# characterize - characterize results of pfocr and image classifaction

library(magrittr)
library(dplyr)
library(ggplot2)
library(reshape2)

## LOCAL INFO PER USER
setwd("~/Dropbox (Gladstone)/Pathway Figure OCR/20200224_65k") #AP
setwd("/git/wikipathways/pathway-figure-ocr/20200131") #AP
setwd("~/Dropbox (Gladstone)/PFOCR_25Years") #AP

## data on all 235k
df.all.235k <- readRDS("df.all.235k.final.rds")
df.auto.235k <- read.csv("automl_single_po_235k_10k.csv", header = T, stringsAsFactors = F)

## Merge columns for common rows
df.all.auto.235k <- merge(df.all.235k[,c(1,4,9,10)], df.auto.235k, by = "figid")

## Clean up
df.all.auto.235k <- df.all.auto.235k %>%
  dplyr::select(-c("other_score"))

## Read in manually screened images: p,c,o
### repeat per file:
df.p <- as.data.frame(readRDS("pfocr_pathway.rds")) 
#df.man <- setNames(df.p[,c(1,10)], c("figid", "type.man")) #first time only
#df.man <- unique(rbind(df.man,setNames(df.p[,c(1,10)], c("figid", "type.man")))) #old format
df.man <- unique(rbind(df.man,df.p[,c(1,5)]))
#df.man <- unique(rbind(df.man,data.frame(figid="PMC6355902__42003_2019_280_Fig2_HTML.jpg", type.man="composite")))

### check and save when done
df.man %>%
  filter(type.man == "composite") %>%
  count()

# clean up
df.man %>% 
  group_by(figid) %>%
  count(cnt=n()) %>%
  arrange(desc(cnt))

df.man %>% filter(figid == "PMC6355902__42003_2019_280_Fig2_HTML.jpg") %>%
  select(type.man)

df.man <- df.man %>%
  filter(!(figid == "PMC6355902__42003_2019_280_Fig2_HTML.jpg" & type.man =="other"))


saveRDS(df.man, "manual_11k.rds")
#df.man<-readRDS("manual_11k.rds")

## Annotate 235k with manually curated types
df.all.man.235k <- merge(df.all.auto.235k, df.man, by = "figid", all.x=T)

# # clean up
# df.all.man.235k %>% 
#   group_by(figid) %>%
#   count(cnt=n()) %>%
#   arrange(desc(cnt))
# 
# df.all.man.235k.clean %>%
#   filter(figid == "PMC1578487__biophysj00087098F03_LW.jpg")
# 
# df.all.man.235k.clean <- df.all.man.235k.clean %>%
#   filter(!(figid == "PMC1578487__biophysj00087098F03_LW.jpg" & type.man =="other"))
# 
# df.all.man.235k.clean <- mutate(df.all.man.235k.clean, type.man = ifelse(figid == "PMC1929113__1471-2407-7-109-3.jpg", "other", type.man))
# 
# 
## add indexes
df.all.man.235k <- df.all.man.235k %>%
  arrange(desc(as.numeric(pathway_score_old))) %>%
 # select(-automl_index) %>%
  tibble::rowid_to_column("automl_index_old")

## reorder
df.all.man.235k <- df.all.man.235k %>%
   select(-automl_index_old, automl_index_old)

saveRDS(droplevels(as.data.frame(df.all.man.235k)), "pfocr.man.235k_10k.rds")
#df.all.man.235k <- readRDS("pfocr.man.235k_10k.rds")


df.all.man.235k <- df.all.man.235k %>%
  mutate(pathway_score_diff = pathway_score - pathway_score_old) %>%
  arrange(desc(as.numeric(pathway_score_diff)))
  
  
## Save slices for further manual screening
df.all.man.235k %>%  
  dplyr::filter(pathway_score >= .9 & 
                  pathway_score < 1.0) %>%
  count()

df.all.man.235k3 %>%  
  dplyr::filter(pathway_score >= 0.4  & 
                  #pathway_score < 0.9 &
                  (is.na(type.man) |
                  type.man == "pathway")) %>%
  count()

# 0.0: p0 c0 o18 na2508 (sample 300: p0 c1 o299 p0% o100%) automl_index233817
# .02-.03: p2 c6 o33 na3449 (sample 300: p10 c39 o251 p3% o84%) automl_index97966               
# .15-.25: p5 c10 o30 na4394 (sample 300: 51p c49 o200 p17% o67%) automl_index80938
# .3-.4: p5 c6 o26 [1:1:5] na3203 (sample 300: p82 c45 o173 p27% o58%) automl_index75294
# .4-.5: p573 c173 o153 [3.5:1:1] na2207 => p1246 c397 o1463 p40% o47% automl_index72120
# .6-.7: p222 c30 o33 [7:1:1] na3394 (sample 300: p161 c26 o113 p54% o38%) automl_index65462
# .7-.8: p34 c5 o15 [7:1:3] na4709 (sample 300: p193 c32 o75 p%64 o25%) automl_index61241
# .8-.9: p100 c5 o17 [20:1:3] na7584 (sample 300: p218 c12 o70 p73% o23%) automl_index55006
# .94-.96: p67 c1 o8 [67:1:8] na4016 (sample 300: p255 c8 o37 p85% o12%) automl_index43661
# .98-.986: p75 c0 o0 na3364 (sample 300: p271 c5 o24 p90% o8%) automl_index32809                        
# .996-.998: p88 c0 o3 na4649 (sample 300: p285 c3 o12 p95% o4%) automl_index18172                           
# 1.0: p82 c0 o0 [1:0:0] na3942 (sample 300: p300 c0 o0 p100% o0%) automl_index2012

