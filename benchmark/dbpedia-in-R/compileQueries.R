library(SPARQL)

queries <- read.csv("/home/kjekje/DBPediaBenchmark/data/dbpedia.aksw.org/benchmark.dbpedia.org/Queries.txt", header=FALSE, col.names=c('name', 'query', 'auxquery'), row.names=1, sep="\t")

singleQuery <- function(endpoint, queries, runs = 5) {
  auxdata <- SPARQL(url=endpoint, query=queries$auxquery)
  using <- auxdata$results[sample((1:nrow(auxdata$results)), runs),]
  using
}

singleQuery("http://dbpedia.org/sparql", queries[1,])
