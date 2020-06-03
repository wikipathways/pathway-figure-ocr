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

## Process Jensen disease file to gmt and save
# jensen_know <- read.csv("raw/human_disease_knowledge_filtered.tsv", sep="\t", stringsAsFactors = F)[ ,c(2,4)]
# colnames(jensen_know) <- c("symbol", "disease")
# jensen_know2 <- jensen_know %>%
#   dplyr::group_by(disease) %>%
#   dplyr::filter(n() > 7) %>%
#   dplyr::summarise(symbol_all = paste(symbol,collapse="\t"))
# write.table(jensen_know2, file = "raw/jensen_know.gmt", append = FALSE, quote = FALSE, sep = "\t",
#            na = "NA", dec = ".", row.names = FALSE,
#             col.names = FALSE)


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

## also make TERM2GENE object
jensen2gene <- gmt 

## Prepare list of gene sets from GO_BP GMT (downloaded from Enrichr)
gmt.file <- "raw/go_bp.gmt"
gmt <- clusterProfiler::read.gmt(gmt.file)
gmt.entrez <- bitr(gmt$gene,fromType = "SYMBOL",toType = "ENTREZID",OrgDb = org.Hs.eg.db)
gmt <-gmt %>%
  dplyr::left_join(gmt.entrez, by=c("gene" = "SYMBOL")) %>%
  dplyr::filter(!is.na(ENTREZID)) %>%
  dplyr::select(term, ENTREZID)

## also make TERM2GENE object
gobp2gene <- gmt 

####################
## Prepare PFOCR GMT
####################

## Prepare GMT of PFOCR results to serve as enrichment database
pfocr.genes <- readRDS("pfocr_genes.rds") %>%
  dplyr::select(figid, symbol, source, entrez)

# Get counts of nobe genes in order to subset:
# First collapse bioentity cases per figure and word,...
pfocr.nobe <- pfocr.genes %>% 
  dplyr::select(-entrez) %>% 
  dplyr::group_by(figid, symbol, source) %>%
  dplyr::summarise(entrez_count = n()) 
# ... then count entrez per figure.
pfocr.nobecnt <- pfocr.nobe %>% 
  dplyr::select(-c(source, -symbol)) %>% 
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

## Also make gene list
pfocr.lists <- pfocr.genes.sub %>% group_by(figid) %>%
  dplyr::summarize(cnt = n(),
                   genes = list(entrez))
pfocr.all.genes <- unique(as.character(pfocr.genes.sub$entrez))

#####################
## Perform Enrichment
#####################
### gene sets against PFOCR

# Apply to each gene set in list  
gmt.pfocr.overlaps <- plyr::ldply(gmt.lists$term, function(t){
  
  gmt.term.genes <- gmt %>%
    dplyr::filter(term == t) %>%
    dplyr::select(ENTREZID)
  
  ## PFOCR Analysis
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
        mutate (term = t,
                cnt = gmt.lists$cnt[which(gmt.lists$term == t)],
                genes = paste(unlist(gmt.lists$genes[which(gmt.lists$term == t)]), collapse = ", "),
                figid = ID,
                pf.overlap.cnt = Count,
                pf.overlap.genes = str_replace_all(geneID, "/",", ")
        ) %>%
        dplyr::select(term, cnt, genes, figid, pf.overlap.cnt, pf.overlap.genes)
    }
  }
})

#write.table(gmt.pfocr.overlaps, "raw/gmt-pfocr-jensen_know7-overlaps_7.tsv", quote=F, sep="\t", row.names = F)
#gmt.pfocr.overlaps <- read.table("raw/gmt-pfocr-jensen_know7-overlaps_7.tsv", header=T, sep="\t", stringsAsFactors = F)

## Basic counts
sprintf("Unique figures with hits: %i",length(unique(gmt.pfocr.overlaps$figid)))
gmt.pfocr.overlaps.genes <- gmt.pfocr.overlaps %>% 
  dplyr::select(1,6) %>% 
  mutate(genes = strsplit(pf.overlap.genes, ",", fixed = T)) %>% 
  unnest(genes) %>% 
  dplyr::select(c(1,3))
sprintf("Unique overlapping genes: %i",length(unique(gmt.pfocr.overlaps.genes$genes)))
sprintf("Unique enriched terms: %i",length(unique(gmt.pfocr.overlaps$term)))


