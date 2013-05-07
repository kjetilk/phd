coef.sorted <- function(model) {
  sort(abs(coef(model)))
}

implementation.coef <- function(model) {
  coef(model)[grep("Implement", names(coef(model)))]
}

fulllm <- function(results) {
  lm(formula = experiments ~ Implement * TripleC * BGPComp * Lang * Range * Union * Optional * Machine, data = results)
}

robust.simple <- function(model, control = "Implement",
                   noise = c("TripleC", "Lang", "Union", "Optional"), 
                   inactive = c("Machine", "BGPComp", "Range"),
                   pairwise=FALSE, ...) {
  fm <- as.formula(paste("experiments ~", control, " * ", paste(inactive, collapse=" * ")))
  allmeans <- aggregate(fm, data=model, mean)
  t.test(allmeans[allmeans["Implement"] == 1,]$experiments, allmeans[allmeans["Implement"] == 2,]$experiments)
}

robust.pairwise <- function(model, control = "Implement", 
                            noise = c("TripleC", "Lang", "Union", "Optional")) {
  fm <- as.formula(paste("~", paste(noise, collapse=" * ")))
  dlply(model, fm, function(tmp) {
    t.test(tmp[tmp["Implement"] == 1,]$experiments, tmp[tmp["Implement"] == 2,]$experiments)
  })
}
 
