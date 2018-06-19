# using lib eulerr
# proportional

install.packages("tidyverse")
install.packages("eulerr")
library(tidyverse)
require(eulerr)
# see ?plot.euler

pfocr_genes <- read_tsv("./4k_pfocr_unique_genes.tsv", col_names = c("gene")) %>%
  rowwise() %>% mutate(PFOCR = TRUE)
pubtator_genes <- read_tsv("./4k_pubtator_unique_genes.tsv", col_names = c("gene")) %>%
  rowwise() %>% mutate(PubTator = TRUE)
pubmed_genes <- read_tsv("./4k_pubmed_unique_genes.tsv", col_names = c("gene")) %>%
  rowwise() %>% mutate(PubMed = TRUE)

combined <- pfocr_genes %>%
  full_join(pubtator_genes, by = "gene") %>%
  full_join(pubmed_genes, by = "gene") %>%
  select(-one_of("gene")) %>%
  rowwise() %>% mutate_all(funs(replace(., which(is.na(.)), FALSE)))

plot(euler(combined, shape = "ellipse"),
     labels = list(
       # NOTE: w/out setting these, PubTator runs off the board
       # Remove the "\n" to move PubMed down
       labels = c("PFOCR", "PubTator     ", "\nPubMed"),
       fontsize = 20,
       col = "#333333"
       # the following options don't seem to do anything consistent
       #check.overlap = TRUE,
       #x = c(100, 100, 100),
       #y = c(unit(0.5, "npc"), unit(-0.5, "npc"), unit(-0.5, "npc")),
       #y = c(0, 0.5, 0.2)
       #control = "extraopt_threshold",
     ),
     quantities = list(fontsize = 18),
     fills = list(
       fill = c("#fefefe", "#66c2a5", "#fc8d62"),
       col = "#333333",
       alpha = 0.7
     ),
     edges = list(col = "#333333")
     #edges = FALSE
)

