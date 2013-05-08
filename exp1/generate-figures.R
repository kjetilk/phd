library(FrF2)
library(plyr)

load("RelevantExperiments.RData")

source("analysis.R")

postscript(file="fullnormal.eps")
DanielPlot(runbgplangf1.lm)
dev.off()

postscript(file="fulllenth.eps")
LenthPlot(runbgplangf1.lm)
dev.off()

postscript(file="frac32normal.eps")
DanielPlot(frac32r1.lm)
dev.off()

postscript(file="frac64normalalpha005.eps")
DanielPlot(frac64r3.lm)
dev.off()

postscript(file="frac64normalalpha015l.eps")
DanielPlot(frac64r3.lm, alpha=0.15)
dev.off()

postscript(file="frac64hugenormal.eps")
DanielPlot(frac64huger1.lm)
dev.off()
