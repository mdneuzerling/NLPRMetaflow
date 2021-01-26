#' Evaluate a Yelp review model
#'
#' @param model Fitted `parsnip` or `workflows` model
#' @param test Test data containing "text" and "stars" columns
#'
#' @return tibble
#' @import yardstick
#' @importFrom magrittr %>%
#' @export
evaluate_model <- function(model, test) {
  model %>%
    predict(test) %>%
    metric_set(rmse, mae, rsq)(test$interactions, .pred)
}
