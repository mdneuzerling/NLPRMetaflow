#' Compare hyperparameter performance and train a final model
#'
#' @details
#' This step is join in the flow, and so must first reduce the various
#' hyperparameter evaluations produced in the previous steps and merge the
#' other variables.
#'
#' It appears as though Metaflow struggles with nested tibbles, likely due to
#' a restriction with reticulate/Python. This prevents us from using the
#' tuning results from `tune` directly, so we have to use a custom
#' `select_best_hyperparameters` function.
#'
#' @param self Metaflow state variable
#' @param inputs Inputs from the previous split Metaflow steps
#'
#' @export
train_final_model <- function(self, inputs) {
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
}
