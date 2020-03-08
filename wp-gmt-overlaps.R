# This script will take a GMT (like from Enrichr) and then perform
# enrichment analysis on each of the GMT terms against all of WikiPathways.
# It will generate a dataframe that can be used to make new GMT and
# annotation files. 

# Set to your own local working directory
setwd("~/Dropbox (Gladstone)/PFOCR_25Years") #AP

# Libraries
load.libs <- c(
  "DOSE",
  "GO.db",
  "GSEABase",
  "org.Hs.eg.db", ## Human-specific
  "clusterProfiler",
  "plyr",  ## for ldply
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

# Prepare WikiPathways GMT
#wp.hs.gmt <- rWikiPathways::downloadPathwayArchive(date="current", organism="Homo sapiens", format = "gmt")
wp.hs.gmt <-"raw/wikipathways-20200210-gmt-Homo_sapiens.gmt"
wp2gene <- clusterProfiler::read.gmt(wp.hs.gmt)
wp2gene <- wp2gene %>% tidyr::separate(ont, c("name","version","wpid","org"), "%")
wpid2gene <- wp2gene %>% dplyr::select(wpid,gene) #TERM2GENE
wpid2name <- wp2gene %>% dplyr::select(wpid,name) #TERM2NAME
wpid2name<-unique(wpid2name)

## Process Jensen disease files
# jensen_text <- read.csv("raw/human_disease_textmining_filtered.tsv", sep="\t", stringsAsFactors = F)[ ,c(2,4)]
# colnames(jensen_text) <- c("symbol", "disease")
# jensen_know <- read.csv("raw/human_disease_knowledge_filtered.tsv", sep="\t", stringsAsFactors = F)[ ,c(2,4)]
# colnames(jensen_know) <- c("symbol", "disease")
# jensen_exp <- read.csv("raw/human_disease_experiments_filtered.tsv", sep="\t", stringsAsFactors = F)[ ,c(2,4)]
# colnames(jensen_exp) <- c("symbol", "disease")
# 
# jensen_text2 <- plyr::ddply(jensen_text, .(disease), summarize, symbol_all=paste(symbol,collapse="\t"))
# jensen_text2 <- jensen_text %>%
#   group_by(disease) %>%
#   summarise(symbol_all=paste(symbol,collapse="\t"))
# write.table(jensen_text2, file = "raw/jensen_text.gmt", append = FALSE, quote = FALSE, sep = "\t",
#            na = "NA", dec = ".", row.names = FALSE, 
#             col.names = FALSE)

# Get GMT from file (e.g., downloaded from Enrichr)
gmt.file <- "raw/omim_disease.gmt"
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
  
# Apply to each term in GMT  
gmt.wp.overlaps <- plyr::ldply(gmt.lists$ont, function(term){

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
    TERM2GENE = wpid2gene,
    TERM2NAME = wpid2name)
  #ewp <- DOSE::setReadable(ewp, org.Hs.eg.db, keyType = "ENTREZID")
  #head(ewp, 20)
  
  ## stash results
  if (!is.null(ewp)){
    res <- ewp@result %>%
      dplyr::filter(p.adjust < 0.05)
    
    ovr.genes <- res %>%
      tidyr::separate_rows(geneID, sep="/") %>%
      dplyr::distinct(geneID)
    
    gmt.lists[gmt.lists$ont == term,] %<>%
      dplyr::mutate(wp.cnt = length(res$ID),
             wpids = paste(res$ID, collapse = ","),
             overlap.cnt = length(ovr.genes$geneID),
             overlap.genes = paste(ovr.genes$geneID, collapse = ", ")
      )
  }
})

## Flatten and save
gmt.wp.overlaps <- gmt.wp.overlaps %>%
  rowwise() %>%
  dplyr::mutate(genes = paste(unlist(genes), collapse = ", "))

#write.table(gmt.wp.overlaps, "raw/gmt-wp-overlaps.tsv", quote=F, sep="\t", row.names = F)
gmt.wp.overlaps <- read.table("raw/gmt-wp-overlaps.tsv", header=T, sep="\t", stringsAsFactors = F)

disease.wp.cnt <- nrow(filter(gmt.wp.overlaps, wp.cnt > 0))
disease.wp.pct20 <- nrow(filter(gmt.wp.overlaps, overlap.cnt / cnt > 0.20))

