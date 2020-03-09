## Using enrichment analysis to compare and annotate PFOCR gene sets
#  with public gene sets, e.g,. OMIM, Jensen Disease, etc.
#
#  See wp-gmt-overlap.R for a similar analysis w.r.t. WikiPathways content
#  to, for example, prioritize PFOCR figures for curation

## Set to your own local working directory
setwd("~/Dropbox (Gladstone)/PFOCR_25Years") #AP

## Libraries
load.libs <- c(
  "DOSE",
  "GO.db",
  "GSEABase",
  "org.Hs.eg.db", ## Human-specific
  "clusterProfiler",
  "plyr", 
  "dplyr",
  "tidyr",
  "magrittr",
  "stringr",
  "rWikiPathways")
options(install.packages.check.source = "no")
options(install.packages.compile.from.source = "never")
if (!require("pacman")) install.packages("pacman"); library(pacman)
p_load(load.libs, update = TRUE, character.only = TRUE)
status <- sapply(load.libs,require,character.only = TRUE)
if(all(status)){
  print("SUCCESS: You have successfully installed and loaded all required libraries.")
} else{
  cat("ERROR: One or more libraries failed to install correctly. Check the following list for FALSE cases and try again...\n\n")
  status
}

library(plyr)  ## for ldply and ddply

####################
## Collect gene sets
####################

# For example, download files via https://amp.pharm.mssm.edu/Enrichr/#stats

## Process Jensen disease files to gmts and save
# jensen_know <- read.csv("raw/human_disease_knowledge_filtered.tsv", sep="\t", stringsAsFactors = F)[ ,c(2,4)]
# colnames(jensen_know) <- c("symbol", "disease")
# jensen_know2 <- jensen_know %>%
#   dplyr::group_by(disease) %>%
#   dplyr::filter(n() > 7) %>%
#   dplyr::summarise(symbol_all = paste(symbol,collapse="\t"))
# write.table(jensen_know2, file = "raw/jensen_know.gmt", append = FALSE, quote = FALSE, sep = "\t",
#            na = "NA", dec = ".", row.names = FALSE,
#             col.names = FALSE)

## Prepare list of gene sets from GMTs (e.g., downloaded from Enrichr)
gmt.file <- "raw/omim-disease.gmt"
gmt <- clusterProfiler::read.gmt(gmt.file)
gmt.entrez <- bitr(gmt$gene,fromType = "SYMBOL",toType = "ENTREZID",OrgDb = org.Hs.eg.db)
gmt <-gmt %>%
  dplyr::left_join(gmt.entrez, by=c("gene" = "SYMBOL")) %>%
  dplyr::filter(!is.na(ENTREZID)) %>%
  dplyr::select(ont, ENTREZID)
gmt.lists <- gmt %>% group_by(ont) %>%
  dplyr::summarize(cnt = n(),
                   genes = list(ENTREZID))
gmt.all.genes <- unique(gmt$ENTREZID)

####################
## Prepare PFOCR GMT
####################

## Prepare GMT of PFOCR results to serve as enrichment database
pfocr.genes <- readRDS("pfocr_genes.rds") %>%
  dplyr::select(figid, word, source, entrez)

# Get counts of nobe genes in order to subset:
# First collapse bioentity cases per figure and word,...
pfocr.nobe <- pfocr.genes %>% 
  dplyr::select(-entrez) %>% 
  dplyr::group_by(figid, word, source) %>%
  dplyr::summarise(entrez_count = n()) 
# ... then count entrez per figure.
pfocr.nobecnt <- pfocr.nobe %>% 
  dplyr::select(-source, -word) %>% 
  dplyr::group_by(figid) %>%
  dplyr::summarise(entrez_count = n()) #  count
# Subset with N or more nobe genes
pfocr.nobecnt7 <- pfocr.nobecnt %>%
  dplyr::filter(entrez_count >= 7) %>%
  ungroup()
# Prepare subset for enrichment database
pfocr.genes.sub <- pfocr.genes %>%
  dplyr::filter(figid %in% pfocr.nobecnt7$figid)