## estimate "lost" pathways from 0 to 0.5:  ~6030 pathway figures (less than 10%)
lost.p <-
  .4 * 3106 +
  .27 * 3240 +  # 875 (27%)
  .25 * 1805 + (.3-.25) * 1805 /2 +  #496 (27%)
  .17 * 4439 +  # 755 (17%)
  .03 * 13064 + (.15-.03)* 13064 /2 + #1175 (9%)
  .03 * 4439 +  # 133 (3%)
  0 * 135369 +  (.02 -0) * 135369 /2 # 1354 (1%)

total.p <-  #79,271 = 33.7% of 235,080
  lost.p +
  (.4 + .54)/2 * 3266 +
  .54 * 3679 +
  .64 * 4763 +
  .73 * 7706 +
  (.73 + .85)/2 * 13152 +
  .85 * 4092 +
  (.85 + .9)/2 * 16625 +
  .9 * 3439 +
  (1 + .9)/2 * 31089


df.all.man.235k %>%  
  dplyr::filter(pathway_score >= 0.996 & 
                  pathway_score < 0.998) %>%
  summarise(median(automl_index))

plot.automl.check.actual <-data.frame(x=c(1, 18172, 32809, 43661,55006,61241, 65462, 72120, 75294, 80938, 97966, 235080), 
                               y=c(1, .95, .903, .85, .73, .64, .54, .40, .27, .17, .03, 0))
plot.automl.check.position <-data.frame(x=c(1, 18172, 32809, 43661,55006,61241, 65462, 72120, 75294, 80938, 97966, 235080), 
                               y=c(1, .997, .983, .95, .85, .75, .65, .45, .35, .2, .025, 0))
plot.pmc.check.position <-data.frame(x=c(1, 100000, 235080), 
                                        y=c(.663, .35, .10))

#############################
### FIGURE FOR 25 YEARS PAPER
#############################
## PMC and AutoML plots

# Fit curves for max slopes, mid points and accuracy

## PMC
fit.pmc <- lm(y ~ x, data = plot.pmc.check.position)
coef.pmc <- coefficients(fit.pmc)
mid.pmc <- round(tail(plot.pmc.check.position$x, 1)/2)
acc.beg.pmc <- coef.pmc["(Intercept)"]
acc.mid.pmc <- mid.pmc * coef.pmc["x"] + acc.beg.pmc
acc.ave.pmc <- mean(c(acc.beg.pmc, acc.mid.pmc))
sprintf("Number of figures for PMC (mid-point): %i", mid.pmc) # 117,540
sprintf("Accuracy for PMC: %f", acc.ave.pmc)                  # 49.6%
#sprintf("Max slope for PMC: %s", (coef.pmc["x"]))             # -2.4e-06

## Round 1
library(pracma)
fit.r1 <- nls(as.numeric(pathway_score_old) ~ SSlogis(automl_index_old, Asym, xmid, scal), data = df.all.man.235k)
coef.r1 <- coefficients(fit.r1)
mid.r1 <- round(coef.r1["xmid"])
sprintf("Number of figures for R1 (mid-point): %i", mid.r1) # 70,271
df.sort <- arrange(df.all.man.235k, automl_index_old)
auc.r1 = trapz(df.sort$automl_index_old[1:mid.r1],df.sort$pathway_score_old[1:mid.r1])
sprintf("Predicted accuracy for R1: %f", auc.r1/mid.r1)        # 91.6%
auc.r1a = trapz(plot.automl.check.actual$x[1:8],plot.automl.check.actual$y[1:8])
sprintf("Sampled accuracy for R1: %f", auc.r1a/mid.r1)        # 84.8%
fit.r1s <- nls(as.numeric(pathway_score_old) ~ SSlogis(automl_index_old, Asym, xmid, scal), data = filter(df.all.man.235k,
                                                                                                          automl_index_old >25000 &
                                                                                                            automl_index_old < 110000))
coef.r1s <- coefficients(fit.r1s)
mid.r1s <- round(coef.r1s["xmid"])

#sprintf("Max slope for R1: %i", round(coef.r1["scal"]))                  

## Round 2
# fit.r2 <- nls(as.numeric(pathway_score) ~ SSlogis(automl_index, Asym, xmid, scal), data = df.all.man.235k)
# coef.r2 <- coefficients(fit.r2)
# mid.r2 <- round(coef.r2["xmid"])
sprintf("Number of figures for R2 (mid-point): %i", 64,679) # 64,679
df.sort <- arrange(df.all.man.235k, automl_index)
auc.r2 = trapz(df.sort$automl_index[1:64679],df.sort$pathway_score[1:64679])
sprintf("Predicted accuracy for R2: %f", auc.r2/64679)                                 # 87.5%
sprintf("Sampled accuracy for R2: %f", 0.94)                                 # 94%
# data.sub <- df.sort[seq(25000, 110000, 200),]
# x <- data.sub$automl_index
# y <- data.sub$pathway_score
# fit.r2s <- nls(y ~ SSlogis(x, Asym, b2, b3), data = data.sub)
# coef.r2s <- coefficients(fit.r2s)
# b2<- coef.r2s['b2']
# b3<- coef.r2s['b3']
# list2env(as.list(coef(coef.r2s)), .GlobalEnv)
# dGomp <- deriv((y ~ Asym*exp(-b2*b3^x)), "x", func=T)
# dGomp(2)

#sprintf("Max slope for R2: %i", round(coef.r2["scal"]))                    

## Table data

