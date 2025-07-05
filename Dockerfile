# Use the official r-base image
FROM r-base:4.5.1

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libssl-dev libcurl4-openssl-dev libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Install R packages
RUN R -e "install.packages(c('bigrquery', 'DBI', 'RPostgres', 'dplyr', 'dbplyr', 'config', 'glue', 'logger'), repos='https://cran.rstudio.com/')"

# Set working directory
WORKDIR /app

# Copy the script
COPY data_transfer.R /app/

# THIS IS THE FIX: Use CMD to set the default, overridable command
CMD ["Rscript", "/app/data_transfer.R"]