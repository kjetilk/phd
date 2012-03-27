library(SPARQL)

queries <- read.delim("/home/kjekje/DBPediaBenchmark/data/dbpedia.aksw.org/benchmark.dbpedia.org/Queries.txt", header=FALSE, col.names=c('name', 'query', 'auxquery'), row.names=1, colClasses = "character")

singleQuery <- function(endpoint, queries, runs = 5) {
  auxdata <- SPARQL(url=endpoint, query=queries$auxquery)
#  browser()
  using <- as.matrix(auxdata$results[sample((1:nrow(auxdata$results)), runs),])
  runqueries <- apply(using, 1, runQueries, queries$query, endpoint)
  runqueries
}

runQueries <- function(var, queryWithVar, endpoint) {
#  browser()
  query <- sub("%%var%%", paste("<", var, ">", sep="", collapse=""), queryWithVar, fixed=TRUE)
  timeQuery(endpoint, query)
}

single <- singleQuery("http://kjekje-vm/sparql", queries["union,distinct",])
single <- singleQuery("http://dbpedia.org/sparql", queries["union,distinct",])
