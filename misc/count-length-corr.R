literals <- read.csv('/ifi/bifrost/a03/kjekje/Desktop/sparql')
framelit <- as.data.frame(table(literals))
framelit$length <- sapply(levels(framelit$literals), nchar)
plot(framelit$Freq, framelit$length, log="xy")
