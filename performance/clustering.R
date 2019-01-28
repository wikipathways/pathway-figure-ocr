## Perform Clustering and Binary Heatmap

install.packages(c("gplots","ggplot2","RColorBrewer"))
library(ggplot2)
library(RColorBrewer)
library(gplots)

# Alt color palette to consider: https://cran.r-project.org/web/packages/viridis/index.html

#read pfocr 
pfocr.4000 <- read.csv('20180413_4000_pfocr_sub.csv',stringsAsFactors = F)

#reshape pfocr into named lists by genes
## all results
pfocr.4000.genes.nl <- unstack(pfocr.4000[,1:2])
## subset excluding bioentities hits
pfocr.4000.nobe.genes.nl <- unstack(pfocr.4000[sapply(pfocr.4000$source, function(x) x!="bioentities_symbol"),1:2])


#HEATMAP #1: all results
## first, prepare subsets to cluster and plot
## only genes on more than x pmc...
pfocr.4000.genes.count<-lapply(pfocr.4000.genes.nl,length)
pfocr.4000.top.genes<-names(pfocr.4000.genes.count[sapply(pfocr.4000.genes.count, function(x) x>10)])
pfocr.4000.top.genes.nl<-pfocr.4000.genes.nl[pfocr.4000.top.genes]
### reshape into named list by pmc
pfocr.4000.top.genes.sk<-stack(pfocr.4000.top.genes.nl)
pfocr.4000.top.nl<-unstack(pfocr.4000.top.genes.sk[,2:1])

## ...and only pmc with more than y of those genes
pfocr.4000.top.count<-lapply(pfocr.4000.top.nl,length)
pfocr.4000.top.pmc<-names(pfocr.4000.top.count[sapply(pfocr.4000.top.count, function(y) y>24)])
pfocr.4000.top.nl<-pfocr.4000.top.nl[pfocr.4000.top.pmc]

## get unique gene list for x-axis
unique.4000.top.genes<-c()
for (p in names(pfocr.4000.top.nl)){
    unique.4000.top.genes <- c(unique.4000.top.genes, setdiff(pfocr.4000.top.nl[[p]],unique.4000.top.genes))
}

## initialize dataframe for heatmap
pfocr.4000.top.matrix.df <- data.frame(matrix(nrow=length(names(pfocr.4000.top.nl)),ncol=length(unique.4000.top.genes)))
row.names(pfocr.4000.top.matrix.df)<-names(pfocr.4000.top.nl)
colnames(pfocr.4000.top.matrix.df)<-as.character(unique.4000.top.genes)

## build dataframe 
### WARNING: This takes a few minutes
t=0
for (p in names(pfocr.4000.top.nl)){
    print(paste(p,t,sep=" -- "))
    t=t+1
    for (g in unique.4000.top.genes){
        val<-0
        if(g %in% pfocr.4000.top.nl[[p]]) val<-1
        pfocr.4000.top.matrix.df[p,as.character(g)]<-val
    }
}

## calc clusters
d = dist(pfocr.4000.top.matrix.df, method = "binary")
hc = hclust(d, method="ward.D2")

## cut into k.num clusters and prep color strip
k.num=20
hh<-cutree(hc,k=k.num )
clusters<-split(names(hh),hh)
nofclust.height <-  length(unique(as.vector(hh)));
selcol <- colorRampPalette(RColorBrewer::brewer.pal(9,"Set1"))
clustcol.height = selcol(nofclust.height);

## prep matrix, order and color by clusters
pfocr.4000.top.matrix<- as.matrix(pfocr.4000.top.matrix.df)
pfocr.4000.top.matrix.k<-as.matrix(pfocr.4000.top.matrix[unname(unlist(clusters)),])
hh.k<-hh[unname(unlist(clusters))]
#write.csv(hh.k,"clusters_top10x24.csv")

## plot (uncomment to print)
#png(filename = "pfocr_4000_top10x24_cluster.png", width = 8000, height=8800,res = 170)
gplots::heatmap.2(pfocr.4000.top.matrix.k, 
                  key = F,
                  dendrogram="none",
                  trace="none",
                  scale="none", 
                  col=c("white","blue"), 
                  RowSideColors=clustcol.height[hh.k],
                  xlab="Entrez Gene IDs",
                  ylab="PMCIDs",
                  Rowv=F
)
#dev.off()

