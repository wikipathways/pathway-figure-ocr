## Generate Performance Measures for Plots and Table

install.packages(c("ggplot2"))
install.packages(c("RColorBrewer"))
library(ggplot2,RColorBrewer)

#read pfocr and gmt
pfocr <- read.csv('20180418_wp_hs_pfocr_sub.csv',stringsAsFactors = F)
gmt <- read.csv('20180418_wp_hs_gmt.csv',stringsAsFactors = F)

#reshape pfocr into named list
pfocr.nl <- unstack(pfocr[,2:1])

#do the same for a named source list
pfocr.source.tall <- pfocr[,c(4,1)]
pfocr.source.nl <- unstack(pfocr.source.tall) 

#reshape gmt into named list
gmt.p <- factor(gmt[,1])
gmt.nl <- c()
for(i in 1:nrow(gmt)){
    p <- as.character(gmt.p[i])
    e <- c()
    for (j in 2:ncol(gmt)){
        if (!is.na(gmt[i,j]))
            e <- c(e, gmt[i,j]) 
    }
    gmt.nl[[p]] <- e
}

#take intersection with lexicon to exclude entrez ids that we didn't attempt to match, e.g., miRNA
lex1 <- read.csv('../lexicon/1_symbol.csv',stringsAsFactors = F)
lex2 <- read.csv('../lexicon/2_bioentities.csv',stringsAsFactors = F)
lex3 <- read.csv('../lexicon/3_alias_symbol.csv',stringsAsFactors = F)
lex4 <- read.csv('../lexicon/4_prev_symbol.csv',stringsAsFactors = F)
lex<- c(lex1[,1], lex2[,1], lex3[,1], lex4[,1])
lex <- unique(lex)
gmt.lex.nl <- c()
for(p in names(gmt.nl)){
    gmt.lex.nl[[p]] <- intersect(gmt.nl[[p]],lex)
}

#perform initial comparisons
tp <- c()
fp <- c()
tp.source <- c()
fp.source <- c()
fn <- c()
for (p in names(pfocr.nl)) {
    tp[[p]] <- intersect(pfocr.nl[[p]], gmt.lex.nl[[p]])
    fp[[p]] <- setdiff(pfocr.nl[[p]], gmt.lex.nl[[p]])
    tp.source[[p]] <- pfocr.source.nl[[p]][match(tp[[p]],pfocr.nl[[p]])]
    fp.source[[p]] <- pfocr.source.nl[[p]][match(fp[[p]],pfocr.nl[[p]])]
}
for (p in names(gmt.lex.nl)) {
    fn[[p]] <- setdiff(gmt.lex.nl[[p]], pfocr.nl[[p]])
}

#assess FP by source
## FP based on bioentities checked out as legitimate TPs;
## add fp.be to tp and define fp.real, excluding fp.be 
tp.fp.be <- list()
fp.real <- list()
for (p in names(pfocr.nl)) {
    tp.fp.be[[p]] <- fp.source[[p]][which(fp.source[[p]] == "bioentities_symbol")]
    fp.real[[p]] <- fp.source[[p]][-which(fp.source[[p]] == "bioentities_symbol")]
}

#prepare final counts
tp.count <- lapply(tp, length)
tp.fp.be.count <- lapply(tp.fp.be, length)
fp.real.count <- lapply(fp.real, length)
fn.count <- lapply(fn, length)
counts <- c()
counts.tp <- c()
counts.fp <- c()
counts.fn <- c()
for (p in names(gmt.lex.nl)) {
    tp.p<-0
    fp.p<-0
    tp.fp.be.p<-0
    fn.p<-0
    if(!is.null(tp.count[[p]])) tp.p<-tp.count[[p]]
    if(!is.null(fp.real.count[[p]])) fp.p<-fp.real.count[[p]]
    if(!is.null(tp.fp.be.count[[p]])) tp.fp.be.p<-tp.fp.be.count[[p]]
    if(!is.null(fn.count[[p]])) fn.p<-fn.count[[p]]
    counts[[p]] <- c(tp.p+tp.fp.be.p, fp.p, fn.p)
    if((tp.p+tp.fp.be.p)>fp.p && (tp.p+tp.fp.be.p) >fn.p)
        counts.tp[[p]] <- c(tp.p, fp.p, fn.p)
    if(fp.p>(tp.p+tp.fp.be.p) && fp.p >fn.p)
        counts.fp[[p]] <- c(tp.p, fp.p, fn.p)
    if(fn.p>fp.p && fn.p >(tp.p+tp.fp.be.p))
        counts.fn[[p]] <- c(tp.p, fp.p, fn.p)
}

