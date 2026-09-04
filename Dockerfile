ARG BIOC_VERSION
FROM bioconductor/bioconductor_docker:${BIOC_VERSION}
COPY . /opt/pkg

## Keep R's user cache and the book's `micromamba` and its conda env
ENV R_USER_CACHE_DIR=/opt/R-cache

## Install book package 
RUN Rscript -e 'install.packages("remotes") ; repos <- BiocManager::repositories() ; remotes::install_local(path = "/opt/pkg/", repos=repos, dependencies=TRUE, build_vignettes=FALSE, upgrade=TRUE) ; sessioninfo::session_info(installed.packages()[,"Package"], include_base = TRUE)'

## Install the python environment
RUN Rscript -e 'BiocBook::setup_python(requirements = "/opt/pkg/inst/requirements.yml"); cat(sprintf("RETICULATE_PYTHON=%s\n", reticulate::py_config()$python), file = file.path(R.home("etc"), "Renviron.site"), append = TRUE)' && \
    chmod -R a+rX "${R_USER_CACHE_DIR}" && \
    Rscript -e 'stopifnot(nzchar(Sys.getenv("RETICULATE_PYTHON"))); cat("book python:", reticulate::py_config()$python, "\n")'

## Build/install using same approach than BBS
RUN R CMD INSTALL /opt/pkg
RUN quarto install --quiet tinytex && R CMD build --keep-empty-dirs --no-resave-data /opt/pkg