df.ml <- data.frame(Method=c("PMC","ML#1","ML#2","Final"), 
                    Figures=c(117540,70271,64679,64643), 
                    Predicted=c(NA,92,88,NA), 
                    Accuracy=c(50,85,93,94))


library(scales)
library(ggpubr)

p1 <- ggplot(data=plot.pmc.check.position, 
             aes(x = x, y = y)) +
  geom_line(color = "black", linetype = 3) +
  geom_point(aes(x =  x, y = y), size=2) +
  geom_vline(aes(xintercept=mid.pmc), color="red", linetype = 1) +
  ggtitle("A. PMC Query Results") +
  xlab("") +
  ylab("Pathway Likelihood") 


p1 <- p1 + theme(
  axis.title.x = element_text(size=12),
  axis.title.y = element_text(size=12),
  axis.text.x = element_text(size=10),
  axis.text.y = element_text(size=10)
) + 
  scale_x_continuous(breaks=c(0, 50000, 100000, 150000, 200000),
                     expand = expansion(mult=c(0.01,0.01)) ) +
  scale_y_continuous(breaks=c(0, 0.25, 0.5, 0.75, 1.0), 
                     expand = expansion(mult=c(0.015,0.015)),
                     limits = c(0,1.0),
                     labels = percent) 
p1

p2 <-  ggplot(df.all.man.235k, 
              aes(x = automl_index_old, y = as.numeric(pathway_score_old))) +
  geom_line(color = "black") +
  geom_point(data=plot.automl.check.actual, 
             aes(x = x, y = y), size = 2) +
  geom_line(data=plot.automl.check.actual, 
             aes(x = x, y = y), linetype = 3) +
  geom_vline(aes(xintercept=mid.r1), color="red", 
             linetype = 1) +
  ggtitle("B. ML Round 1") +
  xlab("") +
  ylab("Pathway Likelihood") 

p2 <- p2 + theme(
  axis.title.x = element_text(size=12),
  axis.title.y = element_text(size=12),
  axis.text.x = element_text(size=10),
  axis.text.y = element_text(size=10)
) + 
  scale_x_continuous(breaks=c(0, 50000, 100000, 150000, 200000),
                     expand = expansion(mult=c(0.01,0.01)) ) +
  scale_y_continuous(breaks=c(0, 0.25, 0.5, 0.75, 1.0), 
                     expand = expansion(mult=c(0.015,0.015)),
                     limits = c(0,1.0),
                     labels = percent) 
p2

p3 <- ggplot(df.all.man.235k, 
             aes(x = automl_index, y = as.numeric(pathway_score))) +
  geom_line(color = "black") +
  geom_vline(aes(xintercept=64679), color="red", linetype = 1) +
  ggtitle("C. ML Round 2") +
  xlab("Independently Sorted Figures") +
  ylab("Pathway Likelihood") 

p3 <- p3 + theme(
  axis.title.x = element_text(size=12),
  axis.title.y = element_text(size=12),
  axis.text.x = element_text(size=10),
  axis.text.y = element_text(size=10)
) + 
  scale_x_continuous(breaks=c(0, 50000, 100000, 150000, 200000),
                     expand = expansion(mult=c(0.01,0.01)) ) +
  scale_y_continuous(breaks=c(0, 0.25, 0.5, 0.75, 1.0), 
                     expand = expansion(mult=c(0.015,0.015)),
                     limits = c(0,1.0),
                     labels = percent) 
p3

ggarrange(p1, p2, p3,
          # labels = c("A. PMC Results", "B. ML Round 1", "C. ML Round 2"),
          vjust = 0,
          ncol = 1, nrow = 3)


###########################################
### Slices

df.all.man.235k.996_998 <- df.all.man.235k %>%  
  dplyr::filter(pathway_score >= 0.996 & 
                  pathway_score < 0.998 &
                  is.na(type.man)) 

saveRDS(droplevels(as.data.frame(df.all.man.235k.0_0)), "pfocr.man.235k.0_0.rds")
saveRDS(droplevels(as.data.frame(df.all.man.235k.02_03)), "pfocr.man.235k.02_03.rds")
saveRDS(droplevels(as.data.frame(df.all.man.235k.15_25)), "pfocr.man.235k.15_25.rds")
saveRDS(droplevels(as.data.frame(df.all.man.235k.3_4)), "pfocr.man.235k.3_4.rds")
saveRDS(droplevels(as.data.frame(df.all.man.235k.4_5)), "pfocr.man.235k.4_5.rds")
saveRDS(droplevels(as.data.frame(df.all.man.235k.5_6)), "pfocr.man.235k.5_6.rds")
saveRDS(droplevels(as.data.frame(df.all.man.235k.6_7)), "pfocr.man.235k.6_7.rds")
saveRDS(droplevels(as.data.frame(df.all.man.235k.7_8)), "pfocr.man.235k.7_8.rds")
saveRDS(droplevels(as.data.frame(df.all.man.235k.8_9)), "pfocr.man.235k.8_9.rds")
saveRDS(droplevels(as.data.frame(df.all.man.235k.94_96)), "pfocr.man.235k.94_96.rds")
saveRDS(droplevels(as.data.frame(df.all.man.235k.98_986)), "pfocr.man.235k.98_986.rds")
saveRDS(droplevels(as.data.frame(df.all.man.235k.996_998)), "pfocr.man.235k.996_998.rds")
saveRDS(droplevels(as.data.frame(df.all.man.235k.1_0)), "pfocr.man.235k.1_0.rds")


########### OCR #############