## plot rates by pathway
counts.df <- as.data.frame(counts)
rownames(counts.df) <- c("TP","FP","FN")

counts.df.sk <- stack(counts.df)
counts.df.sk$type <- c("TP","FP","FN")
counts.df.sk$sort <- c(0,0,0)
colnames(counts.df.sk) <- c("counts","pathway","type","sort")
## add sort col
for (r in 1:length(counts.df.sk$pathway)){
    if(counts.df.sk$type[r]=="TP")
        counts.df.sk$sort[r]<-counts.df.sk$counts[r]
}

ggplot(counts.df.sk, aes(group=type, y=counts, x=reorder(pathway,-sort))) +
    geom_line(aes(color=type)) +
    geom_point(aes(color=type)) +
    xlab("Pathways")+
    ylab("Counts by Type")+
    theme(
        axis.text.x = element_blank(), 
        axis.ticks.x = element_blank(),
        panel.background = element_rect(fill = 'white'),
        legend.position = "none",
        axis.text=element_text(size=16),
        axis.title=element_text(size=16)
        )

## plot rates independently sorted
counts.df.sk.tp<-counts.df.sk[counts.df.sk$type=="TP",2:1]
counts.df.sk.tp<-counts.df.sk.tp[order(-counts.df.sk.tp$counts),]
counts.df.sk.tp$sort<-c(1:length(counts.df.sk.tp$pathway))
counts.df.sk.tp$type<-c(rep("3.TP"))
counts.df.sk.fp<-counts.df.sk[counts.df.sk$type=="FP",2:1]
counts.df.sk.fp<-counts.df.sk.fp[order(-counts.df.sk.fp$counts),]
counts.df.sk.fp$sort<-c(1:length(counts.df.sk.fp$pathway))
counts.df.sk.fp$type<-c(rep("1.FP"))
counts.df.sk.fn<-counts.df.sk[counts.df.sk$type=="FN",2:1]
counts.df.sk.fn<-counts.df.sk.fn[order(-counts.df.sk.fn$counts),]
counts.df.sk.fn$sort<-c(1:length(counts.df.sk.fn$pathway))
counts.df.sk.fn$type<-c(rep("2.FN"))

### overlapping
ggplot(counts.df.sk.tp, aes(y=counts,x=sort,color="red"))+geom_area(fill="#619CFF") +
    geom_area(data=counts.df.sk.fn, aes(y=counts,x=sort,color="blue"), fill="#F8766D") +
    geom_area(data=counts.df.sk.fp, aes(y=counts,x=sort,color="green"), fill="#00BA38") +
    xlab("Independently Ordered Pathways")+
    ylab("Stacked Counts by Type")+
    scale_x_continuous(breaks=c(1,100,200,300,400), expand = c(0,0))+
    scale_y_continuous(expand = c(0,0))+
    theme(
        panel.background = element_rect(fill = 'white'),
        legend.position = "none"
    )

### stacked
counts.df.sk.indi<-rbind(counts.df.sk.fp,counts.df.sk.fn,counts.df.sk.tp)
p<-ggplot(counts.df.sk.indi, aes(y=counts, x=sort, fill=type))
p + geom_area() + 
    scale_fill_manual(values=c("#00BA38","#F8766D","#619CFF")) +
    xlab("Independently Ordered Pathways")+
    ylab("Stacked Counts by Type")+
        scale_x_continuous(breaks=c(1,100,200,300,400), expand = c(0,0))+
    scale_y_continuous(expand = c(0,0))+
    theme(
         panel.background = element_rect(fill = 'white'),
         legend.position = "none",
         axis.text=element_text(size=22),
         axis.title=element_text(size=22)
         )

