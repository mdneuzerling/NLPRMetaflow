#' Generate a recipe for processing text data into a document-term matrix
#'
#' Adapted from work by Emil Hvitfeldt
#' https://www.hvitfeldt.me/blog/text-classification-with-tidymodels/
#'
#' @param formula A model formula.
#' @param train_data A data frame or tibble of the _template_ data set.
#' @param min_times An integer. Minimum number of times a word can appear before
#'   getting removed. Defaults to 10.
#'
#' @return `recipes::recipe` object
#'
#' @importFrom recipes step_filter
#' @import textrecipes
#' @export
#'
generate_text_processing_recipe <- function(formula, train_data, min_times = 10) {
  recipes::recipe(formula, data = train_data) %>%
    step_filter(text != "") %>%
    step_tokenize(text) %>%
    step_stopwords(text, keep = TRUE) %>%
    step_tokenfilter(text, min_times = min_times) %>%
    step_tfidf(text)
}