## Grab autoML and OCR dataframes
df.ocr.65k <- read.table("20200224_ocr_results.tsv", sep="\t", header = T, stringsAsFactors = F, quote="", comment.char = "")
df.all.man.235k <- readRDS("pfocr.man.235k_10k.rds")

## Additional manual classifications
top.other <- readRDS("images/other_65k_top300_test/pfocr_other.rds")
top.composite <- readRDS("images/composite_65k_top300_test/pfocr_composite.rds")
df.all.man.235k <- df.all.man.235k %>%
  mutate(type.man = ifelse(.$figid %in% test.figs$figid, "pathway", type.man)) %>%
  mutate(type.man = ifelse(.$figid %in% top.other$figid, "other", type.man)) %>%
  mutate(type.man = ifelse(.$figid %in% top.composite$figid, "composite", type.man))

## Merge
pfocr.ml <- merge(df.ocr.65k, df.all.man.235k, by.x="figure", by.y = "figid", all.x = T)

## Clean and shape
pfocr.ml <- dplyr::select(pfocr.ml, -c(pmcid.y, transforms_applied, automl_index_old, pathway_score_diff)) # redundant
names(pfocr.ml)[names(pfocr.ml) == 'pmcid.x'] <- 'pmcid'
names(pfocr.ml)[names(pfocr.ml) == 'figure'] <- 'figid'

# count entrez per figure.
pfocr.ml.cnt <- pfocr.ml %>% 
  dplyr::select(-word, -hgnc_symbol, -symbol, -source, -entrez) %>% 
  dplyr::group_by(figid, pmcid, filename, number, figtitle, caption, figlink, reftext, type.man, automl_index, pathway_score, pathway_score_old) %>%
  dplyr::summarise(entrez_count = n())
  
# First collapse bioentity cases per figure and word,...
pfocr.ml.nobe <- pfocr.ml %>% 
  dplyr::select(-hgnc_symbol, -symbol, -entrez) %>% 
  dplyr::group_by(figid, pmcid, filename, number, figtitle, caption, figlink, reftext, type.man, automl_index, pathway_score, pathway_score_old, word, source) %>%
  dplyr::summarise(entrez_count = n()) 
# ... then count entrez per figure.
pfocr.ml.nobecnt <- pfocr.ml.nobe %>% 
  dplyr::select(-source, -word) %>% 
  dplyr::group_by(figid, pmcid, filename, number, figtitle, caption, figlink, reftext, type.man, automl_index, pathway_score, pathway_score_old) %>%
  dplyr::summarise(entrez_count = n()) #  count

# Subset with 3 or more nobe genes
pfocr.ml.nobecnt3 <- pfocr.ml.nobecnt %>%
  dplyr::filter(entrez_count >= 3) %>%
  ungroup()

#saveRDS(as.data.frame(pfocr.ml.nobecnt3), "pfocr.ml10k.nobecnt3.rds")
#pfocr.ml.nobecnt3 <- readRDS("pfocr.ml10k.nobecnt3.rds")

# Subset with N or more nobe genes and pathway_score >= 0.5 or manually curated
pfocr.ml.nobecnt1.ps5 <- pfocr.ml.nobecnt %>%
  dplyr::filter((pathway_score >= 0.5 & 
                   (type.man == "pathway" | is.na(type.man))) |
                  (pathway_score < 0.5 &
                     type.man == "pathway")) 
  
saveRDS(as.data.frame(pfocr.ml.nobecnt3.ps5), "pfocr.ml10k.nobecnt3.ps5.rds")
#pfocr.ml.nobecnt3.ps5 <- readRDS("pfocr.ml10k.nobecnt3.ps5.rds")

# plot
pfocr.ml.nobecnt1.ps5.pre <- arrange(pfocr.ml.nobecnt1.ps5.pre, !is.na(type.man), type.man)
ggplot(pfocr.ml.nobecnt1.ps5.pre, aes(pathway_score, entrez_count)) +
  labs(fill="Confirmed") +
  geom_point(aes(fill=type.man), shape=21, alpha=0.5) + 
  scale_color_manual(values="#666666") +
  scale_fill_manual(values=alpha(c("pathway" = "blue"),0.01),na.value="#CCCCCC") #"other" = "red", "composite" = "green"

# # dataframes with genes
# pfocr.ml.nobecnt3.ps5.genes <- pfocr.ml %>%
#   dplyr::filter(figid %in% pfocr.ml.nobecnt3.ps5$figid)
# saveRDS(as.data.frame(pfocr.ml.nobecnt3.ps5.genes), "pfocr.ml10k.nobecnt3.ps5.genes.rds")
# 
# # only nobe genes
# pfocr.ml.nobecnt3.ps5.nobegenes <- pfocr.ml.nobe %>%
#   ungroup() %>%
#   dplyr::filter(figid %in% pfocr.ml.nobecnt3.ps5$figid)
# #saveRDS(as.data.frame(pfocr.ml.nobecnt3.ps5.nobegenes), "pfocr.ml10k.nobecnt3.ps5.nobegenes.rds")

## Cutoff data.frames
pfocr.ml.nobecnt3.figid <- pfocr.ml.nobecnt %>%
  ungroup() %>%
  dplyr::filter((pathway_score >= 0.5 & 
                   (type.man == "pathway" | is.na(type.man))) |
                  (pathway_score < 0.5 &
                     type.man == "pathway")) %>%
  dplyr::filter(entrez_count >= 3) %>%
  select(figid) %>%
  unique() 

pfocr.ml.nobecnt3.ps5.genes <- pfocr.ml %>%
  dplyr::filter(figid %in% pfocr.ml.nobecnt3.figid$figid)