## nobe7-jensenknow7:
# 23,331/28,236 figures with hits (83%)
# 2378/2913 disease genes
# 151/160 disease terms

## nobe7-omim:
# 15,957/28,236 figures with hits (57%)
# 880/1526 disease genes
# 78/90 disease terms

## nobe10-omim:
# 11,874/18,917 figures with hits (63%)
# 838/1526 disease genes 
# 78/90 disease terms


## COUNTS
# with 2+ hits
twocnt.df <- filter(gmt.pfocr.overlaps, pf.overlap.cnt >= 2)
total.figids <- length(unique(twocnt.df$figid))
sprintf("Unique figures with hits: %i",total.figids)

total.terms <- length(unique(twocnt.df$term))
sprintf("Unique enriched go terms: %i",total.terms)

ont.terms <- twocnt.df %>% dplyr::group_by(term) %>% dplyr::summarise(count=n())
sprintf("Average pathway hits per term: %f",mean(ont.terms$count))

figs <- twocnt.df %>% dplyr::group_by(figid) %>% dplyr::summarise(count=n())
sprintf("Average terms per pathway figure: %f",mean(figs$count))


#########################
## TOP TEN DISEASE
# with exclusion to reduce redundancy
# with 2+ hits
#########################

for(i in 1:10){
  dis <- twocnt.df %>% dplyr::group_by(term) %>% dplyr::summarise(count=n())
  dis.arr <- arrange(dis, desc(count))
  top.term <- dis.arr$term[1]
  top.term.figids <- dis.arr$count[1]
  print(sprintf("#%i. %s %i (%f)",i, top.term, top.term.figids, top.term.figids/total.figids))
  rm.figs <- twocnt.df %>% filter(term == top.term)
  twocnt.df <- twocnt.df %>% filter(!figid %in% rm.figs$figid)
}

other.figids <- length(unique(twocnt.df$figid))
sprintf("#%i. %s %i (%f)",11, "Other", other.figids, other.figids/total.figids)

# know7_pfocr7_cnt2:
#
# [1] "#1. Cancer 9700 (0.469075)"
# [1] "#2. Juvenile rheumatoid arthritis 1742 (0.084240)"
# [1] "#3. Ovarian cancer 1368 (0.066154)"
# [1] "#4. Primary hyperaldosteronism 935 (0.045215)"
# [1] "#5. Aortic aneurysm 710 (0.034334)"
# [1] "#6. Alopecia areata 684 (0.033077)"
# [1] "#7. Primary cutaneous amyloidosis 525 (0.025388)"
# [1] "#8. Melanoma 495 (0.023937)"
# [1] "#9. Alzheimer's disease 444 (0.021471)"
# [1] "#10. Rheumatoid arthritis 432 (0.020891)"
# [1] "#11. Other 3644 (0.176217)"

#########################
## Annotate PFOCR figures
#########################
# pfocr.figs <- readRDS("pfocr_figures.rds") %>%
#   dplyr::select(figid)

## Aggregate with prior results
pfocr.figs <- read.table("tables/enriched_annots.tsv", header=T, sep="\t", stringsAsFactors = F)

### CAUTION: change name to be used in this chunk to reflect current analysis
set.name <- "jensenknow7"

gmt.pfocr.overlaps.tidy <- gmt.pfocr.overlaps %>%
  dplyr::mutate(!!set.name := ont) %>%
  dplyr::select(figid, !!as.name(set.name)) %>%
  dplyr::group_by(figid) %>%
  dplyr::summarise(!!paste(set.name, "list", sep = "_") := paste(unique(!!as.name(set.name)), collapse=" | "),
                   !!paste(set.name, "cnt", sep = "_") := n()) 

enriched.annots <- merge(gmt.pfocr.overlaps.tidy, 
                         pfocr.figs, 
                         by = "figid", 
                         all.y = TRUE)

write.table(enriched.annots, "tables/enriched_annots.tsv", quote=T, sep="\t", row.names = F)

#########################
## PFOCR against JENSEN KNOW_7
#########################

