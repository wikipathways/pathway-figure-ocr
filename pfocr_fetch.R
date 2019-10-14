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

query.date.from <- "2019/01/01"
query.date.to <- "3000"

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
library(RSelenium)
library(rvest)
library(xml2)
library(tidyverse)

# set dir for saving results as tsv
setwd("/git/wikipathways/pathway-figure-ocr/20191013")
tsv.out <- "pfocr_fetch.tsv"
robj.out <- "pfocr_fetch.Rdata"
write.table(data.frame("figureid","pmcid", "filename", "fignumber", "figtitle",  "papertitle", "figcaption", "reftext"), 
            paste("pfocr_fetch.tsv",sep = '/'), 
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
pmc.df.all <- data.frame(pmc.figid=character(),pmc.pmcid=character(), pmc.filename=character(), 
                         pmc.number=character(), pmc.figtitle=character(), pmc.papertitle=character(), 
                         pmc.caption=character(), pmc.reftext=character())

page.count <- xml2::read_html(remDr$getPageSource()[[1]]) %>%
  rvest::html_nodes(".title_and_pager") %>%
  rvest::html_node(".pagination") %>%
  rvest::html_nodes("a") %>%
  rvest::html_attr("page")
page.count <- as.integer(page.count[4])

for (i in 1:page.count){

  ## Parse page
  pmc.filename <- xml2::read_html(remDr$getPageSource()[[1]]) %>%
    rvest::html_nodes(".rprt_img") %>%
    rvest::html_node("img") %>%
    rvest::html_attr("src-large") %>%
    str_match("bin/(.*\\.jpg)") %>%
    as.data.frame() %>%
    select(2) %>%
    as.matrix() %>%
    as.character()
  pmc.number <- xml2::read_html(remDr$getPageSource()[[1]]) %>%
    rvest::html_nodes(".rprt_img") %>%
    rvest::html_node("img") %>%
    rvest::html_attr("alt") %>%
    str_remove_all("<.*?>")
  pmc.titles <- xml2::read_html(remDr$getPageSource()[[1]]) %>%
    rvest::html_nodes(".rprt_img") %>%
    rvest::html_node(xpath='..') %>%
    rvest::html_node(".rprt_cont") %>%
    rvest::html_node(".title") %>%
    rvest::html_text() %>%
    str_split("\\s+From: ", simplify = TRUE)
  pmc.papertitle <- pmc.titles[,2] %>% 
    str_trim()
  pmc.caption <- xml2::read_html(remDr$getPageSource()[[1]]) %>%
    rvest::html_nodes(".rprt_img") %>%
    rvest::html_node(xpath='..') %>%
    rvest::html_node(".rprt_cont") %>%
    rvest::html_node(".supp") %>%
    rvest::html_text()
  pmc.reftext <- xml2::read_html(remDr$getPageSource()[[1]]) %>%
    rvest::html_nodes(".rprt_img") %>%
    rvest::html_node(xpath='..') %>%
    rvest::html_node(".rprt_cont") %>%
    rvest::html_node(".aux") %>%
    rvest::html_text() %>%
    str_remove("CitationFull text")
  pmc.pmcid <- xml2::read_html(remDr$getPageSource()[[1]]) %>%
    rvest::html_nodes(".rprt_img") %>%
    rvest::html_node(xpath='..') %>%
    rvest::html_node(".rprt_cont") %>%
    rvest::html_node(".title") %>%
    rvest::html_node("a") %>%
    rvest::html_attr("href") %>%
    str_match("PMC\\d+") %>%
    as.character()
  
  ## Extract best figure title from analysis of provided, number, title and caption
  temp.df  <- data.frame(n=pmc.number, t=pmc.titles[,1], c=pmc.caption, stringsAsFactors = FALSE) %>%
    mutate(t=str_trim(str_remove(t,paste0(as.character(n),"\\.{0,1}")))) 
  temp.df  <- temp.df  %>%
    mutate(c=if_else(is.na(c),t,c)) %>%
    mutate(t=if_else(t=="",c,t)) %>%
    mutate(t=if_else(!is.na(str_match(t,"\\. .*")),str_remove(t,"\\. .*"),t)) %>%
    mutate(t=str_trim(str_remove(t,"\\.+$"))) %>%
    mutate(c=str_trim(str_replace(c,"\\.\\.","\\."))) %>%
    mutate(n=str_trim(str_replace(n,"\\.$","")))
  pmc.number <- as.character(temp.df[,1])
  pmc.figtitle <- as.character(temp.df[,2])
  pmc.caption <- as.character(temp.df[,3])
  
  ## Prepare df and write to R.object and tsv
  pmc.df <- data.frame(pmc.pmcid, pmc.filename, pmc.number, pmc.figtitle, pmc.papertitle, pmc.caption, pmc.reftext) %>%
    mutate(pmc.figid=paste(pmc.pmcid,pmc.filename, sep = "__")) %>%
    select(pmc.figid,pmc.pmcid, pmc.filename, pmc.number, pmc.figtitle, pmc.papertitle, pmc.caption, pmc.reftext)
  
  pmc.df.all <- rbind(pmc.df.all, pmc.df)
  
  write.table(pmc.df, 
              paste(tsv.out, sep = '/'), 
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

#remDr$goBack()

## At the end of the day...
save(pmc.df.all, file = robj.out)
#load(robj.out)