## Make clusterProfiler enricher files from PFOCR 
pfocr2gene <- pfocr.genes.sub %>% dplyr::select(figid,entrez) #TERM2GENE
pfocr2name <- pfocr.genes.sub %>% mutate(name = figid) %>% dplyr::select(figid,name) #TERM2NAME
pfocr2name<-unique(pfocr2name)

#####################
## Perform Enrichment
#####################

# Apply to each gene set in list  
gmt.pfocr.overlaps <- plyr::ldply(gmt.lists$ont, function(term){
  
  gmt.term.genes <- gmt %>%
    dplyr::filter(ont == term) %>%
    dplyr::select(ENTREZID)
  
  ## WikiPathways Analysis
  ewp <- clusterProfiler::enricher(
    gene = gmt.term.genes$ENTREZID,
    universe = gmt.all.genes,
    pAdjustMethod = "fdr",
    pvalueCutoff = 0.05, #p.adjust cutoff
    minGSSize = 2,
    maxGSSize = 500,
    TERM2GENE = pfocr2gene,
    TERM2NAME = pfocr2name)
  #ewp <- DOSE::setReadable(ewp, org.Hs.eg.db, keyType = "ENTREZID")
  #head(ewp, 20)
  
  ## stash results
  if (!is.null(ewp)){
    res <- ewp@result %>%
      dplyr::filter(p.adjust < 0.05)
    if (nrow(res) > 0){
      res <- res %>%
        mutate (ont = term,
                cnt = gmt.lists$cnt[which(gmt.lists$ont == term)],
                genes = paste(unlist(gmt.lists$genes[which(gmt.lists$ont == term)]), collapse = ", "),
                figid = ID,
                pf.overlap.cnt = Count,
                pf.overlap.genes = str_replace_all(geneID, "/",", ")
        ) %>%
        dplyr::select(ont, cnt, genes, figid, pf.overlap.cnt, pf.overlap.genes)
    }
  }
})

#write.table(gmt.pfocr.overlaps, "raw/gmt-pfocr-omim-overlaps_7.tsv", quote=F, sep="\t", row.names = F)
#gmt.pfocr.overlaps <- read.table("raw/gmt-pfocr-omim-overlaps_7.tsv", header=T, sep="\t", stringsAsFactors = F)

## Basic counts
sprintf("Unique figures with hits: %i",length(unique(gmt.pfocr.overlaps$figid)))
gmt.pfocr.overlaps.genes <- gmt.pfocr.overlaps %>% 
  dplyr::select(1,6) %>% 
  mutate(genes = strsplit(pf.overlap.genes, ",", fixed = T)) %>% 
  unnest(genes) %>% 
  dplyr::select(c(1,3))
sprintf("Unique overlapping genes: %i",length(unique(gmt.pfocr.overlaps.genes$genes)))
sprintf("Unique enriched terms: %i",length(unique(gmt.pfocr.overlaps$ont)))


## nobe7:
# 15,957/28,236 figures with hits (57%)
# 880/1526 disease genes
# 78/90 disease terms

## nobe10:
# 11,874/18,917 figures with hits (63%)
# 838/1526 disease genes 
# 78/90 disease terms


#########################
## Annotate PFOCR figures
#########################
# pfocr.figs <- readRDS("pfocr_figures.rds") %>%
#   dplyr::select(figid)

## Aggregate with prior results
pfocr.figs <- read.table("tables/enriched_annots.tsv", header=T, sep="\t", stringsAsFactors = F)

gmt.pfocr.overlaps.tidy <- gmt.pfocr.overlaps %>%
  mutate(omim7 = ont) %>%
  dplyr::select(figid, omim7) %>%
  group_by(figid) %>%
  summarise(omim7_list = paste(unique(omim7), collapse=" | "),
            omim7_cnt = n()) 

enriched.annots <- merge(gmt.pfocr.overlaps.tidy, 
                         pfocr.figs, 
                         by = "figid", 
                         all.y = TRUE)

write.table(enriched.annots, "tables/enriched_annots.tsv", quote=F, sep="\t", row.names = F)

