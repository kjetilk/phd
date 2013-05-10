library(FrF2)
library(plyr)

load("RelevantExperiments.RData")

source("FrF2-mod/remodel.R")
source("FrF2-mod/check.R")
source("FrF2-mod/DanielPlot.R")

pdf(file="fullnormal.pdf")
par(mai=c(0.6,0.6,0.05,0.05))
DanielPlot(runbgplangf1.lm, main="", cex.fac=0.8)
dev.off()

pdf(file="frac32normal.pdf", height=3)
par(mai=c(0.6,0.6,0.05,0.05))
DanielPlot(frac32r1.lm, main="", cex.fac=0.8)
dev.off()

pdf(file="frac64normal.pdf", height=6)
par(mai=c(0.6,0.6,0.05,0.05))
DanielPlot(frac64r3.lm, alpha=c(0.05, 0.15), main="", cex.fac=0.8)
dev.off()


pdf(file="frac64hugenormal.pdf", height=6)
par(mai=c(0.6,0.6,0.05,0.05))
DanielPlot(frac64huger1.lm, main="", cex.fac=0.8)
dev.off()

#sign <- LenthPlot(runbgplangf1.lm, alpha=0.05, plt=F)["ME"]
sign <- 2 # We haven't got space for more
coefs <- coef(runbgplangf1.lm)
sigcoefs <- sort(coefs[abs(coefs) > sign])*2
sigcoefs2 <- sigcoefs[names(sigcoefs) != "(Intercept)"]

lapply(robust.pairwise(runbgplangf1), function(x) x$p.value) # Lots of manual work after this
