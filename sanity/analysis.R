
library(SPARQL)

sparqlfile <- function(filename, dir = "/home/kjetil/sanity/queries/", url = "http://robin:8890/sparql" , ...) {
    query <- paste(readLines(paste0(dir, filename)), collapse="\n")
    SPARQL(url = url, query = query, ...)
}
