# ###########################
# Curate PFOCR Fetch Results 
# ###########################

# 1. Read in Robj of PFOCR fetch results: "pmc.df.all" (from pfocr_fetch.R)
# 2. Optionally add fig.type column if missing
# 3. Loop through figures and interactively curate
# 4. Save "pmc.df.curated" and tsv (e.g, for OCR and pfocr2ndex.R)

library(RCy3)
library(dplyr)
library(jpeg)

## Set working dir to location with Robj and tsv to be pruned 
setwd("/git/wikipathways/pathway-figure-ocr/20191020")

## Read in PFOCR results
load("pmc.df.all.Rdata")
if (is.null(pmc.df.all$fig.type))
  pmc.df.all[,"fig.type"] <- character(0)

## Screen fetch results to prepare a pmc.df.curated
dapply(pmc.df.all[1:5,], function(df) {  # subset for rounds, e.g., fig.list[1001:length(fig.list)]
  f <- df$pmc.figid
  
  if (!grepl("^PMC\\d+__.*\.jpg$",f)){
    print(paste("Skipping",f)) #skip garbage entries
    next
  }
  print(paste("Presenting ",f,"..."))
  
  # Retrieve images from PMC or from local fir 
  f.path<-paste0('images/',f)
  ## FROM PMC
  figure_link <- paste0("https://www.ncbi.nlm.nih.gov/pmc/articles/",df$pmc.pmcid,"/bin/",df$pmc.filename)
  download.file(figure_link,f.path, mode = 'wb')
  
  # Display image for review 
  jj <- readJPEG(f.path,native=TRUE)
  plot(0:1,0:1,type="n",ann=FALSE,axes=FALSE)
  rasterImage(jj,0,0,1,1)
  ## enter or '-enter (Note: that actually produced pair of single quotes)
  res <- readline(prompt="Press [enter] to skip or [']-[enter] to keep")
  
  # Build clean df and copy clean collection
  ft <- "other"
  if (res == "''"){
    ft <- "pw"
    print(paste("*** SAVED ***"))
  } else {
    print(paste(". rejected ."))
  }
  pmc.df.all<- pmc.df.all %>% mutate_if(pmc.figid==f, fig.type=ft)
  f.path.curated <- paste('images',ft,f, sep = '/')
  file.copy(f.path,f.path.curated)
  
})

fig.list.clean <- unique(pfocr.clean$figure)  #optional for debugging and stats

## Save "clean" csv for pfocr2ndex.R
write.csv(pfocr.clean, "results-clean-1000.csv", row.names = F)