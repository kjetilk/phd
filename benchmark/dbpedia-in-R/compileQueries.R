library(SPARQL)

allqueries <- read.delim("/home/kjekje/DBPediaBenchmark/data/dbpedia.aksw.org/benchmark.dbpedia.org/Queries.txt", header=FALSE, col.names=c('name', 'query', 'auxquery'), row.names=1, colClasses = "character")

singleQuery <- function(queries, endpoint, runs = 5) {
  auxdata <- SPARQL(url=endpoint, query=queries$auxquery)
  using <- as.matrix(auxdata$results[sample((1:nrow(auxdata$results)), runs),])
  runqueries <- t(apply(using, 1, runQueries, queries$query, endpoint))
  as.data.frame(runqueries)
}

runQueries <- function(var, queryWithVar, endpoint) {
  if (length(var) < 1) stop("Auxillary query had no results")
  if (length(var) == 1) {
    substQuery <- sub("%%var%%", paste("<", var, ">", sep="", collapse=""), queryWithVar, fixed=TRUE)
  } else {
    substQuery <- queryWithVar
    for(name in names(var)) {
      substQuery <- gsub(paste("%%", name, "%%", sep="", collapse=""),
                         paste("<", var[[name]], ">", sep="", collapse=""),
                         substQuery, fixed=TRUE)
    }
  }
  unlist(timeQuery(endpoint, substQuery))
}

allQueries <- function(allqueries, endpoint, runs = 5) {
  for(queryname in row.names(allqueries)) {
   singleq <- singleQuery(allqueries[queryname,], endpoint, runs)
   browser()
   singleq
 }
}


single <- singleQuery(queries["union,distinct",], "http://kjekje-vm/sparql")
single1 <- singleQuery(queries[1,], "http://kjekje-vm/sparql")
single <- singleQuery(queries["union,distinct",], "http://dbpedia.org/sparql")
