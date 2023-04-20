## fetch pathway figure PMCIDs from NCBI

## NOTE: query qualifier for figure captions [CAPT] is clearly broken and only hits on a fraction of caption titles.
##  the "imagesdocsum" report type does a better job of actually searching captions, e.g.:
# https://www.ncbi.nlm.nih.gov/pmc/?term=(signaling+pathway)+AND+(2019+[pdat])&report=imagesdocsum&dispmax=100 
## (11349 hits with "signaling pathway" in every caption title or caption body)
# https://www.ncbi.nlm.nih.gov/pmc/?term=(signaling+pathway[CAPT])+AND+(2019+[pdat])&report=imagesdocsum&dispmax=100
## (244 hits with "signaling pathway" ONLY in caption titles)
# https://www.ncbi.nlm.nih.gov/pmc/?term=(signaling+pathway[CAPT])+AND+(2019+[pdat])
## (2775 hits when "report=imagesdocsum" is excluded)

## NOTE: the imagesdocsum" report is not supported by NCBI's eutils, so we'll have to go with HTML scraping. 
##  The pagination of pmc output is not apparent, however...

## Example queries for what is possible
# https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&term=asthma[mesh]+AND+leukotrienes[mesh]+AND+2009[pdat]&usehistory=y&retmax=500&retStart=0
# https://www.ncbi.nlm.nih.gov/pmc/?term=signaling+pathway+AND+2018+[pdat]&report=imagesdocsum&dispmax=100
# https://www.ncbi.nlm.nih.gov/pmc/?term=((((((((((signaling+pathway)+OR+regulatory+pathway)+OR+disease+pathway)+OR+drug+pathway)+OR+metabolic+pathway)+OR+biosynthetic+pathway)+OR+synthesis+pathway)+OR+cancer+pathway)+OR+response+pathway)+OR+cycle+pathway)+AND+(\%222019/01/01\%22[PUBDATE]+%3A+\%223000\%22[PUBDATE])&report=imagesdocsum&dispmax=100#
## Network query:
# https://www.ncbi.nlm.nih.gov/pmc/?term=((network)+OR+PPI)+AND+(%222019/01/01%22[PUBDATE]+%3A+%223000%22[PUBDATE])&report=imagesdocsum&dispmax=100

##################
## QUERY BUILDER
##################

## Pathway types:
query.terms <- c("signaling+pathway",
                 "signalling+pathway",
                 "regulatory+pathway",
                 "disease+pathway",
                 "drug+pathway",
                 "metabolic+pathway",
                 "biosynthetic+pathway",
                 "synthesis+pathway",
                 "cancer+pathway",
                 "response+pathway",
                 "cycle+pathway"
)

query.date.from <- "1995/01/01"
query.date.to <- "3000/01/01"

term <- paste0("term=",paste(rep("(",length(query.terms)),collapse = ""),paste(lapply(query.terms, function(x){
  paste0(x,")")
}), collapse = "+OR+"),
'+AND+("',query.date.from,'"[PUBDATE]+%3A+"',query.date.to,'"[PUBDATE])')

query.url <- paste0("https://www.ncbi.nlm.nih.gov/pmc/?",
                term,
                "&report=imagesdocsum",
                "&dispmax=100")

################
## PMC SCRAPER
################
library(conflicted)
library(RSelenium)
library(rvest)
library(xml2)
library(tidyverse)
conflict_prefer("filter", "dplyr")
conflict_prefer("select", "dplyr")
conflict_prefer("mutate", "dplyr")

# set dir for saving results as tsv
setwd("/git/wikipathways/pathway-figure-ocr/20200214")
cat(query.url, file="query.txt")
write.table(data.frame("figureid","pmcid", "filename", "fignumber", "figtitle",  "papertitle", "figcaption", "figlink", "reftext"), 
            file = "pmc.df.all.tsv",
            append = FALSE,
            sep = '\t',
            quote = FALSE,
            col.names = FALSE, 
            row.names = FALSE)


# launch Docker.app
# run this line in Terminal: docker run -d -p 4445:4444 selenium/standalone-firefox:2.53.0

remDr <- remoteDriver(
  remoteServerAddr = "localhost",
  port = 4445L
)

remDr$open()

## go to query result
remDr$navigate(query.url)
# confirm you got there
remDr$screenshot(display = TRUE)

## Collect all pages!
df.all <- data.frame(figid=character(),pmcid=character(), filename=character(), 
                         number=character(), figtitle=character(), papertitle=character(), 
                         caption=character(), figlink=character(), reftext=character())

