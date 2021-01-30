# NLPRMetaflow

This repository accompanies my blog post [Using Metaflow to Make Model Tuning Less Painful](https://mdneuzerling.com/post/using-metaflow-to-make-model-tuning-less-painful/).

I have a machine learning model that takes some time to train. Data pre-processing and model fitting can take 15–20 minutes. That’s not so bad, but I also want to tune my model to make sure I’m using the best hyper-parameters. With 16 different combinations of hyperparameters and 5-fold cross-validation, my 20 minutes can become a day or more.

Metaflow is an open-source tool from the folks at Netflix that can be used to make this process less painful. It lets me choose which parts of my model training flow I want to execute on the cloud. To speed things up I’m going to ask Metaflow to spin up enough compute resources so that every hyperparameter combination can be evaluated in parallel in separate environments.

The best part is that my flow is pure R code.

## Requirements

This repository uses [Urban Dictionary data available on Kaggle](https://www.kaggle.com/therohk/urban-dictionary-words-dataset). The CSV should be copied into a `data/` directory.

To run the flow on AWS Batch, [the appropriate resources must exist and be configured with Metaflow](https://docs.metaflow.org/metaflow-on-aws/metaflow-on-aws). The `ecr_repository` value should point to an image built by the Dockerfile in this repository. Alternatively, the flow can be run locally by removing the "batch" decorators from all steps.