# Apply to each gene set in list  
pfocr.ont.overlaps <- plyr::ldply(pfocr.lists$figid, function(f){
  
  pfocr.figid.genes <- pfocr.genes.sub %>%
    dplyr::filter(figid == f) %>%
    dplyr::select(entrez)
  
  ## PFOCR Analysis
  ewp <- clusterProfiler::enricher(
    gene = pfocr.figid.genes$entrez,
    universe = pfocr.all.genes,
    pAdjustMethod = "fdr",
    pvalueCutoff = 0.05, #p.adjust cutoff
    minGSSize = 2,
    maxGSSize = 500,
    TERM2GENE = jensen2gene)
  #ewp <- DOSE::setReadable(ewp, org.Hs.eg.db, keyType = "ENTREZID")
  #head(ewp, 20)
  
  ## stash results
  if (!is.null(ewp)){
    res <- ewp@result %>%
      dplyr::filter(p.adjust < 0.05)
    if (nrow(res) > 0){
      res <- res %>%
        mutate (figid = f,
                cnt = pfocr.lists$cnt[which(pfocr.lists$figid == f)],
                genes = paste(unlist(pfocr.lists$genes[which(pfocr.lists$figid == f)]), collapse = ", "),
                term = ID,
                pf.overlap.cnt = Count,
                pf.overlap.genes = str_replace_all(geneID, "/",", ")
        ) %>%
        dplyr::select(figid, cnt, genes, term, pf.overlap.cnt, pf.overlap.genes)
    }
  }
})

#write.table(pfocr.ont.overlaps, "raw/gmt-jensen_know7-pfocr-overlaps_7.tsv", quote=F, sep="\t", row.names = F)
#gmt.pfocr.overlaps <- read.table("raw/gmt-jensen_know7-pfocr-overlaps_7.tsv", header=T, sep="\t", stringsAsFactors = F)

## COUNTS
# with 2+ hits
twocnt.df <- filter(pfocr.ont.overlaps, pf.overlap.cnt >= 2)
total.figids <- length(unique(twocnt.df$figid))
sprintf("Unique figures with hits: %i",total.figids)

total.terms <- length(unique(twocnt.df$term))
sprintf("Unique enriched go terms: %i",total.terms)

ont.terms <- twocnt.df %>% dplyr::group_by(term) %>% dplyr::summarise(count=n())
sprintf("Average pathway hits per term: %f",mean(ont.terms$count))

figs <- twocnt.df %>% dplyr::group_by(figid) %>% dplyr::summarise(count=n())
sprintf("Average terms per pathway figure: %f",mean(figs$count))

#########################
## TOP TEN DISEASE
# with exclusion to reduce redundancy
# with 2+ hits
#########################

for(i in 1:10){
  dis <- twocnt.df %>% dplyr::group_by(term) %>% dplyr::summarise(count=n())
  dis.arr <- arrange(dis, desc(count))
  top.term <- dis.arr$term[1]
  top.term.figids <- dis.arr$count[1]
  print(sprintf("#%i. %s %i (%f)",i, top.term, top.term.figids, top.term.figids/total.figids))
  rm.figs <- twocnt.df %>% filter(term == top.term)
  twocnt.df <- twocnt.df %>% filter(!figid %in% rm.figs$figid)
}

other.figids <- length(unique(temp.df$figid))
sprintf("#%i. %s %i (%f)",11, "Other", other.figids, other.figids/total.figids)

# [1] "#1. Cancer 8429 (0.416720)"
# [1] "#2. Juvenile rheumatoid arthritis 1568 (0.077520)"
# [1] "#3. Ovarian cancer 1384 (0.068423)"
# [1] "#4. DOID:12252 1020 (0.050428)"
# [1] "#5. Aortic aneurysm 710 (0.035102)"
# [1] "#6. Alopecia areata 632 (0.031245)"
# [1] "#7. Primary cutaneous amyloidosis 552 (0.027290)"
# [1] "#8. Melanoma 461 (0.022791)"
# [1] "#9. Alzheimer's disease 434 (0.021456)"
# [1] "#10. Rheumatoid arthritis 428 (0.021160)"
# [1] "#11. Other 4609 (0.227864)"

#########################
## PFOCR against GO:BP
#########################

