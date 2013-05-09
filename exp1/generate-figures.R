library(FrF2)
library(plyr)

load("RelevantExperiments.RData")

source("analysis.R")


pdf(file="fullnormal.pdf")
par(mai=c(0.6,0.6,0.05,0.05))
DanielPlot(runbgplangf1.lm, main="", cex.fac=0.8)
dev.off()

pdf(file="frac32normal.pdf", height=3)
par(mai=c(0.6,0.6,0.05,0.05))
DanielPlot(frac32r1.lm, main="", cex.fac=0.8)
dev.off()

pdf(file="frac64normal.pdf", height=5)
par(mai=c(0.6,0.6,0.05,0.05))
DanielPlot(frac64r3.lm, alpha=c(0.05, 0.15), main="", cex.fac=0.8)
dev.off()


pdf(file="frac64hugenormal.pdf")
par(mai=c(0.6,0.6,0.05,0.05))
DanielPlot(frac64huger1.lm, main="", cex.fac=0.8)
dev.off()