# saveRDS(as.data.frame(pfocr.ml.nobecnt3.ps5.genes), "pfocr.ml10k.nobecnt3.ps5.genes.rds")
pfocr.ml.nobecnt3.ps5.genes <- readRDS("pfocr.ml10k.nobecnt3.ps5.genes.rds")
# write.table(pfocr.ml.nobecnt3.ps5.genes, "pfocr.ml10k.nobecnt3.ps5.genes.tsv", sep = "\t", row.names = F)


## Cutoffs and Plot
cutoff = c(2,3,5,7,10,15,20,30,45,70,100)
cutoff.data <- sapply (cutoff, function(c){
  pfocr.ml.nobecntX.figid <- pfocr.ml.nobecnt %>%
    ungroup() %>%
    dplyr::filter((pathway_score >= 0.5 & 
                     (type.man == "pathway" | is.na(type.man))) |
                    (pathway_score < 0.5 &
                       type.man == "pathway")) %>%
    dplyr::filter(entrez_count >= c) %>%
    select(figid) %>%
    unique() 
  
  pfocr.ml.nobecntX.ps5.genes <- pfocr.ml %>%
    dplyr::filter(figid %in% pfocr.ml.nobecntX.figid$figid)
  
  fp = length(unique(pfocr.ml.nobecntX.ps5.genes$figid)) / nrow(pfocr.ml.nobecnt1.ps5)
  gp = length(unique(pfocr.ml.nobecntX.ps5.genes$entrez)) / length(unique(pfocr.ml.nobecnt1.ps5.genes$entrez))
  c(fp=unlist(fp),gp=unlist(gp))
})

# Percent of figures by percent of unique genes per min gene cutoff
gene.loss <- data.frame(fig.pct = cutoff.data[1,], 
                        gene.pct = cutoff.data[2,],
                        cutoff = cutoff)

ggplot(gene.loss, aes((fig.pct), gene.pct, label=cutoff)) +
  geom_point() +
  geom_text(aes(label=cutoff),hjust=1.2, vjust=0) +
  scale_x_reverse( lim=c(1,0)) +
  scale_y_continuous(lim=c(0,1))


## 65k set
pfocr.ml.ps5.all65k <- df.all.man.235k %>%
  dplyr::filter((pathway_score >= 0.5 & 
                   (type.man == "pathway" | is.na(type.man))) |
                  (pathway_score < 0.5 &
                     type.man == "pathway")) 
#saveRDS(as.data.frame(pfocr.ml.ps5.all65k), "pfocr.ml10k.ps5.all65k.rds")
pfocr.ml.ps5.all65k <- readRDS("pfocr.ml10k.ps5.all65k.rds")
#write.table(pfocr.ml.ps5.all65k, "pfocr.ml10k.ps5.all65k.tsv", sep = "\t", row.names = F)

# STATS for automl_10k, OCR_20200224, nobecnt3, ps5
length(unique(pfocr.ml.nobecnt3.ps5.genes$figid)) #unique figures: 47,680
length(unique(pfocr.ml.nobecnt3.ps5.genes$pmcid)) #unique papers: 41,988
length(pfocr.ml.nobecnt3.ps5.genes$entrez)        #total genes: 1,084,905
length(unique(pfocr.ml.nobecnt3.ps5.genes$word)) #unique gene symbols: 80,135 (6:1 symbols to entrez)
length(unique(pfocr.ml.nobecnt1.ps5.genes$entrez)) #unique genes: 13,449
length(pfocr.ml.nobecnt3.ps5.nobegenes$word)        #total nobe gene symbols: 530,399
length(unique(pfocr.ml.nobecnt3.ps5.nobegenes$word)) #unique nobe gene symbols: 80,135
pfocr.ml.nobecnt3.ps5.genes %>%
  dplyr::filter(source != "bioentities_symbol") %>%
  select(entrez) %>%                                 
  unique() %>%                                       # unique nobe genes: 13,358
  count()
pfocr.ml.nobecnt3.ps5.nobegenes %>%
  dplyr::filter(source == "bioentities_symbol") %>%
  select(word) %>%                                  # total bioentities symbols: 109,365
  # unique() %>%                                       # unique bioentities symbols: 7733 (4:1 symbols to entrez)
  count()
pfocr.ml.nobecnt3.ps5.genes %>%
  dplyr::filter(source == "bioentities_symbol") %>%
  select(entrez) %>%                                 
  unique() %>%                                       # unique bioentities genes: 1864 (91 not found outside of be expansion)
  count()


# pfocr.ml.nobecnt3.ps7_8 <- pfocr.ml.nobecnt3 %>%  dplyr::filter(pathway_score >= 0.7 & pathway_score < 0.8)
# pfocr.ml.nobecnt3.ps6_7 <- pfocr.ml.nobecnt3 %>%  dplyr::filter(pathway_score >= 0.6 & pathway_score < 0.7)
# pfocr.ml.nobecnt3.ps5_6 <- pfocr.ml.nobecnt3 %>%  dplyr::filter(pathway_score >= 0.5 & pathway_score < 0.6)
# pfocr.ml.nobecnt3.ps4_5 <- pfocr.ml.nobecnt3 %>%  dplyr::filter(pathway_score >= 0.4 & pathway_score < 0.5)
# pfocr.ml.nobecnt3.ps3_4 <- pfocr.ml.nobecnt3 %>%  dplyr::filter(pathway_score >= 0.3 & pathway_score < 0.4)
# pfocr.ml.nobecnt3.ps2_3 <- pfocr.ml.nobecnt3 %>%  dplyr::filter(pathway_score >= 0.2 & pathway_score < 0.3)
# 
# saveRDS(pfocr.ml.nobecnt3.ps7_8, "pfocr.ml.nobecnt3.ps7_8.rds")
# saveRDS(pfocr.ml.nobecnt3.ps6_7, "pfocr.ml.nobecnt3.ps6_7.rds")

