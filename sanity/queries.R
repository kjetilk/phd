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
pdf(file="hardall.pdf", height=5.2,width=8)
par(mai=c(1,1,0.2,0.05))
bphard <- barplot(hardall, col="white", xlab="Standards-compliant freshness lifetime", ylab="Number of occurences", main='')
text(bphard, hardall, labels=paste0(signif(hardall*100/sum(hardall),2),'%'), pos=1)
dev.off()

heuristictable <- lifetimetable("other-heuristic.rq")
hardtable2 <- cbind(hardtable[,3], hardtable[,1], hardtable[,4], hardtable[,2])
colnames(hardtable2) <- colnames(heuristictable)

pdf(file="hardtable.pdf", height=5.2,width=8)
par(mai=c(0.6,0.6,0.05,0.05))
mosaicplot(hardtable2, main='', xlab="Standards-compliant freshness lifetime", ylab="Relative abundance of resource types", color=c("red", "blue", "green", "yellow"))
dev.off()

heuristicall <- apply(heuristictable, 1, sum)
pdf(file="heuristicall.pdf", height=5.2,width=8)
par(mai=c(1,1,0.2,0.05))
bpheuristic <- barplot(heuristicall, col="white", xlab="Simple heuristic freshness lifetime", ylab="Number of occurrences", main='')
text(bpheuristic, heuristicall, labels=paste0(signif(heuristicall*100/sum(heuristicall),2),'%'), pos=1)
dev.off()

pdf(file="heuristictable.pdf", height=5.2,width=8)
par(mai=c(0.6,0.6,0.05,0.05))
mosaicplot(heuristictable, main='', xlab="Heuristic freshness lifetime", ylab="Relative abundance of resource types", color=c("red", "blue", "green", "yellow"))
dev.off()

harderrordata <- sparqlfile("failed-hard.rq")
harderrordata$results$fresh[harderrordata$results$fresh <0] <- 0
errorok <- harderrordata$results$fresh[which(harderrordata$results$status == "OK")]
errorparse <- harderrordata$results$fresh[which(harderrordata$results$status == "parseerror")]
pdf(file="errorsqq.pdf", height=4,width=4)
par(mai=c(1,1,0.2,0.05))
qqplot(errorok,errorparse, xlab="Lifetime when no errors", ylab="Lifetime with parse errors")
dev.off()

