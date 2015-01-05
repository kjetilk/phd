checkserver <- sparqlfile("check-server.rq")
reshardbin <- as.integer(checkserver$results$hard)
reshardbin[! is.na(reshardbin)] <- 1
reshardbin[is.na(reshardbin)] <- 0
chisq.test(checkserver$results$server, reshardbin, simulate.p.value=T, B = 10000)

respromisebin <- checkserver$results$promise
respromisebin[! is.na(respromisebin)] <- 1
respromisebin[is.na(respromisebin)] <- 0
chisq.test(checkserver$results$server, respromisebin, simulate.p.value=T, B = 10000)

checkservercount <- sparqlfile("check-server-count.rq")
serverratio <- data.frame(name=checkservercount$results$server, promise=checkservercount$results$pc/checkservercount$results$sc, hard=checkservercount$results$hc/checkservercount$results$sc, pc=checkservercount$results$pc, hc=checkservercount$results$hc)
xtable(as.matrix(serverratio[which(serverratio$hard == 1), ]$name))

