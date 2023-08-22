ARG BIOC_VERSION
FROM bioconductor/bioconductor_docker:${BIOC_VERSION}
SHELL ["/bin/bash", "-c"]
COPY . /opt/BiocBook

## Install micromamba and required softwares
RUN curl -L micro.mamba.pm/install.sh | bash
RUN /root/.local/bin/micromamba create --file /opt/BiocBook/inst/requirements.yml --yes
RUN /root/.local/bin/micromamba clean --yes --quiet
RUN /root/.local/bin/micromamba shell init --shell bash --root-prefix=~/micromamba

## Install Quarto
RUN apt-get update && apt-get install rsync gdebi-core -y
RUN curl -LO https://quarto.org/download/latest/quarto-linux-amd64.deb 
RUN gdebi --non-interactive quarto-linux-amd64.deb
RUN rm quarto-linux-amd64.deb

## Install pak
RUN Rscript -e 'install.packages("pak", repos = "https://r-lib.github.io/p/pak/devel/")'

## Set repositories 
RUN Rscript -e 'write(paste0("R_BIOC_VERSION=", gsub(".[0-9]*$$", "", as.character(packageVersion("BiocVersion")))), paste0(Sys.getenv("R_HOME"), "/etc/Renviron.site"), append = TRUE)'
RUN Rscript -e 'write(paste0("BIOCBOOK_PACKAGE=", gsub(".*: ", "", grep("Package: ", readLines("/opt/BiocBook/DESCRIPTION"), value = TRUE))), paste0(Sys.getenv("R_HOME"), "/etc/Renviron.site"), append = TRUE)'
RUN Rscript -e 'write(paste0("BIOCBOOK_IMAGE=", tolower(Sys.getenv("BIOCBOOK_PACKAGE"))), paste0(Sys.getenv("R_HOME"), "/etc/Renviron.site"), append = TRUE)'

## Install BiocBook repo
RUN Rscript -e 'pak::pkg_install("/opt/BiocBook/", ask = FALSE, dependencies = c("Depends", "Imports", "Suggests"))'

## Check installed BiocBook with rcmdcheck and BiocCheck following BioC recommendations
RUN Rscript -e 'rcmdcheck::rcmdcheck("/opt/BiocBook/", args = c("--no-manual", "--no-vignettes", "--timings"), build_args = c("--no-manual", "--keep-empty-dirs", "--no-resave-data"), error_on = "warning", check_dir = "check")'
RUN Rscript -e 'BiocCheck::BiocCheck(dir("check", "tar.gz$$", full.names = TRUE), `quit-with-status` = TRUE, `no-check-R-ver` = TRUE, `no-check-bioc-help` = TRUE)'
