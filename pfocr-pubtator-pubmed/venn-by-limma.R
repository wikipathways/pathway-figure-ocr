# using lib limma
# can't do proportional for this

install.packages("tidyverse")
source("http://www.bioconductor.org/biocLite.R")
biocLite("limma")

library(tidyverse)
library(limma)

pfocr_genes <- read_tsv("./4k_pfocr_unique_genes.tsv", col_names = c("gene")) %>%
  rowwise() %>% mutate(PFOCR = 1)

pubtator_genes <- read_tsv("./4k_pubtator_unique_genes.tsv", col_names = c("gene")) %>%
  rowwise() %>% mutate(PubTator = 1)

pubmed_genes <- read_tsv("./4k_pubmed_unique_genes.tsv", col_names = c("gene")) %>%
  rowwise() %>% mutate(PubMed = 1)

combined <- pfocr_genes %>%
  full_join(pubtator_genes, by = "gene") %>%
  full_join(pubmed_genes, by = "gene") %>%
  select(-one_of("gene")) %>% 
  rowwise() %>% mutate_all(funs(replace(., which(is.na(.)), 0)))

vennDiagram(
  vennCounts(combined),
  lwd = 2,
  circle.col = c("#333333", "#66c2a5", "#fc8d62")
)