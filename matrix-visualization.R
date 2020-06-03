library(igraph)
library(ggplot2)
library(ggdendro)
library(reshape2)
library(grid)
library(ggpubr)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

data <- read.table(file="hippo-combined-5genes-new.txt", header = FALSE, sep="\t")

G <- graph.data.frame(data,directed=TRUE)
data.overlap <- as_adjacency_matrix(G,type="both",names=TRUE,sparse=FALSE,attr="V3")
data.jaccard <- as_adjacency_matrix(G,type="both",names=TRUE,sparse=FALSE,attr="V4")

overlap.dendro <- as.dendrogram(hclust(d = dist(x = data.overlap)), horiz=FALSE)
dendro.plot <- ggdendrogram(data = overlap.dendro, rotate = TRUE, labels=FALSE)
dendro.order <- order.dendrogram(overlap.dendro)

data.overlap.sorted <- data.overlap[dendro.order,dendro.order]
data.jaccard.sorted <- data.jaccard[dendro.order,dendro.order]

data.overlap.long <- melt(data.overlap.sorted, id = c("f1", "f2", "overlap"))
data.jaccard.long <- melt(data.jaccard.sorted, id = c("f1", "f2", "overlap"))

overlap.plot <-   ggplot(data.overlap.long, aes(Var2, Var1, fill= value)) + 
  geom_tile() +
  scale_y_discrete(limits = rev(levels(data.overlap.long$Var1))) +
  scale_fill_continuous(name="overlap", labels=c("0%","25%","50%","75%", "100%")) +
  theme(axis.text.x=element_blank(),
        axis.text.y=element_blank(),
        axis.title = element_blank(),
        axis.ticks.x = element_blank(), 
        legend.position = "top")


jaccard.plot <- ggplot(data.jaccard.long, aes(Var1, Var2, fill= value)) + 
  geom_tile() +
  theme(axis.text.x=element_blank(),
        axis.text.y=element_blank())

grid.newpage()
print(overlap.plot, vp = viewport(x = 0.4, y = 0.5, width = 0.8, height = 1.0))
print(dendro.plot, vp = viewport(x = 0.90, y = 0.40, width = 0.2, height = 1.0))

ggarrange(dendro.plot, overlap.plot,
          labels = c("Percentage overlap", "Dendrogram"),
          ncol = 2, nrow = 1)
