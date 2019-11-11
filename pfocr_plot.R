# plot - plot results of pfocr and image classifaction

library(magrittr)
library(dplyr)
library(ggplot2)
library(reshape2)

## LOCAL INFO PER INSTALLATION
fetch.path <- "/git/wikipathways/pathway-figure-ocr/20181216"
image.path <- paste(fetch.path, "images", sep = '/')

## Grab results of screen
df.target <- readRDS(paste(fetch.path,"pmc.df.target.rds",sep='/'))
df.path <- readRDS(paste(image.path,"pathway",paste0("pfocr_","pathway",".rds"),sep = '/'))
df.comp <- readRDS(paste(image.path,"composite",paste0("pfocr_","composite",".rds"),sep = '/'))
df.other <- readRDS(paste(image.path,"other",paste0("pfocr_","other",".rds"),sep = '/'))


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