#median and means
tp.med <- median(unlist(counts.df.sk.tp$counts))
fp.med <- median(unlist(counts.df.sk.fp$counts))
fn.med <- median(unlist(counts.df.sk.fn$counts))
tp.med
fp.med
fn.med
tp.mean <- mean(unlist(counts.df.sk.tp$counts))
fp.mean <- mean(unlist(counts.df.sk.fp$counts))
fn.mean <- mean(unlist(counts.df.sk.fn$counts))
tp.mean
fp.mean
fn.mean

#performance stats
## recall: tp/(tp+fn)
tpfn.list= Map("+",unlist(counts.df.sk.tp$counts),unlist(counts.df.sk.fn$counts))
tpr.list<-Map("/",unlist(counts.df.sk.tp$counts),tpfn.list)
tpr.list<-na.omit(unlist(tpr.list))
tpr.med <- median(tpr.list)
tpr.std <- sd(tpr.list)
tpr.min <- min(tpr.list)
tpr.max <- max(tpr.list)

## precision: tp/(tp+fp)
tpfp.list= Map("+",unlist(counts.df.sk.tp$counts),unlist(counts.df.sk.fp$counts))
ppv.list<-Map("/",unlist(counts.df.sk.tp$counts),tpfp.list)
ppv.list<-na.omit(unlist(ppv.list))
ppv.med <- median(ppv.list)
ppv.std <- sd(ppv.list)
ppv.min <- min(ppv.list)
ppv.max <- max(ppv.list)

## false negative rate
fnr.list <- unlist(lapply(tpr.list, function(x) 1-x))
fnr.med <- median(fnr.list)
fnr.std <- sd(fnr.list)
fnr.min <- min(fnr.list)
fnr.max <- max(fnr.list)

## false discovery rate
fdr.list <- unlist(lapply(ppv.list, function(x) 1-x))
fdr.med <- median(fdr.list)
fdr.std <- sd(fdr.list)
fdr.min <- min(fdr.list)
fdr.max <- max(fdr.list)

## F-measure: 2*(ppv * tpr / (ppv + tpr))
fm.med <- 2 * (ppv.med * tpr.med / (ppv.med + tpr.med))
ppvtpr.med.sum <- ppv.med + tpr.med
ppvtpr.std.sum <- sqrt(ppv.std^2+tpr.std^2)
fm.std <-2*(ppv.med * tpr.med / ppvtpr.med.sum *
    sqrt((ppv.std/ppv.med)^2+
             (tpr.std/tpr.med)^2 +(ppvtpr.std.sum/ppvtpr.med.sum)^2))


#################
# Percent coverage of WP human signaling pathways
install.packages('rWikiPathways')
library(rWikiPathways)

## take subset of pathways tagged with a child term of 'signaling pathway'
sigwp<-getPathwayIdsByParentOntologyTerm("PW:0000003")
gmt.sig.nl <- c()
for(p in names(gmt.nl)){
    if(p %in% sigwp)
        gmt.sig.nl[[p]] <- gmt.nl[[p]]
}
length(gmt.sig.nl)

## take intersection with lexicon to exclude entrez ids that we didn't attempt to match, e.g., miRNA
gmt.sig.lex.nl <- c()
for(p in names(gmt.sig.nl)){
    gmt.sig.lex.nl[[p]] <- intersect(gmt.nl[[p]],lex)
}

## get unique list of WP human signaling pathway genes
gmt.sig.lex.genes <- unique(unlist(gmt.sig.lex.nl))

## get unique list of PFOCR.4000 genes
pfocr.4000 <- read.csv('20180413_4000_pfocr_sub.csv',stringsAsFactors = F)
pfocr.4000.nl <- unstack(pfocr.4000[,2:1])
pfocr.4000.genes <- unique(unlist(pfocr.4000.nl))

## compare
overlap<-length(intersect(gmt.sig.lex.genes,pfocr.4000.genes))
ratio<-overlap/length(gmt.sig.lex.genes)
