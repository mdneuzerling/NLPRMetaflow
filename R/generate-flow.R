#' Generate model training flow
#'
#' This function requires that an AWS account ID is configured as an
#' environment variable "AWS_ACCOUNT_ID". This is used to construct the
#' location of the image used to run the flow on AWS Batch.
#'
#' @return Metaflow flow object
#'
#' @import metaflow
#' @importFrom glue glue
#' @importFrom magrittr %>%
#' @export
generate_flow <- function() {

  # AWS configuration
  aws_region <- "ap-southeast-2"
  ecr_repository_name <- "nlprmetaflow"
  git_hash <- system("git rev-parse HEAD", intern = TRUE)
  ecr_repository <- glue(
    "{Sys.getenv('AWS_ACCOUNT_ID')}.dkr.ecr.{aws_region}.amazonaws.com/",
    "{ecr_repository_name}:{git_hash}"
  )

  metaflow("NLPRMetaflow") %>%
    step(
      step = "start",
      r_function = prepare_data,
      next_step = "configure_model"
    ) %>%
    step(
      step = "configure_model",
      r_function = configure_model,
      next_step = "tune_hyperparameters",
      foreach = "hyperparameter_indices"
    ) %>%
    step(
      step = "tune_hyperparameters",
      batch(memory = 16384, cpu = 4, image = ecr_repository),
      r_function = tune_hyperparameters,
      next_step = "train_final_model"
    ) %>%
    step(
      step = "train_final_model",
      join = TRUE,
      batch(memory = 30720, cpu = 4, image = ecr_repository),
      r_function = train_final_model,
      next_step="end") %>%
    step(step = "end")
}
