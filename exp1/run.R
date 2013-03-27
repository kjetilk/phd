sparqlEval <- function(design) {
  if (!inherits(design, "design")) {
    stop("Argument 'design' has to be a design object or an object of a subclass")
  }
  apply(design, 1, experiment)

}

experiment <- function(run) {
  name <- names(run)
  print(run)
  stop()
}
