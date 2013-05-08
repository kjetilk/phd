library(FrF2)
library(plyr)

load("RelevantExperiments.RData")

source("analysis.R")

pdf(file="fullnormal.pdf")
DanielPlot(runbgplangf1.lm)
dev.off()

pdf(file="frac32normal.pdf")
DanielPlot(frac32r1.lm)
dev.off()

pdf(file="frac64normalalpha005.pdf")
DanielPlot(frac64r3.lm)
dev.off()

pdf(file="frac64normalalpha015.pdf")
DanielPlot(frac64r3.lm, alpha=0.15)
dev.off()

pdf(file="frac64hugenormal.pdf")
DanielPlot(frac64huger1.lm)
dev.off()
