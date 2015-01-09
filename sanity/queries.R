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

lifetimetable <- function(filename) {
    data <- sparqlfile(filename)
    
    mybreaks <- timebuckets(data$results$fresh)$points
    types <- unique(data$results$type)
    
    allhists <- lapply(types, function(type) {
        times <- data$results[which(data$results$type == type),3]
        times[times <= 0] <- 0
        myhist <- hist(times, breaks=mybreaks, plot=F)
        myhist$xname <- type
        myhist
    })
    
    tmp <- NULL # It feels wrong to do this this way...
    tmpm <- sapply(allhists, function(thishist) {
        tmp <- c(tmp, thishist$counts)
    })
    colnames(tmpm) <- types
    rownames(tmpm) <- timebuckets(data$results$fresh)$names
    as.table(tmpm)
}

hardtable <- lifetimetable("other-hard.rq")
hardall <- apply(hardtable, 1, sum)
bphard <- barplot(hardall, col="white", xlab="Standards-compliant freshness lifetime", ylab="Frequency", main='')
text(bphard, hardall, labels=hardall, pos=1)

mosaicplot(hardtable)

heuristictable <- lifetimetable("other-heuristic.rq")
heuristicall <- apply(heuristictable, 1, sum)
bpheuristic <- barplot(heuristicall, col="white", xlab="Simple heuristic freshness lifetime", ylab="Frequency", main='')
text(bpheuristic, heuristicall, labels=heuristicall, pos=1)

mosaicplot(heuristictable)

harderrordata <- sparqlfile("failed-hard.rq")
harderrordata$results$fresh[harderrordata$results$fresh <0] <- 0
errorok <- harderrordata$results$fresh[which(harderrordata$results$status == "OK")]
errorparse <- harderrordata$results$fresh[which(harderrordata$results$status == "parseerror")]
qqplot(errorok,errorparse)
