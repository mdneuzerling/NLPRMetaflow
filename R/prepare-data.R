#' Step function for preparing and splitting data
#'
#' @param self Metaflow state variable
#'
#' @export
prepare_data <- function(self) {
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
}
