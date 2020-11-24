## Annotation of WikiPathways using enrichment of JENSEN Disease terms.
## Adapted from pfocr-gmt-enrich.R, the method used to annotate PFOCR.


## Set to your own local working directory
setwd("~/Dropbox (Gladstone)/PFOCR_25Years") #AP

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

## Prepare list of gene sets from JENSEN GMTs 
gmt.file <- "raw/jensen_know.gmt"
gmt <- clusterProfiler::read.gmt(gmt.file)
gmt.entrez <- bitr(gmt$gene,fromType = "SYMBOL",toType = "ENTREZID",OrgDb = org.Hs.eg.db)
gmt <-gmt %>%
  dplyr::left_join(gmt.entrez, by=c("gene" = "SYMBOL")) %>%
  dplyr::filter(!is.na(ENTREZID)) %>%
  dplyr::select(term, ENTREZID)
gmt.lists <- gmt %>% group_by(term) %>%
  dplyr::summarize(cnt = n(),
                   genes = list(ENTREZID))
gmt.all.genes <- unique(gmt$ENTREZID)

## Prepare WP gmt
#wp.hs.gmt <- rWikiPathways::downloadPathwayArchive(organism="Homo sapiens", format = "gmt")
wp.hs.gmt <-"wikipathways-20200810-gmt-Homo_sapiens.gmt"
wp2gene <- clusterProfiler::read.gmt(wp.hs.gmt)
wp2gene <- wp2gene %>% tidyr::separate(term, c("name","version","wpid","org"), "%")
wpid2gene <- wp2gene %>% dplyr::select(wpid,gene) #TERM2GENE
wpid2name <- wp2gene %>% dplyr::select(wpid,name) #TERM2NAME
wpid2name<-unique(wpid2name)

#####################
## Perform Enrichment
#####################
### JESEN DISEASE gene sets against WP

# Apply to each gene set in list  
gmt.wp.overlaps <- plyr::ldply(gmt.lists$term, function(t){
  
  gmt.term.genes <- gmt %>%
    dplyr::filter(term == t) %>%
    dplyr::select(ENTREZID)
  
  ## wp Analysis
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
    if (nrow(res) > 0){
      res <- res %>%
        mutate (term = t,
                cnt = gmt.lists$cnt[which(gmt.lists$term == t)],
                genes = paste(unlist(gmt.lists$genes[which(gmt.lists$term == t)]), collapse = ", "),
                wpid = ID,
                wp.overlap.cnt = Count,
                wp.overlap.genes = str_replace_all(geneID, "/",", ")
        ) %>%
        dplyr::select(term, cnt, genes, wpid, wp.overlap.cnt, wp.overlap.genes)
    }
  }
})

# saveRDS(gmt.wp.overlaps, "raw/gmt-wp-overlaps.RDS")
# gmt.wp.overlaps <- readRDS("raw/gmt-wp-overlaps.RDS")

## Basic counts
sprintf("Unique pathways with hits: %i",length(unique(gmt.wp.overlaps$wpid)))
gmt.wp.overlaps.genes <- gmt.wp.overlaps %>% 
  dplyr::select(1,6) %>% 
  mutate(genes = strsplit(wp.overlap.genes, ",", fixed = T)) %>% 
  unnest(genes) %>% 
  dplyr::select(c(1,3))
sprintf("Unique overlapping genes: %i",length(unique(gmt.wp.overlaps.genes$genes)))
sprintf("Unique enriched disease terms: %i",length(unique(gmt.wp.overlaps$term)))

# Unique pathways with hits: 444/624 pathways (71%)
# Unique overlapping genes: 1421/2913 disease genes
# Unique enriched disease terms: 142/160 disease terms

## Filter for n+ hits
gmt.wp.overlaps.5 <- filter(gmt.wp.overlaps, wp.overlap.cnt >= 5)

## Filter for curated terms: 58 confirmed disease annotations with good pathway hits
cur.wp.terms <- readRDS("raw/cur-wp-terms.RDS")
gmt.wp.overlaps.5 <- gmt.wp.overlaps.5 %>%
  filter(term %in% cur.wp.terms$term)

## COUNTS
total.wpids <- length(unique(gmt.wp.overlaps.5$wpid))
sprintf("Unique pathways with n+ hits: %i/%i (%.0f%%)",
        total.wpids,
        nrow(wpid2name),
        total.wpids/nrow(wpid2name)*100)

total.terms <- length(unique(gmt.wp.overlaps.5$term))
sprintf("Unique enriched disease terms: %i/%i (%.0f%%)",
        total.terms,
        nrow(gmt.lists),
        total.terms/nrow(gmt.lists)*100)

ont.terms <- gmt.wp.overlaps.5 %>% dplyr::group_by(term) %>% dplyr::summarise(count=n())
sprintf("Average pathway hits per term: %f",mean(ont.terms$count))

pathways <- gmt.wp.overlaps.5 %>% dplyr::group_by(wpid) %>% dplyr::summarise(count=n())
sprintf("Average disease terms per pathway figure: %f",mean(pathways$count))

#n=5 curated
# [1] "Unique pathways with n+ hits: 194/624 (31%)"
# [1] "Unique enriched disease terms: 56/160 (35%)"
# [1] "Average pathway hits per term: 5.428571"
# [1] "Average disease terms per pathway: 1.567010"

#########################
## TOP TEN DISEASE
# with exclusion to reduce redundancy
# with n+ hits
#########################

gmt.wp.temp <- gmt.wp.overlaps.5
for(i in 1:10){
  dis <- gmt.wp.temp %>% dplyr::group_by(term) %>% dplyr::summarise(count=n())
  dis.arr <- arrange(dis, desc(count))
  top.term <- dis.arr$term[1]
  top.term.wpids <- dis.arr$count[1]
  print(sprintf("#%i. %s %i (%f)",i, top.term, top.term.wpids, top.term.wpids/total.wpids))
  rm.pathways <- gmt.wp.temp %>% filter(term == top.term)
  gmt.wp.temp <- gmt.wp.temp %>% filter(!wpid %in% rm.pathways$wpid)
}

other.wpids <- length(unique(gmt.wp.temp$wpid))
sprintf("#%i. %s %i (%f)",11, "Other", other.wpids, other.wpids/total.wpids)

# know7_wp_cnt5_cur:
# [1] "#1. Cancer 129 (0.664948)"
# [1] "#2. Intellectual disability 10 (0.051546)"
# [1] "#3. Cardiomyopathy 7 (0.036082)"
# [1] "#4. Leigh disease 6 (0.030928)"
# [1] "#5. Neurodegenerative disease 6 (0.030928)"
# [1] "#6. Rheumatoid arthritis 5 (0.025773)"
# [1] "#7. Epilepsy 3 (0.015464)"
# [1] "#8. Age related macular degeneration 2 (0.010309)"
# [1] "#9. Asphyxiating thoracic dystrophy 2 (0.010309)"
# [1] "#10. Glycogen storage disease 2 (0.010309)"
# [1] "#11. Other 22 (0.113402)"





