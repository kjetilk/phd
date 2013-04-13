sparqlEval <- function(design, path = "experiment/") {
  if (!inherits(design, "design")) {
    stop("Argument 'design' has to be a design object or an object of a subclass")
  }
  # First get all from files
  facnames <- factor.names(design)
  lapply(seq_along(facnames), function(i, factors, justnames) {
           sapply(factors[[i]], loadexperiment, name=justnames[i], path=path)
         },
         factor=facnames, justnames=names(facnames))
    
  # Run the experiment by iterating design matrix
  #  apply(design, 1, experiment)

}

loadexperiment <-  function(level, name, path) {
  paste(path, name, level, sep="-")
}

experiment <- function(run) {
  name <- names(run)
  print(run)
  stop()
}
