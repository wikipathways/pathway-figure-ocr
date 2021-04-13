# Interrogate PFOCR for module genes in RAS-RAF-MEK-ERK cascade

library(magrittr)
library(tidyr)
library(dplyr)

## LOCAL INFO PER USER
setwd("~/Dropbox (Gladstone)/PFOCR_25Years") #AP

pfocr.genes <- readRDS("pfocr_genes.rds")

geneset <- c(
  "KRAS",
  "HRAS",
  "NRAS",
  "ARAF",
  "BRAF",
  "RAF1",
  "MAP2K1",
  "MAP2K2",
  "MAPK1",
  "MAPK3")

pfocr.genes.sub <- pfocr.genes %>%
  dplyr::filter(hgnc_symbol %in% geneset) %>%
  dplyr::select(c(figid, hgnc_symbol))%>%
  dplyr::mutate(value=TRUE) %>%
  dplyr::distinct(figid,hgnc_symbol, value)

upset.df <- pfocr.genes.sub %>%
  tidyr::spread(hgnc_symbol, value, convert=T, fill=F)

#### UpSetR: PFOCR and PubTator Genes

library(UpSetR)

pfocr <- upset.df %>% 
  mutate(KRAS = if_else(KRAS == TRUE, 1, 0))%>% 
  mutate(HRAS = if_else(HRAS == TRUE, 1, 0))%>% 
  mutate(NRAS = if_else(NRAS == TRUE, 1, 0))%>% 
  mutate(ARAF = if_else(ARAF == TRUE, 1, 0))%>% 
  mutate(BRAF = if_else(BRAF == TRUE, 1, 0)) %>%
  mutate(RAF1 = if_else(RAF1 == TRUE, 1, 0)) %>%
  mutate(MAP2K1 = if_else(MAP2K1 == TRUE, 1, 0)) %>%
  mutate(MAP2K2 = if_else(MAP2K2 == TRUE, 1, 0)) %>%
  mutate(MAPK1 = if_else(MAPK1 == TRUE, 1, 0)) %>%
  mutate(MAPK3 = if_else(MAPK3 == TRUE, 1, 0)) %>%
  mutate(source = "pfocr")


upset(pfocr,
      nsets = 10, number.angles = 0, point.size = 3.5, line.size = 2,
      order.by = "degree",
      mainbar.y.label = "Pathway Figures with Module Genes", 
      sets.x.label = "Total Gene Mentions",
      text.scale = c(2, 2, 2, 2, 2, 2)
)

