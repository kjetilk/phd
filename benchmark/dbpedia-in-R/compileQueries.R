library(SPARQL)

queries <- read.delim("/home/kjekje/DBPediaBenchmark/data/dbpedia.aksw.org/benchmark.dbpedia.org/Queries.txt", header=FALSE, col.names=c('name', 'query', 'auxquery'), row.names=1, colClasses = "character")

singleQuery <- function(endpoint, queries, runs = 5) {
  auxdata <- SPARQL(url=endpoint, query=queries$auxquery)
  using <- as.vector(auxdata$results[sample((1:nrow(auxdata$results)), runs),]) # TODO: Support multivars
  sapply(using, insertAuxillaries, queries$query)
}

insertAuxillaries <- function(var, query) {
  sub("%%var%%", paste("<", var, ">", sep="", collapse=""), query, fixed=TRUE)
}

singleQuery("http://dbpedia.org/sparql", queries[1,])