# Apply to each gene set in list  
pfocr.gobp.overlaps <- plyr::ldply(pfocr.lists$figid, function(f){
  
  pfocr.figid.genes <- pfocr.genes.sub %>%
    dplyr::filter(figid == f) %>%
    dplyr::select(entrez)
  
  ## PFOCR Analysis
  ewp <- clusterProfiler::enricher(
    gene = pfocr.figid.genes$entrez,
    universe = pfocr.all.genes,
    pAdjustMethod = "fdr",
    pvalueCutoff = 0.05, #p.adjust cutoff
    minGSSize = 2,
    maxGSSize = 500,
    TERM2GENE = gobp2gene)
  #ewp <- DOSE::setReadable(ewp, org.Hs.eg.db, keyType = "ENTREZID")
  #head(ewp, 20)
  
  ## stash results
  if (!is.null(ewp)){
    res <- ewp@result %>%
      dplyr::filter(p.adjust < 0.05)
    if (nrow(res) > 0){
      res <- res %>%
        mutate (figid = f,
                cnt = pfocr.lists$cnt[which(pfocr.lists$figid == f)],
                genes = paste(unlist(pfocr.lists$genes[which(pfocr.lists$figid == f)]), collapse = ", "),
                term = ID,
                pf.overlap.cnt = Count,
                pf.overlap.genes = str_replace_all(geneID, "/",", ")
        ) %>%
        dplyr::select(figid, cnt, genes, term, pf.overlap.cnt, pf.overlap.genes)
    }
  }
})

#write.table(pfocr.gobp.overlaps, "raw/gmt-gobp-pfocr-overlaps_7.tsv", quote=F, sep="\t", row.names = F)
#pfocr.gobp.overlaps <- read.table("raw/gmt-jgobp-pfocr-overlaps_7.tsv", header=T, sep="\t", stringsAsFactors = F)

## COUNTS
# with 2+ hits
twocnt.df <- filter(pfocr.gobp.overlaps, pf.overlap.cnt >= 2)
total.figids <- length(unique(twocnt.df$figid))
sprintf("Unique figures with hits: %i",total.figids)

total.terms <- length(unique(twocnt.df$term))
sprintf("Unique enriched go terms: %i",total.terms)

ont.terms <- twocnt.df %>% dplyr::group_by(term) %>% dplyr::summarise(count=n())
sprintf("Average pathway hits per term: %f",mean(ont.terms$count))

figs <- twocnt.df %>% dplyr::group_by(figid) %>% dplyr::summarise(count=n())
sprintf("Average terms per pathway figure: %f",mean(figs$count))

#########################
## TOP TEN GO TERMS
# with exclusion to reduce redundancy
# with 2+ hits
#########################

for(i in 1:10){
  dis <- twocnt.df %>% dplyr::group_by(term) %>% dplyr::summarise(count=n())
  dis.arr <- arrange(dis, desc(count))
  top.term <- dis.arr$term[1]
  top.term.figids <- dis.arr$count[1]
  print(sprintf("#%i. %s %i (%f)",i, top.term, top.term.figids, top.term.figids/total.figids))
  rm.figs <- twocnt.df %>% filter(term == top.term)
  twocnt.df <- twocnt.df %>% filter(!figid %in% rm.figs$figid)
}

other.figids <- length(unique(twocnt.df$figid))
sprintf("#%i. %s %i (%f)",11, "Other", other.figids, other.figids/total.figids)

# [1] "#1. positive regulation of macromolecule metabolic process (GO:0010604) 17166 (0.601893)"
# [1] "#2. cellular response to cytokine stimulus (GO:0071345) 2849 (0.099895)"
# [1] "#3. protein phosphorylation (GO:0006468) 1739 (0.060975)"
# [1] "#4. cellular response to organic cyclic compound (GO:0071407) 762 (0.026718)"
# [1] "#5. monocarboxylic acid metabolic process (GO:0032787) 656 (0.023001)"
# [1] "#6. positive regulation of nucleic acid-templated transcription (GO:1903508) 626 (0.021950)"
# [1] "#7. cellular response to DNA damage stimulus (GO:0006974) 459 (0.016094)"
# [1] "#8. organonitrogen compound biosynthetic process (GO:1901566) 279 (0.009783)"
# [1] "#9. positive regulation of intracellular signal transduction (GO:1902533) 264 (0.009257)"
# [1] "#10. phosphate-containing compound metabolic process (GO:0006796) 250 (0.008766)"
# [1] "#11. Other 3470 (0.121669)"