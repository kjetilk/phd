sparqlEval <- function(design, path = "experiment/") {
  if (!inherits(design, "design")) {
    stop("Argument 'design' has to be a design object or an object of a subclass")
  }
  allnames <- factor.names(design)
  files <- allnames 
  # Use a for loop to read the files, though rapply is probably the R way
  for(name in names(allnames)) {
    for(j in 1:length(allnames[[name]])) {
      files[[name]][j] <- cat(path,names(allnames)[name], "-", allnames[[name]][j], sep="")
    }
  }

  files


  # Run the experiment by iterating design matrix
  #apply(design, 1, experiment)

}

experiment <- function(run) {
  name <- names(run)
  print(run)
  stop()
}
