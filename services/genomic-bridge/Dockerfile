FROM rocker/tidyverse:4.2.0

# Install Bioconductor manager
RUN R -e "install.packages('BiocManager')"
RUN R -e "BiocManager::install(c('GenomicRanges', 'VariantAnnotation'))"

# Install other dependencies
RUN R -e "install.packages(c('plumber', 'checkmate', 'data.table'))"

WORKDIR /app
COPY . .

EXPOSE 8000
CMD ["Rscript", "start_linkage_service.R"]
