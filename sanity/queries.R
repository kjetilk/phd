checkserver <- sparqlfile("check-server.rq")
reshardbin <- as.integer(checkserver$results$hard)
reshardbin[! is.na(reshardbin)] <- 1
reshardbin[is.na(reshardbin)] <- 0
chisq.test(checkserver$results$server, reshardbin, simulate.p.value=T, B = 10000)
