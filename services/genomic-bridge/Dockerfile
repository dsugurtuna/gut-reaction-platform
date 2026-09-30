FROM rocker/tidyverse:4.2.0

# Install Bioconductor manager
RUN R -e "install.packages('BiocManager')"
RUN R -e "BiocManager::install(c('GenomicRanges', 'VariantAnnotation'))"

# Install other dependencies
RUN R -e "install.packages(c('plumber', 'checkmate', 'data.table'))"

WORKDIR /app
COPY . .

EXPOSE 8000
# Sourcing the file only defines the routes; pr_run() starts the HTTP server.
CMD ["Rscript", "-e", "plumber::pr_run(plumber::pr('start_linkage_service.R'), host = '0.0.0.0', port = 8000)"]
