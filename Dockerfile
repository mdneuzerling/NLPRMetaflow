FROM rocker/r-ver:4.0.3
ENV RENV_VERSION 0.12.3
ENV MINICONDA_VERSION py38_4.9.2
ENV PANDAS_VERSION 1.2.1
ENV NUMPY_VERSION 1.19.2
ENV METAFLOW_PYTHON_VERSION 2.2.5

RUN apt-get update && apt-get install -y curl \
  && curl -LO https://repo.anaconda.com/miniconda/Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh \
  && bash Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh -p /miniconda -b \
  && rm Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh

ENV PATH=/miniconda/bin:${PATH}
ENV METAFLOW_PYTHON /miniconda/bin/python3

RUN  conda install numpy=$NUMPY_VERSION pandas=$PANDAS_VERSION \
  && conda install -c conda-forge metaflow=$METAFLOW_PYTHON_VERSION

# Use the precompiled binaries kindly provided by RStudio
ENV CRAN_REPO https://packagemanager.rstudio.com/all/__linux__/focal/latest
RUN Rscript -e 'install.packages(c("remotes", "devtools"), repos = c("CRAN" = Sys.getenv("CRAN_REPO")))'

ADD . / /package/
WORKDIR /package

RUN eval $(Rscript -e 'writeLines(paste(c("apt-get update", remotes::system_requirements("ubuntu", "20.04")), collapse = " && "))')

# renv::restore can be a bit buggy if .Rprofile and the renv directory exist
RUN rm -f .Rprofile \
  && rm -rf renv \
  && Rscript -e "install.packages('remotes', repos = c(CRAN = Sys.getenv('CRAN_REPO')))" \
  && Rscript -e "remotes::install_github('rstudio/renv', ref = Sys.getenv('RENV_VERSION'))" \
  && Rscript -e "renv::restore(repos = c(CRAN = Sys.getenv('CRAN_REPO')))" \
  && Rscript -e "devtools::install(dependencies = FALSE)"
