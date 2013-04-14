sparqlEval <- function(design, path = "experiment/") {
  if (!inherits(design, "design")) {
    stop("Argument 'design' has to be a design object or an object of a subclass")
  }
  # First get all from files
  facnames <- factor.names(design)
  files <- lapply(seq_along(facnames), function(i, factors, justnames) {
                    sapply(factors[[i]], loadexperiment, name=justnames[i], path=path)
                  },
                  factor=facnames, justnames=names(facnames))
  # Run the experiment by iterating design matrix
  apply(design, 1, experiment, files=files)
}

loadexperiment <-  function(level, name, path) {
  filename <- paste(path, name, "-", level, sep="")
  expfile <- readLines(filename)
  query <- FALSE
  endpoint <- FALSE
  type <- NA
  if(!(is.na(charmatch("# SPARQL", expfile[1])))) {
    query <- TRUE
    type <- substr(expfile[1], 10, 20)
  }
  else if(!(is.na(charmatch("# ENDPOINT URL", expfile[1])))) {
    endpoint <- TRUE
  }
  else {
    stop("No valid file header (SPARQL / ENDPOINT URL) found")
  }
  list(content = expfile, query = query, endpoint = endpoint, type = type, level = level)
  
}

experiment <- function(run, files) {

  name <- names(run)
  browser()
}


