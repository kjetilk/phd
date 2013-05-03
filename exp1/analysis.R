coef.sorted <- function(model) {
  sort(abs(coef(model)))
}

implementation.coef <- function(model) {
  coef(model)[grep("Implement", names(coef(model)))]
}

fulllm <- function(results) {
  lm(formula = experiments ~ Implement * TripleC * BGPComp * Lang * Range * Union * Optional * Machine, data = results)
}

robust <- function(model, control = "Implement", inactive = c("Machine", "BGPComp", "Range"), pairwise=FALSE, ...) {
  fm <- as.formula(paste("experiments ~", control, " * ", paste(inactive, collapse=" * ")));
  allmeans <- aggregate(fm, data=model, mean)
  allmeans

}
  
