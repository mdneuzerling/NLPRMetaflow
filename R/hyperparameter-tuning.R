#' Select the best hyperparameter set according to a given metric
#'
#' Metaflow saves artefacts as pickle files, which prevents us from using nested
#' tibbles. Unfortunately, `tune` relies on nested tibbles to store its results.
#' We instead use `collect_metrics` to store simple tibbles that are compatible
#' with pickle. Unfortunately, this means we cannot rely on `tune`'s functions
#' for extracting optimal hyperparameter sets and must write our own.
#'
#' @param hyperparameter_results A tibble of hyperparameter results collected
#'   with `tune::collect_metrics`
#' @param metric A metric to minimise. Defaults to "rmse".
#'
#' @return named list
#' @importFrom magrittr %>%
#' @export
select_best_hyperparameters <- function(
  hyperparameter_results,
  metric = "rmse"
) {
  hyperparameter_results <- hyperparameter_results %>%
    dplyr::filter(.metric == metric)
  optimal <- hyperparameter_results[which.min(hyperparameter_results$mean),]
  optimal %>% dplyr::select(1:.metric, -.metric) # similar to tune::select_best
}
