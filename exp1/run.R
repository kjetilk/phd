sparqlEval <- function(design, dir = "experiment/") {
  if (!inherits(design, "design")) {
    stop("Argument 'design' has to be a design object or an object of a subclass")
  }
  # First get all from files
  lapply(factor.names(design), function(factorname) {
    name <- names(factorname)
    names <- sapply(factorname, function(level) {
      print name
      cat(name, "-", level, sep='')
    }
    , name )
#    content <- readLines(cat(dir, 
    stop(names)
  } )
  # Run the experiment by iterating design matrix
  apply(design, 1, experiment)

}

experiment <- function(run) {
  name <- names(run)
  print(run)
  stop()
}
