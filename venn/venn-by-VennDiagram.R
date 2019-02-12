# using lib VennDiagram
# proportional

install.packages("tidyverse")
install.packages("VennDiagram")
library(tidyverse)
require(VennDiagram)

pfocr_genes <- read_tsv("./4k_pfocr_unique_genes.tsv",
                        col_types = list(col_character()),
                        col_names = c("gene"))
pubmed_genes <- read_tsv("./4k_pubmed_unique_genes.tsv",
                         col_types = list(col_character()),
                         col_names = c("gene"))
pubtator_genes <- read_tsv("./4k_pubtator_unique_genes.tsv",
                           col_types = list(col_character()),
                           col_names = c("gene"))

MyVennDiagram = venn.diagram(
  x = list(
    pfocr = pfocr_genes$gene,
    pubtator = pubtator_genes$gene,
    pubmed = pubmed_genes$gene
  ),
  filename = NULL,
  euler.d = TRUE,
  scaled = TRUE,
  col = "#555555",
  fontfamily = "Helvetica",
  #fontface = "bold",
  sep.dist = 1,
  cex = 1.5,
  #cex = c(1.5, 1, 1, 0.75, 1, 1, 1),
  #offset = 0.75,
  rotation.degree = -35,
  #rotation.centre = c(5, 30),
  #fill = c("#66c2a5", "#fc8d62", "#8da0cb"),
  fill = c("#f5f5f5", "#66c2a5", "#fc8d62"),
  #margin = 0.05,
  alpha = 0.8,
  #alpha = c(0.3, 0.5, 0.3),
  cat.cex = 2,
  cat.fontface = "bold",
  cat.fontfamily = "Helvetica",
  cat.pos = c(285, 145, 190),
  cat.dist = c(-0.085, 0.025, 0.035)
  #cat.dist = c(0.045, 0.025, 0.035)
)
grid.newpage()
#pushViewport(viewport(width=unit(0.95, "npc"), height = unit(0.95, "npc")));
grid.draw(MyVennDiagram)

