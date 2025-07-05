pacman::p_load(bigrquery, DBI, RPostgres, dplyr, config, glue, logger)
Sys.setenv(R_CONFIG_ACTIVE = "weather")
# read config
cfg <- config::get("/app/secrets/config.yml")

# connect to Postgres
pg <- dbConnect(
  Postgres(),
  host     = cfg$db$host,
  port     = cfg$db$port,
  dbname   = cfg$db$name,
  user     = cfg$db$user,
  password = cfg$db$pass
)


# determine latest timestamp/record in pg
res <- dbGetQuery(pg,
                  glue("SELECT COALESCE(MAX(timestamp),'1970-01-01') AS last_ts
   FROM {cfg$db$schema}.{cfg$db$table};")
)
last_ts <- res$last_ts


# authenticate (via GOOGLE_APPLICATION_CREDENTIALS)
bq_auth(path = "user.json")

bq_con <- dbConnect(
  bigquery(),
  project = cfg$bq$project,
  dataset = cfg$bq$dataset,
  billing = cfg$bq$project,
  table = cfg$bq$table)

bq_sql <- glue(
  "SELECT *\n",
  "  FROM `{cfg$bq$project}.{cfg$bq$dataset}.{cfg$bq$table}`\n",
  " WHERE timestamp > '{last_ts}'\n",
  " ORDER BY timestamp"
)

qry <- bq_project_query(cfg$bq$project, bq_sql)

# download delta between pg and bq
delta <- bq_table_download(qry)

# write to Postgres
if (nrow(delta) > 0) {
  dbWriteTable(
    pg,
    Id(schema = cfg$bg$schema, table = cfg$db$table),
    delta,
    append = TRUE
  )
  log_info("Appended {nrow(delta)} new rows.")
} else {
  log_info("No new rows to append.")
}
