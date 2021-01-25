#' Tune a subset of hyperparameters
#'
#' @details
#' This step is split in the flow so that separate instances can evaluate
#' different combinations of hyperparameters indepentently of one another.
#'
#' It appears as though Metaflow struggles with nested tibbles, likely due to
#' a restriction with reticulate/Python. This prevents us from using the
#' tuning results from `tune` directly, so we have to `collect_metrics`.
#'
#' @param self Metaflow state variable
#'
#' @export
tune_hyperparameters = function(self) {
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
}
