checkserver <- sparqlfile("check-server.rq")
reshardbin <- as.integer(checkserver$results$hard)
reshardbin[! is.na(reshardbin)] <- 1
reshardbin[is.na(reshardbin)] <- 0
chisq.test(checkserver$results$server, reshardbin, simulate.p.value=T, B = 10000)

respromisebin <- checkserver$results$promise
respromisebin[! is.na(respromisebin)] <- 1
respromisebin[is.na(respromisebin)] <- 0
chisq.test(checkserver$results$server, respromisebin, simulate.p.value=T, B = 10000)
