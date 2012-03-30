library(SPARQL)

queries <- read.delim("/home/kjekje/DBPediaBenchmark/data/dbpedia.aksw.org/benchmark.dbpedia.org/Queries.txt", header=FALSE, col.names=c('name', 'query', 'auxquery'), row.names=1, colClasses = "character")

singleQuery <- function(endpoint, queries, runs = 5) {
  auxdata <- SPARQL(url=endpoint, query=queries$auxquery)
  using <- as.matrix(auxdata$results[sample((1:nrow(auxdata$results)), runs),])
  runqueries <- apply(using, 1, runQueries, queries$query, endpoint)
  runqueries
}

runQueries <- function(var, queryWithVar, endpoint) {
  substQuery <- queryWithVar
  for(name in names(var)) {
    substQuery <- gsub(paste("%%", name, "%%", sep="", collapse=""),
                       paste("<", var[[name]], ">", sep="", collapse=""),
                       substQuery, fixed=TRUE)
  }
  timeQuery(endpoint, substQuery)
}

single <- singleQuery("http://kjekje-vm/sparql", queries["union,distinct",])
single1 <- singleQuery("http://kjekje-vm/sparql", queries[1,])
single <- singleQuery("http://dbpedia.org/sparql", queries["union,distinct",])