# saveRDS(pfocr.ml.nobecnt3.ps5_6, "pfocr.ml.nobecnt3.ps5_6.rds")
# pathways: 711/985 = 72%
# composite: 168/985 = 17%
# other: 105/985 = 11%

#saveRDS(pfocr.ml.nobecnt3.ps4_5, "pfocr.ml.nobecnt3.ps4_5.rds")
# pathways: 563/876 = 64%
# composite: 172/876 = 20%
# other: 141/876 = 16%

#saveRDS(pfocr.ml.nobecnt3.ps3_4, "pfocr.ml.nobecnt3.ps3_4.rds")
#saveRDS(pfocr.ml.nobecnt3.ps2_3, "pfocr.ml.nobecnt3.ps2_3.rds")


#### NETWORKS ##########
#install.packages("Matrix")
library(Matrix)

sample <- pfocr.ml.nobecnt3.ps5.genes  #%>%
  # filter(figid %in% (pfocr.ml.nobecnt3.ps5.genes$figid[1:10000]))
sample <- unique(sample[c("figid", "entrez")])

figid.fac <- factor(sample$figid)
gene.fac <- factor(sample$entrez)
gene.fac.df <- data.frame(val = unique(gene.fac), lvl = as.numeric(unique(gene.fac)))

sm.nobecnt3 <- sparseMatrix(
  as.numeric(figid.fac), 
  as.numeric(gene.fac),
  dimnames = list(
    as.character(levels(figid.fac)), 
    as.character(levels(gene.fac))),
  x = 1)

# calculating co-occurrences
v.nobecnt3 <- t(sm.nobecnt3) %*% sm.nobecnt3

# setting transactions counts of items to zero
diag(v.nobecnt3) <- 0
v.nobecnt3

# cross-product of vectors (numerator)
num <- v.nobecnt3 %*% v.nobecnt3

# square root of square sum of each vector (used for denominator)
srss <- sqrt(apply(v.nobecnt3^2, 1, sum))

# denominator
den <- srss %*% t(srss)

# cosine similarity
v.cos.sim <- num / den

# cosine distance
v.cos.dist <- 1 - v.cos.sim

#5578, 5330, 4
# sample %>% filter(entrez==2767)
# gene.fac.df %>% arrange(lvl)

## gene freq
gene.freq <- sample %>%
  group_by(entrez) %>%
  summarize(freq = n())

## write
v.nobecnt3.sif <- summary(v.nobecnt3)
v.nobecnt3.sif.sub <- v.nobecnt3.sif %>%
  filter(x > 1) 
v.nobecnt3.sif.sub.freq <- merge(v.nobecnt3.sif.sub, gene.fac.df, by.x = "i", by.y="lvl", all.x = T)
v.nobecnt3.sif.sub.freq <- merge(v.nobecnt3.sif.sub.freq, gene.fac.df, by.x = "j", by.y="lvl", all.x = T)
v.nobecnt3.sif.sub.freq <- merge(v.nobecnt3.sif.sub.freq, gene.freq, by.x = "val.x", by.y="entrez", all.x = T)
v.nobecnt3.sif.sub.freq <- merge(v.nobecnt3.sif.sub.freq, gene.freq, by.x = "val.y", by.y="entrez", all.x = T)
names(v.nobecnt3.sif.sub.freq) <- c("entrez_y", "entrez_x","index_y", "index_x", "co_freq",  "x_freq","y_freq")
v.nobecnt3.sif.sub.freq <- v.nobecnt3.sif.sub.freq %>%
  mutate(pct_x_freq = co_freq/x_freq) %>%
  mutate(pct_y_freq = co_freq/y_freq) %>%
  mutate(max_pct = pmax(.$pct_x_freq,.$pct_y_freq)) %>%
  mutate(min_pct = pmin(.$pct_x_freq,.$pct_y_freq))
max(v.nobecnt3.sif.sub.freq$pct_x_freq)
max(v.nobecnt3.sif.sub.freq$pct_y_freq)

v.nobecnt3.sif.sub.freq.sub <- v.nobecnt3.sif.sub.freq %>%
  filter(max_pct > 0.1)
write.table(v.nobecnt3.sif.sub.freq.sub, file = "v.nobecnt3.sub.tsv", row.names=FALSE, sep = "\t")

write.table(v.nobecnt3.sif.sub.freq, file = "v.nobecnt3.tsv", row.names=FALSE, sep = "\t")
#writeMM(v.nobecnt3, "v.nobecnt3.mtx")

############
### OLD ####
############

## Extract running tally
data <- data.frame(pathway=character(0),
                   composite=character(0),
                   other=character(0))

for (n in seq(1,5763-1000,100)) { #MOD: using 5763 to exclude unordered "plus" matches at end of target df
  figs <- df.target %>% filter(row_number() %in% seq(n,n+999)) %>% select(pmc.figid)
  p <- df.path %>% filter(pmc.figid %in% figs$pmc.figid) %>% nrow()
  c <- df.comp %>% filter(pmc.figid %in% figs$pmc.figid) %>% nrow()
  o <- df.other %>% filter(pmc.figid %in% figs$pmc.figid) %>% nrow()
  data <- rbind(data, data.frame(pathway=p, composite=c, other=o))
}