disease.genes.prioritized <- gmt.wp.overlaps %>%
  mutate(overlap.pct = overlap.cnt / cnt) %>%
  filter(overlap.pct < 0.20, wp.cnt == 0) %>%
  arrange(overlap.pct, wp.cnt, cnt)

#write.table(disease.genes.prioritized, "raw/disease-genes-prioritized.tsv", quote=F, sep="\t", row.names = F)
disease.genes.prioritized <- read.table("raw/disease-genes-prioritized.tsv", header=T, sep="\t", stringsAsFactors = F)


###############
## CHECK PFOCR
###############
pfocr.genes <- readRDS("pfocr_genes.rds") %>%
  dplyr::select(figid, word, source, entrez)

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
pfocr.nobecnt10 <- pfocr.nobecnt %>%
  dplyr::filter(entrez_count >= 10) %>%
  ungroup()

## Prepare subset for pathway enrichment collection
pfocr.genes.sub <- pfocr.genes %>%
  dplyr::filter(figid %in% pfocr.nobecnt10$figid)

## Make clusterProfiler enricher files from PFOCR + WP (for more stringent/relevant stats), 
## then repeat ORA with GMT
pfocr2gene <- pfocr.genes.sub %>% dplyr::select(figid,entrez) #TERM2GENE
pfocr2name <- pfocr.genes.sub %>% mutate(name = figid) %>% dplyr::select(figid,name) #TERM2NAME
pfocr2name<-unique(pfocr2name)

pfocr2genePlus <- rbind(pfocr2gene, setNames(wpid2gene, names(pfocr2gene)))
pfocr2namePlus <- rbind(pfocr2name, setNames(wpid2name, names(pfocr2name)))

# Apply to each term in GMT  
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
    TERM2GENE = pfocr2genePlus,
    TERM2NAME = pfocr2namePlus)
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

## Filter for just the PFOCR results
gmt.pfocr.overlaps <- gmt.pfocr.overlaps %>%
  filter(substr(figid, 1, 3) == "PMC")

## Flatten and save
gmt.pfocr.overlaps <- gmt.pfocr.overlaps %>%
  rowwise() %>%
  dplyr::mutate(genes = paste(unlist(genes), collapse = ", "))

#write.table(gmt.pfocr.overlaps, "raw/gmt-pfocr-overlaps.tsv", quote=F, sep="\t", row.names = F)
gmt.pfocr.overlaps <- read.table("raw/gmt-pfocr-overlaps.tsv", header=T, sep="\t", stringsAsFactors = F)

disease.pfocr.cnt <- unique(gmt.pfocr.overlaps$ont)

disease.genes.pfocr <- gmt.pfocr.overlaps %>%
  arrange(desc(pf.overlap.cnt))

disease.genes.targets <- disease.genes.pfocr %>%
  left_join(gmt.wp.overlaps[,c(1,4:7)], by=c("ont")) %>%
  mutate_if(is.numeric, replace_na, replace = 0) %>%
  rowwise() %>%
  dplyr::mutate(wpg = stringr::str_split(overlap.genes, ", "),
         ppg = stringr::str_split(pf.overlap.genes, ", ")) %>%
  dplyr::mutate(overlap.pct = overlap.cnt / cnt,
         # pf.diff.cnt = pf.cnt - wp.cnt,
         #pf.diff.overlap.cnt = pf.overlap.cnt - overlap.cnt ,
         pdog = list(dplyr::setdiff(unlist(ppg), unlist(wpg))),
         pf.diff.overlap.cnt = length(pdog),
         pf.diff.overlap.genes = paste(pdog, collapse = ", ")
  ) %>%
  dplyr::select (-c(wpg, ppg, pdog)) %>%
  dplyr::filter (pf.diff.overlap.cnt > 0) %>%
  arrange(wp.cnt, ont, desc(pf.diff.overlap.cnt), desc(pf.overlap.cnt))

#write.table(disease.genes.targets, "tables/disease-genes-targets.tsv", quote=F, sep="\t", row.names = F)
disease.genes.targets <- read.table("tables/disease-genes-targets.tsv", header=T, sep="\t", stringsAsFactors = F)
