library(RCurl)

#h = getCurlHandle()

timeQuery <- function(endpoint, query, ..., curlh = getCurlHandle())
  {
    getForm(c(endpoint), query=query, ..., curl = curlh)
    getCurlInfo(curlh)$starttransfer.time
  }

timeQuery("http://dbpedia.org/sparql", "SELECT * WHERE { ?concept a skos:Concept } LIMIT 10");

    
