coef.sorted <- function(model) {
  sort(abs(coef(model)))
}

implementation.coef <- function(model) {
  coef(model)[grep("Implement", names(coef(model)))]
}

fulllm <- function(results) {
  lm(formula = experiments ~ Implement * TripleC * BGPComp * Lang * Range * Union * Optional * Machine, data = results)
}

robust <- function(model, control = "Implement", noise = c("TripleC", "Lang", "Union", "Optional"), pairwise=FALSE, ...) {
  fm <- as.formula(paste("experiments ~", control, " * ", paste(noise, collapse=" * ")));
  allmeans <- aggregate(fm, data=model, mean)
  oldimplement <- allmeans[allmeans[[control]] == 1,"experiments"]
  newimplement <- allmeans[allmeans[[control]] == 2,"experiments"]
  if(pairwise) {
    browser()
  } else {
    t.test(newimplement, oldimplement, alternative="less", ...)
  }
}
  
