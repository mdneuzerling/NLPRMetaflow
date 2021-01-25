#' Generate a recipe for processing text data into a document-term matrix
#'
#' Adapted from work by Emil Hvitfeldt
#' https://www.hvitfeldt.me/blog/text-classification-with-tidymodels/
#'
#' @param formula A model formula.
#' @param train_data A data frame or tibble of the _template_ data set.
#' @param text_column Column containing the documents.
#' @param min_times Numeric between 0 and 1. Minimum frequency at which a word
#'   can appear before getting removed. Defaults to 0.01.
#' @param max_times Numeric between 0 and 1. Maximum frequency at which a word
#'   can appear before getting removed. Defaults to 1.
#'
#' @return `recipes::recipe` object
#'
#' @importFrom recipes step_filter
#' @import textrecipes
#' @export
#'
generate_text_processing_recipe <- function(
  formula,
  train_data,
  text_column,
  min_times = 0.01,
  max_times = 1.00
  ) {
  recipes::recipe(formula, data = train_data) %>%
    step_filter({{text_column}} != "") %>%
    step_tokenize({{text_column}}) %>%
    step_stopwords({{text_column}}) %>%
    step_tokenfilter(
      {{text_column}},
      min_times = min_times,
      max_times = max_times,
      percentage = TRUE
    ) %>%
    step_tfidf({{text_column}})
}
