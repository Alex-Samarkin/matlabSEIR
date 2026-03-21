library(jsonlite)

# Fetch the data
df <- read.csv("https://ourworldindata.org/grapher/daily-covid-cases-deaths-7-day-ra.csv?v=1&csvType=full&useColumnShortNames=true")

# Fetch the metadata
metadata <- fromJSON("https://ourworldindata.org/grapher/daily-covid-cases-deaths-7-day-ra.metadata.json?v=1&csvType=full&useColumnShortNames=true")

# Convert date column to Date type
df$date <- as.Date(df$date)

# print the first few rows of the data
head(df)