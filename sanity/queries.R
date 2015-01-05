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

timebuckets <- function(data) {
    list(points = c(0,1,60,60*60,24*60*60,7*24*60*60,30*24*60*60,365*24*60*60,max(data)),
         names = c("Off","Seconds","Minutes","Hours","Days","Weeks","Months","Years"))
}

allhard <- sparqlfile("all-hard.rq")
fresh <-  allhard$results$fresh
fresh[fresh <= 0] <- 0
hardhist <- hist(fresh, breaks=timebuckets(fresh)$points, plot=F)
bphard <- barplot(hardhist$count, col="white", names.arg=timebuckets(fresh)$name, xlab="Standards-compliant freshness lifetime", ylab="Frequency", main='')
text(bphard, hardhist$counts, labels=hardhist$counts, pos=1)
