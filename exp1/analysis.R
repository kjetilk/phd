coef.sorted <- function(model) {
  sort(abs(coef(model)))
}

implementation.coef <- function(model) {
  coef(model)[grep("Implement", names(coef(model)))]
}

fulllm <- function(results) {
  lm(formula = experiments ~ Implement * TripleC * BGPComp * Lang * Range * Union * Optional * Machine, data = results)
}

robust.single <- function(model, control = "Implement", noise = c("TripleC", "Lang", "Union", "Optional"), ...) {
  fm <- as.formula(paste("experiments ~", control, " * ", paste(noise, collapse=" * ")));
  allmeans <- aggregate(fm, data=model, mean)
  t.test(
         allmeans[allmeans[[control]] == 2,"experiments"],
         allmeans[allmeans[[control]] == 1,"experiments"],
         alternative="less",
         ...)
}
  
