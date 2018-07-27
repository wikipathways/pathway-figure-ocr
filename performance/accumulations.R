## Generate Plot of Accumulating Unique Genes

#read wp and 4000 pfocr
pfocr.wp <- read.csv('20180418_wp_hs_pfocr_sub.csv',stringsAsFactors = F)
pfocr.4000 <- read.csv('20180413_4000_pfocr_sub.csv',stringsAsFactors = F)

#reshape pfocr into named list
pfocr.wp.nl <- unstack(pfocr.wp[,2:1])
pfocr.4000.nl <- unstack(pfocr.4000[,2:1])

#average number of genes per pathway/image
pfocr.wp.med<-median(unlist(lapply(pfocr.wp.nl, length)))
pfocr.wp.med
pfocr.4000.med<-median(unlist(lapply(pfocr.4000.nl, length)))
pfocr.4000.med
pfocr.wp.mean<-mean(unlist(lapply(pfocr.wp.nl, length)))
pfocr.wp.mean
pfocr.4000.mean<-mean(unlist(lapply(pfocr.4000.nl, length)))
pfocr.4000.mean

#plot accumulation of unique genes in pfocr WP
unique.genes<-c()
unique.genes.counts<-c()
for (p in names(pfocr.wp.nl)){
    unique.genes <- c(unique.genes, setdiff(pfocr.wp.nl[[p]],unique.genes))
    unique.genes.counts <- c(unique.genes.counts,length(unique.genes))
}
plot(unique.genes.counts)
## fit curve
xx<-seq(1:length(unique.genes.counts))
fit<-lm(unique.genes.counts~sqrt(xx))
summary(fit)
lines(xx, predict(fit, data.frame(x=xx)), col="red", lwd=2)
predict(fit,data.frame(xx=269))  
# 5300 WP pathways = 20,000 unique genes
# 269 WP pathways = 4000 genes

#plot accumulation of unique genes in pfocr 4000
unique.4000.genes<-c()
unique.4000.genes.counts<-c()
for (p in names(pfocr.4000.nl)){
    unique.4000.genes <- c(unique.4000.genes, setdiff(pfocr.4000.nl[[p]],unique.4000.genes))
    unique.4000.genes.counts <- c(unique.4000.genes.counts,length(unique.4000.genes))
}
plot(unique.4000.genes.counts)
## fit curve
xx<-seq(1:length(unique.4000.genes.counts))
fit<-lm(unique.4000.genes.counts~sqrt(xx))
summary(fit)
plot(unique.4000.genes.counts)
lines(xx, predict(fit, data.frame(x=xx)), col="red", lwd=2)
predict(fit,data.frame(xx=2925))  
# 12,000 PFOCR images = 8000 unique genes
# 2925 images = 4000 genes