# quick plot
matplot(rownames(data),data, type="l")

# reshape for ggplot
data$id <- 1:nrow(data) 
plot_data <- melt(data,id.var="id")

# format values at percentages
plot_data <- plot_data %>% 
  mutate(value = value/1000) %>%
  mutate(id = id / 48)

# plots
ggplot(plot_data, aes(x=id,y=value)) +
  xlab("Percentage through PMC query results") +
  ylab("Percentage of figures by type" ) +
  labs(color="Type") +
  geom_line(aes(color=variable)) +
  scale_color_brewer(type="qual", palette=7)


ggplot(plot_data, aes(fill=variable, y=value, x=id)) +
  geom_bar(position="fill", stat="identity") +
  scale_fill_brewer(type="qual", palette=7)


#####################
## Unique gene counts

df.path.g <- readRDS(paste(image.path,"pathway",paste0("pfocr_","pathway_genes",".rds"),sep = '/'))
df.comp.g <- readRDS(paste(image.path,"composite",paste0("pfocr_","composite_genes",".rds"),sep = '/'))
df.other.g <- readRDS(paste(image.path,"other",paste0("pfocr_","other_genes",".rds"),sep = '/'))

## Extract running tally
data.g <- data.frame(pathway=character(0),
                   composite=character(0),
                   other=character(0))

for (n in seq(1,5763-1000,100)) { #MOD: using 5763 to exclude unordered "plus" matches at end of target df
  figs <- df.target %>% filter(row_number() %in% seq(n,n+999)) %>% select(pmc.figid)
  p.g <- df.path.g %>% filter(figid %in% figs$pmc.figid) %>% distinct(entrez) 
  c.g <- df.comp.g %>% filter(figid %in% figs$pmc.figid) %>% distinct(entrez) 
  o.g <- df.other.g %>% filter(figid %in% figs$pmc.figid) %>% distinct(entrez)
  u.g <- distinct(rbind(p.g,c.g,o.g))
  p <- nrow(p.g) / nrow(u.g) 
  c <- nrow(c.g) / nrow(u.g) 
  o <- nrow(o.g) / nrow(u.g) 
  data.g <- rbind(data.g, data.frame(pathway=p, composite=c, other=o))
}

# format values as percentages
# data.g <- data.g %>%
#   mutate(pathway.p=pathway/rowSums(.[1:3])) %>%
#   mutate(composite.p=composite/rowSums(.[1:3])) %>%
#   mutate(other.p=other/rowSums(.[1:3])) %>%
#   select(4:6) %>%
#   set_colnames(c("pathway","composite","other"))

head(data.g)

# quick plot
matplot(rownames(data.g),data.g, type="l")

# reshape for ggplot
data.g$id <- 1:nrow(data.g) 
plot_data.g <- melt(data.g,id.var="id")

# format values as percentages
plot_data.g <- plot_data.g %>% 
  mutate(id = id / 48)

# plots
ggplot(plot_data.g, aes(x=id,y=value)) +
  xlab("Percentage through PMC query results") +
  ylab("Percentage of unique genes by type" ) +
  labs(color="Type") +
  geom_line(aes(color=variable)) +
  scale_color_brewer(type="qual", palette=7)

#####################3
#### UpSetR: PFOCR and PubTator Genes

library(UpSetR)

setwd("~/Dropbox (Gladstone)/PFOCR_25Years/tables")

pubtator <- read.csv("top_pubtator_genes_in_pubtator.csv", stringsAsFactors = F)
pfocr <- read.csv("top_pubtator_genes_in_pfocr.csv", stringsAsFactors = F)

pubtator2 <- pubtator %>% 
  mutate(AKT1 = if_else(AKT1 == "True", 1, 0))%>% 
  mutate(MTOR = if_else(MTOR == "True", 1, 0))%>% 
  mutate(TP53 = if_else(TP53 == "True", 1, 0))%>% 
  mutate(MAPK1 = if_else(MAPK1 == "True", 1, 0))%>% 
  mutate(TGFB1 = if_else(TGFB1 == "True", 1, 0)) %>%
  mutate(source = "pubtator")

pfocr2 <- pfocr %>% 
  mutate(AKT1 = if_else(AKT1 == "True", 1, 0))%>% 
  mutate(MTOR = if_else(MTOR == "True", 1, 0))%>% 
  mutate(TP53 = if_else(TP53 == "True", 1, 0))%>% 
  mutate(MAPK1 = if_else(MAPK1 == "True", 1, 0))%>% 
  mutate(TGFB1 = if_else(TGFB1 == "True", 1, 0)) %>%
  mutate(source = "pfocr")

combo <- pubtator2 %>%
  bind_rows(pfocr2)

## drop TGFB1 and group
combo2 <- combo %>%
  select(-TGFB1) %>%
  group_by(pmcid, AKT1, MTOR, TP53, MAPK1) %>% 
  dplyr::summarise(source=paste0(source, collapse = "|"))

upset(pfocr2,
      nsets = 5, number.angles = 0, point.size = 3.5, line.size = 2,
      mainbar.y.label = "Papers Mentioning Genes", sets.x.label = "Total Gene Mentions"
)
upset(pubtator2,
      nsets = 5, number.angles = 0, point.size = 3.5, line.size = 2,
      mainbar.y.label = "Papers Mentioning Genes", sets.x.label = "Total Gene Mentions"
)

upset(as.data.frame(combo2),
      nsets = 4, number.angles = 0, point.size = 3.5, line.size = 2,
      mainbar.y.label = "Papers Mentioning Genes", sets.x.label = "Total Gene Mentions"
)

