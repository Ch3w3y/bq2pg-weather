# 1. start from a minimal R image
FROM r-base:4.5.1

# 2. install OS libs for SSL, curl, Postgres client
RUN apt-get update && apt-get install -y --no-install-recommends \
    libssl-dev \
    libcurl4-openssl-dev \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# 3. install CRAN packages needed by the script
RUN R -e "install.packages(c('pacman','bigrquery', 'DBI', 'RPostgres', 'dplyr', 'dbplyr', 'config', 'glue', 'logger'), repos='https://cran.rstudio.com/')"

# 4. copy only code (not config.yml)
WORKDIR /app
COPY data_transfer.R /app/

# 5. tell the R session where to look for the GCP key
ENV GOOGLE_APPLICATION_CREDENTIALS=/app/user.json

# 6. default command: run your ETL script
ENTRYPOINT ["Rscript","/app/data_transfer.R"]