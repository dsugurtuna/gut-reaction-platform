FROM rocker/r-ver:4.2.0

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

# Install R packages
RUN R -e "install.packages(c('plumber', 'tidyverse', 'data.table', 'checkmate', 'jsonlite'))"

WORKDIR /app
COPY . .

EXPOSE 8000
# Sourcing the file only defines the routes; pr_run() starts the HTTP server.
CMD ["Rscript", "-e", "plumber::pr_run(plumber::pr('start_api.R'), host = '0.0.0.0', port = 8000)"]
