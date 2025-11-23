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
CMD ["Rscript", "start_api.R"]
