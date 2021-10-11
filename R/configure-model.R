#' Configure (but do not fit) a model and associated variables
#'
#' @param self Metaflow state variable
#'
#' @export
configure_model <- function(self) {
  message("Preparing model object for fitting")
  model <- parsnip::boost_tree(
    learn_rate = tune::tune(),
    trees = tune::tune(),
    tree_depth = tune::tune(),
    sample_size = tune::tune()
  ) %>%
    parsnip::set_engine("xgboost", nthread = 4) %>%
    parsnip::set_mode("regression")
  # We only need a 0-row tibble to initialise the recipe, and I'm
  # memory constrained in this step.
  message("Defining recipe")
  recipe <- generate_text_processing_recipe(
    interactions ~ definition,
    self$train[0,],
    text_column = definition,
    min_times = 0.001
  )
  message("Combining model and recipe into workflow")
  self$workflow <- workflows::workflow() %>%
    workflows::add_recipe(recipe) %>%
    workflows::add_model(model)

  message("Preparing hyperparameter grid for tuning")
  self$hyperparameters <- tidyr::expand_grid(
    learn_rate = c(0.1, 0.3),
    trees = c(300, 500),
    tree_depth = c(6, 12),
    sample_size = c(0.8, 1.0)
  )
  self$hyperparameter_indices <- 1:nrow(self$hyperparameters)
  message(glue::glue("Prepared hyperparameter grid with ",
                     "{length(self$hyperparameter_indices)} combinations"))
}