page.count <- xml2::read_html(remDr$getPageSource()[[1]]) %>%
  rvest::html_nodes(".title_and_pager") %>%
  rvest::html_node(".pagination") %>%
  rvest::html_nodes("a") %>%
  rvest::html_attr("page")
page.count <- as.integer(page.count[4])

for (i in 1:page.count){

  ## Parse page
  page.source <- xml2::read_html(remDr$getPageSource()[[1]])
  filename <- page.source %>%
    rvest::html_nodes(".rprt_img") %>%
    rvest::html_node("img") %>%
    rvest::html_attr("src-large") %>%
    str_match("bin/(.*\\.jpg)") %>%
    as.data.frame() %>%
    select(2) %>%
    as.matrix() %>%
    as.character()
  number <- page.source %>%
    rvest::html_nodes(".rprt_img") %>%
    rvest::html_node("img") %>%
    rvest::html_attr("alt") 
  titles <- page.source %>%
    rvest::html_nodes(".rprt_img") %>%
    rvest::html_node(xpath='..') %>%
    rvest::html_node(".rprt_cont") %>%
    rvest::html_node(".title") %>%
    rvest::html_text() %>%
    str_split("\\s+From: ", simplify = TRUE)
  papertitle <- titles[,2] %>% 
    str_trim()
  caption <- page.source %>%
    rvest::html_nodes(".rprt_img") %>%
    rvest::html_node(xpath='..') %>%
    rvest::html_node(".rprt_cont") %>%
    rvest::html_node(".supp") %>%
    rvest::html_text()
  figlink <- page.source %>%
    rvest::html_nodes(".rprt_img") %>% 
    rvest::html_attr("image-link")
  reftext <- page.source %>%
    rvest::html_nodes(".rprt_img") %>%
    rvest::html_node(xpath='..') %>%
    rvest::html_node(".rprt_cont") %>%
    rvest::html_node(".aux") %>%
    rvest::html_text() %>%
    str_remove(fixed("CitationFull text"))
  pmcid <- page.source %>%
    rvest::html_nodes(".rprt_img") %>%
    rvest::html_node(xpath='..') %>%
    rvest::html_node(".rprt_cont") %>%
    rvest::html_node(".title") %>%
    rvest::html_node("a") %>%
    rvest::html_attr("href") %>%
    str_match("PMC\\d+") %>%
    as.character()
  
  ## Extract best figure title from analysis of provided, number, title and caption
  temp.df  <- data.frame(n=number, t=titles[,1], c=caption, stringsAsFactors = FALSE) %>%
    mutate(t=str_trim(str_remove(t,fixed(as.character(number)))))
  temp.df  <- temp.df  %>%
    mutate(c=if_else(is.na(c),t,c)) %>%
    mutate(t=str_trim(str_remove(t,"\\.$"))) %>%
    mutate(t=if_else(t=="",c,t)) %>%
    mutate(t=if_else(!is.na(str_match(t,"\\. .*")),str_remove(t,"\\. .*"),t)) %>%
    mutate(t=str_trim(str_remove(t,"\\.+$"))) %>%
    mutate(t=str_trim(str_remove(t,"^\\."))) %>%
    mutate(c=str_trim(str_replace(c,"\\.\\.","\\."))) %>%
    mutate(n=str_trim(str_replace(n,"\\.$","")))
  number <- as.character(temp.df[,1])
  figtitle <- as.character(temp.df[,2])
  caption <- as.character(temp.df[,3])
  
  ## Prepare df and write to R.object and tsv
  df <- data.frame(pmcid, filename, number, figtitle, papertitle, caption, figlink, reftext) %>%
    mutate(figid=paste(pmcid,filename, sep = "__")) %>%
    select(figid,pmcid, filename, number, figtitle, papertitle, caption, figlink, reftext)
  
  df.all <- rbind(df.all, df)
  
  write.table(df, 
              file = "pmc.df.all.tsv",
              append = TRUE,
              sep = '\t',
              quote = FALSE,
              col.names = FALSE, 
              row.names = FALSE,
              fileEncoding = "UTF-8")
  
  if (i < page.count-1){
    next.page.button <- remDr$findElement(using = "xpath", "//*[@class='active page_link next']")
    next.page.button$clickElement()
    #remDr$screenshot(display = TRUE)
  }
  
  print(paste(i,"of",page.count))
}

#If error, go back a page (next line) and enter last page number as new start in for loop
#remDr$goBack()

## At the end of the day...
df.all<-unique(df.all)
saveRDS(df.all, file = "pmc.df.all.rds")
#df.all <- readRDS("pmc.df.all.rds")

## Close up shop
remDr$closeall()

# In Terminal:
# docker ps ## note CONTAINER ID
# docker stop <CONTAINER ID>