# upset(combo,
#       nsets = 5, number.angles = 0, point.size = 3.5, line.size = 2,
#       mainbar.y.label = "Papers Mentioning Genes", sets.x.label = "Total Gene Mentions",
#       query.legend = "top",
#       queries = list(
#         list(
#           query = elements,
#           params = list("source", "pubtator"),
#           color = "#Df5286", 
#           active = F,
#           query.name = "PubTator"
#         ),
#         list(
#           query = elements,
#           params = list("source", "pfocr"),
#           color = "#8f52D6", 
#           active = F,
#           query.name = "Pfocr"
#         )
#       )
# )


## stacked queries
#https://github.com/hms-dbmi/UpSetR/issues/59
#https://stackoverflow.com/questions/54770795/stacked-barplot-in-upsetr/56704255#56704255

metadata <- data.frame(
  c("AKT1",  "MTOR",  "TP53",  "MAPK1"),
  as.numeric(apply(combo2[which(combo2$source=="pubtator"),2:5],2, sum))
)
colnames(metadata) <- c(
  "genes",
  "Text"
)

metadata2 <- data.frame(
  c("AKT1",  "MTOR",  "TP53",  "MAPK1"),
  as.numeric(apply(combo2[which(combo2$source=="pfocr"),2:5],2, sum))
)
colnames(metadata2) <- c(
  "genes",
  "Figures"
)

metadata3 <- data.frame(
  c("AKT1",  "MTOR",  "TP53",  "MAPK1"),
  as.numeric(apply(combo2[which(combo2$source=="pubtator|pfocr"),2:5],2, sum))
)
colnames(metadata3) <- c(
  "genes",
  "Both"
)


upset(as.data.frame(combo2),
      text.scale = 2,
      sets = c("AKT1",  "MTOR",  "TP53",  "MAPK1"), 
      mainbar.y.label = "Papers Mentioning Genes", 
      sets.x.label = "",
      main.bar.color = "#94BED9",
      show.numbers = F,
      mainbar.y.max = 5000,
      query.legend = "top",
      # set.metadata = list(
      #   data = metadata2,
      #   plots = list(
      #     ### YOU HAVE TO DO THESE ONE AT A TIME :(
      #     # list(type = "hist",
      #     #      column = "Text",
      #     #      assign = 10,
      #     #      colors = "#BCC8A7")
      #     list(type = "hist",
      #          column = "Figures",
      #          assign = 10, # defines width of the meta-data histogram
      #          colors = "#94BED9")
      #     # list(type = "hist",
      #     #      column = "Both",
      #     #      assign = 10, 
      #     #      colors = "#Df5286")
      #     
      #   )
      # ),
      queries = list(
        list(query = elements, 
             params = list("source", c("pfocr","pubtator", "pubtator|pfocr")), 
             color = "#94BED9", 
             active = T,
             query.name = "Figures"),
        list(query = elements, 
             params = list("source", c("pubtator", "pubtator|pfocr")), 
             color = "#BCC8A7", 
             active = T,
             query.name = "Text"),
        list(query = elements, 
             params = list("source", "pubtator|pfocr"), 
             color = "#Df5286", 
             active = T,
             query.name = "Both")
        # list(query = intersects, params = list("MAPK1"), color = "#Df5286"),
        # list(query = intersects, params = list("AKT1"), color = "#Df5286"),
        # list(query = intersects, params = list("MTOR"), color = "#Df5286"),
        # list(query = intersects, params = list("TP53"), color = "#Df5286"),
        # list(query = intersects, params = list("TGFB1"), color = "#Df5286"),
        # list(query = intersects, params = list("MAPK1", "AKT1"), color = "#Df5286", active=T),
        # list(query = intersects, params = list("MTOR", "AKT1"), color = "#Df5286", active=T)
      )
)

## barplots
library(ggpubr)
theme_set(theme_pubr())

metadata <- within(metadata, 
                   genes <- factor(genes, 
                                   levels=c("MAPK1", "AKT1",  "MTOR",  "TP53")))
metadata2 <- within(metadata2, 
                   genes <- factor(genes, 
                                   levels=c("MAPK1", "AKT1",  "MTOR",  "TP53")))
metadata3 <- within(metadata3, 
                   genes <- factor(genes, 
                                   levels=c("MAPK1", "AKT1",  "MTOR",  "TP53")))

p1 <-ggplot(data=metadata2, aes(x=genes, y=Figures)) +
  geom_bar(stat="identity", width = .5, fill = "#94BED9")  +
  coord_flip() +
  scale_y_continuous(trans = "reverse", breaks = c(0, 8000)) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "none", axis.title.y=element_blank(),
        axis.text.y = element_blank())
p1

p2 <-ggplot(data=metadata, aes(x=genes, y=Text)) +
  geom_bar(stat="identity", width = .5, fill ="#BCC8A7")  +
  coord_flip() +
  scale_y_continuous(trans = "reverse", breaks = c(0, 800)) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "none", axis.title.y=element_blank(),
        axis.text.y = element_blank())
p2

p3 <-ggplot(data=metadata3, aes(x=genes, y=Both)) +
  geom_bar(stat="identity", width = .5, fill="#Df5286")  +
  coord_flip() +
  scale_y_continuous(trans = "reverse", breaks = c(0, 800)) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "none", axis.title.y=element_blank(),
        axis.text.y = element_blank())
p3

ggarrange(p1, p2, p3,
          # labels = c("A", "B", "C"),
          ncol = 3, nrow = 1)
