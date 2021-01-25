#' Generate model training flow
#'
#' @return Metaflow flow object
#'
#' @import metaflow
#' @importFrom glue glue
#' @importFrom magrittr %>%
#' @export
generate_flow <- function() {
  aws_region <- "ap-southeast-2"
  ecr_repository_name <- "nlprmetaflow"
  ecr_repository <- glue(
    "{Sys.getenv('AWS_ACCOUNT_ID')}.dkr.ecr.{aws_region}.amazonaws.com/",
    "{ecr_repository_name}:latest"
  )

  metaflow("yelp_reviews") %>%
    step(step = "start",
         r_function = function(self) {
           message("Loading review data")
           # This will skip approximately 650 bad rows in the CSV, which would
           # generate warnings if not suppressed
           ud_data <- suppressWarnings(
             readr::read_csv("data/urbandict-word-defs.csv") %>%
               dplyr::mutate(interactions = up_votes + down_votes)
           )

           message(glue::glue("Splitting {nrow(ud_data)} rows into train/test"))
           n_train_rows <- floor(0.8 * nrow(ud_data))
           train_indices <- sample(seq_len(nrow(ud_data)), size = n_train_rows)
           self$train <- ud_data[train_indices, ]
           self$test <- ud_data[-train_indices, ]
           message(glue::glue("train has {nrow(self$train)} rows"))
           message(glue::glue("test has {nrow(self$test)} rows"))
         },
         next_step = "configure_model"
    ) %>%
    step(step = "configure_model",
         r_function = function(self) {
           message("Preparing model object for fitting")
           model <- parsnip::boost_tree(
             mtry = tune::tune(),
             trees = tune::tune(),
             tree_depth = tune::tune(),
             sample_size = tune::tune()
           ) %>%
             parsnip::set_engine("xgboost", nthread = 1) %>%
             parsnip::set_mode("regression")
           # We only need a 0-row tibble to initialise the recipe, and I'm
           # memory constrained in this step.
           message("Defining recipe")
           recipe <- generate_text_processing_recipe(
             stars ~ definition,
             self$train[0,],
             min_times = floor(0.01 * nrow(self$train))
           )
           message("Combining model and recipe into workflow")
           self$workflow <- workflows::workflow() %>%
             workflows::add_recipe(recipe) %>%
             workflows::add_model(model)

           message("Preparing hyperparameter grid for tuning")
           self$hyperparameters <- tidyr::expand_grid(
             mtry = c(0.5, 1),
             trees = c(300, 500),
             tree_depth = c(6, 12),
             sample_size = c(0.8, 1.0)
           )
           self$hyperparameter_indices <- 1:nrow(self$hyperparameters)
           message(glue::glue("Prepared hyperparameter grid with ",
                        "{length(self$hyperparameter_indices)} combinations"))
         },
         next_step = "tune_hyperparameters", foreach = "hyperparameter_indices"
    ) %>%
    step(step = "tune_hyperparameters",
         decorator(
           "batch",
           memory = 30000,
           cpu = 4,
           image = ecr_repository
         ),
         r_function = function(self) {
           hyperparameters_to_use <- self$hyperparameters[self$input,]

           # metaflow uses pickles to save objects, which struggle with nested
           # tibbles. Instead, we recreate the folds with a specific seed
           message("Creating folds")
           folds <- withr::with_seed(
             20201225,
             rsample::vfold_cv(self$train, v = 5)
           )

           message("Evaluating hyperparameters")
           self$hyperparameter_results <- self$workflow %>%
             tune::tune_grid(
               resamples = folds,
               grid = hyperparameters_to_use
             ) %>% tune::collect_metrics()
           message("Hyperparameters evaluated and metrics collected")
         },
         next_step = "train_final_model"
    ) %>%
    step(step = "train_final_model", join = TRUE,
         decorator(
           "batch",
           memory = 30000,
           cpu = 4,
           image = ecr_repository
         ),
         r_function = function(self, inputs) {
           message("Collecting hyperparameter results")
           self$collected_hyperparameter_results <- gather_inputs(
             inputs,
             "hyperparameter_results"
           ) %>% dplyr::bind_rows()

           message("Merging artefacts from the join")
           merge_artifacts(
             self,
             inputs,
             exclude = list("hyperparameter_results")
           )

           message("Selecting optimal hyperparameters")
           self$optimal_hyperparameters <- select_best_hyperparameters(
             self$collected_hyperparameter_results,
             metric = "rmse"
           )

           message("Training final model")
           self$final_model <- self$workflow %>%
             tune::finalize_workflow(self$optimal_hyperparameters) %>%
             parsnip::fit(self$train)

           message("Evaluating final model")
           self$metrics <- self$final_model %>% evaluate_model(self$test)
           message("Final model evaluated")
         },
         next_step="end") %>%
    step(step = "end")
}