#HEATMAP #2: excluding bioentites hits
## first, prepare subsets to cluster and plot
## only genes on more than x pmc...
pfocr.4000.nobe.genes.count<-lapply(pfocr.4000.nobe.genes.nl,length)
pfocr.4000.nobe.top.genes<-names(pfocr.4000.nobe.genes.count[sapply(pfocr.4000.nobe.genes.count, function(x) x>10)])
pfocr.4000.nobe.top.genes.nl<-pfocr.4000.nobe.genes.nl[pfocr.4000.nobe.top.genes]
### reshape into named list by pmc
pfocr.4000.nobe.top.genes.sk<-stack(pfocr.4000.nobe.top.genes.nl)
pfocr.4000.nobe.top.nl<-unstack(pfocr.4000.nobe.top.genes.sk[,2:1])

## ...and only pmc with more than y of those genes
pfocr.4000.nobe.top.count<-lapply(pfocr.4000.nobe.top.nl,length)
pfocr.4000.nobe.top.pmc<-names(pfocr.4000.nobe.top.count[sapply(pfocr.4000.nobe.top.count, function(y) y>7)])
pfocr.4000.nobe.top.nl<-pfocr.4000.nobe.top.nl[pfocr.4000.nobe.top.pmc]

## get unique gene list for x-axis
unique.4000.nobe.top.genes<-c()
for (p in names(pfocr.4000.nobe.top.nl)){
    unique.4000.nobe.top.genes <- c(unique.4000.nobe.top.genes, setdiff(pfocr.4000.nobe.top.nl[[p]],unique.4000.nobe.top.genes))
}

## initialize dataframe for heatmap
pfocr.4000.nobe.top.matrix.df <- data.frame(matrix(nrow=length(names(pfocr.4000.nobe.top.nl)),ncol=length(unique.4000.nobe.top.genes)))
row.names(pfocr.4000.nobe.top.matrix.df)<-names(pfocr.4000.nobe.top.nl)
colnames(pfocr.4000.nobe.top.matrix.df)<-as.character(unique.4000.nobe.top.genes)

## build dataframe 
### WARNING: This takes a few minutes
t=0
for (p in names(pfocr.4000.nobe.top.nl)){
    print(paste(p,t,sep=" -- "))
    t=t+1
    for (g in unique.4000.nobe.top.genes){
        val<-0
        if(g %in% pfocr.4000.nobe.top.nl[[p]]) val<-1
        pfocr.4000.nobe.top.matrix.df[p,as.character(g)]<-val
    }
}

## calc clusters
d2 = dist(pfocr.4000.nobe.top.matrix.df, method = "binary")
hc2 = hclust(d2, method="ward.D2")

## cut into k.num clusters and prep color strip
k.num=20
hh2<-cutree(hc2,k=k.num )
clusters2<-split(names(hh2),hh2)
nofclust.height2 <-  length(unique(as.vector(hh2)));
selcol2 <- colorRampPalette(RColorBrewer::brewer.pal(9,"Set1"))
clustcol.height2 = selcol2(nofclust.height2);

## prep matrix, order and color by clusters
pfocr.4000.nobe.top.matrix<- as.matrix(pfocr.4000.nobe.top.matrix.df)
pfocr.4000.nobe.top.matrix.k<-as.matrix(pfocr.4000.nobe.top.matrix[unname(unlist(clusters2)),])
hh.k2<-hh2[unname(unlist(clusters2))]
#write.csv(hh.k2,"clusters_nobe_top10x7.csv")

## plot (uncomment to print)
#png(filename = "pfocr_4000_nobe_top10x7_cluster.png", width = 8000, height=10000,res = 175)
gplots::heatmap.2(pfocr.4000.nobe.top.matrix.k, 
                  key = F,
                  dendrogram="none",
                  trace="none",
                  scale="none", 
                  col=c("white","blue"), 
                  RowSideColors=clustcol.height2[hh.k2],
                  xlab="Entrez Gene IDs",
                  ylab="PMCIDs",
                  Rowv=F
)
#dev.off()
