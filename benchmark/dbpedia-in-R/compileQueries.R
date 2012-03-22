library(SPARQL)

queries <- read.delim("/home/kjekje/DBPediaBenchmark/data/dbpedia.aksw.org/benchmark.dbpedia.org/Queries.txt", header=FALSE, col.names=c('name', 'query', 'auxquery'), row.names=1, colClasses = "character")

singleQuery <- function(endpoint, queries, runs = 5) {
  auxdata <- SPARQL(url=endpoint, query=queries$auxquery)
  using <- as.vector(auxdata$results[sample((1:nrow(auxdata$results)), runs),]) # TODO: Support multivars
  runqueries <- sapply(using, runQueries, queries$query)
  runqueries
}

runQueries <- function(var, queryWithVar) {
  query <- sub("%%var%%", paste("<", var, ">", sep="", collapse=""), queryWithVar, fixed=TRUE)
  timeQuery("http://dbpedia.org/sparql", query)
}

singleQuery("http://dbpedia.org/sparql", queries[1,])
