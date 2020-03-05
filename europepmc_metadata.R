### EuropePMC

# Cite: Najko Jahn (2017). europepmc: R Interface to the Europe PubMed Central RESTful Web Service. R package version 0.1.4. 
# https://cran.rstudio.com/package=europepmc

## Set working dir. Change accordingly.
setwd("~/Dropbox (Gladstone)/PFOCR_25Years") #AP

library(europepmc)
library(dplyr)

ocr_results <- readRDS("pfocr_figures.rds")
pmc_ids <- unique(ocr_results$pmcid)

## Go through each PMCID in pmc_ids
pmc_info <- lapply(pmc_ids,  function(p){
  
  print(match(p, pmc_ids))
  
  pmc_data <- tryCatch({ epmc_details(ext_id=p, data_src = "pmc")}, 
                       error = function(e) NULL)
  
  if (is.null(pmc_data)){
    return (data.frame(pmcid = p,
                       author.string = "NULL",
                       author.full.list = "NULL",
                       pub.year = 0,
                       pub.print.date = "NULL",
                       journal.title = "NULL",
                       chem.name.list = "NULL",
                       chem.reg.list = "NULL",
                       mesh.topic.desc.list = "NULL",
                       mesh.qual.desc.list = "NULL",
                       mesh.qual.qual.list = "NULL",
                       mesh.qual.major.list = "NULL")
    )
  }else {
    author.string <- pmc_data$basic$authorString
    author.full.list <- tryCatch({as.list(pmc_data$author_details %>% 
                                            transmute(full.string = paste(firstName, initials, lastName, 
                                                                          sep=" ",collapse = " | "))
    )[[1]][1]}, error = function(e) "NULL")
    pub.year <- tryCatch({ pmc_data$journal_info$yearOfPublication}, error = function(e) 0)
    pub.print.date <- pmc_data$journal_info$printPublicationDate
    journal.title <- pmc_data$journal_info$journal.title
    chem.name.list <- paste0(pmc_data$chemical$name, collapse = " | ")
    chem.reg.list <- paste0(pmc_data$chemical$registryNumber, collapse = " | ")
    mesh.topic.desc.list <- paste0(pmc_data$mesh_topic$descriptorName, collapse = " | ")
    mesh.qual.desc.list <- paste0(pmc_data$mesh_qualifiers$descriptorName, collapse = " | ")
    mesh.qual.qual.list <- paste0(pmc_data$mesh_qualifiers$qualifierName, collapse = " | ")
    mesh.qual.major.list <- paste0(pmc_data$mesh_qualifiers$majorTopic_YN, collapse = " | ")
    
    return(tryCatch({data.frame(pmcid = p,
                                author.string = author.string,
                                author.full.list = author.full.list,
                                pub.year = pub.year,
                                pub.print.date = pub.print.date,
                                journal.title = journal.title,
                                chem.name.list = chem.name.list,
                                chem.reg.list = chem.reg.list,
                                mesh.topic.desc.list = mesh.topic.desc.list,
                                mesh.qual.desc.list = mesh.qual.desc.list,
                                mesh.qual.qual.list = mesh.qual.qual.list,
                                mesh.qual.major.list = mesh.qual.major.list)
    }, error = function(e) {
      data.frame(pmcid = p,
                 author.string = "NULL",
                 author.full.list = "NULL",
                 pub.year = 0,
                 pub.print.date = "NULL",
                 journal.title = "NULL",
                 chem.name.list = "NULL",
                 chem.reg.list = "NULL",
                 mesh.topic.desc.list = "NULL",
                 mesh.qual.desc.list = "NULL",
                 mesh.qual.qual.list = "NULL",
                 mesh.qual.major.list = "NULL")
    }))
  }
}) %>% bind_rows()


saveRDS(pmc_info, "tables/europepmc_metadata.RDS")

## Get Authors
pmc_authors <- unname(unlist(lapply(pmc_info$author.full.list, function(a){
  strsplit(a, " | ",fixed=TRUE)
  
})))

pmc_authors.df <- data.frame(authors = pmc_authors) %>% 
  group_by(authors) %>%
  summarise(count = n()) %>%
  arrange(desc(count))

#saveRDS(pmc_authors.df, "tables/pmc_authors.RDS")
write.table(pmc_authors.df, "tables/pfocr_figures_authors.tsv", sep = "\t", row.names = F)

## Restructure for MESH
library(tidyr)
pmc_info_mesh <- select(pmc_info, c(1,9:12))
pmc_info_mesh2 <- pmc_info_mesh %>%
  mutate(topic.descriptorName = strsplit(mesh.topic.desc.list, " | ",fixed=TRUE)) %>%
  unnest(topic.descriptorName) %>%
    select(c(pmcid, topic.descriptorName))

write.table(pmc_info_mesh2, "tables/europepmc_mesh_topics.tsv", sep = "\t", row.names = F)

pmc_info_mesh3 <- pmc_info_mesh %>%
  select(-mesh.topic.desc.list) %>%
  mutate(descriptorName = strsplit(mesh.qual.desc.list, " | ",fixed=TRUE)) %>%
  mutate(qualifier = strsplit(mesh.qual.qual.list, " | ",fixed=TRUE)) %>%
  mutate(major = strsplit(mesh.qual.major.list, " | ",fixed=TRUE)) %>%
  unnest(descriptorName,qualifier,major) %>%
  select(c(pmcid, descriptorName,qualifier,major))
  
write.table(pmc_info_mesh3, "tables/europepmc_mesh_major.tsv", sep = "\t", row.names = F)

## Journal title and dates
pmc_info_pub <- select(pmc_info, c(1,4:6))
write.table(pmc_info_pub, "tables/europepmc_journal_date.tsv", sep = "\t", row.names = F)

## Chemicals
pmc_info_chem <- select(pmc_info, c(1,7:8))
pmc_info_chem2 <- pmc_info_chem %>%
  mutate(chem.name = strsplit(chem.name.list, " | ",fixed=TRUE)) %>%
  mutate(chem.reg = strsplit(chem.reg.list, " | ",fixed=TRUE)) %>%
  unnest(chem.name,chem.reg) %>%
  select(c(1,4,5))
write.table(pmc_info_pub, "tables/europepmc_chemicals.tsv", sep = "\t", row.names = F)


#######################
## MORE DATA...
###############

pmc_tm <- lapply(pmc_ids,  function(p){
  
  pmc_data <- tryCatch({ epmc_tm(ext_id=p, data_src = "pmc")}, 
    error = function(e) {print("Skipped PMC")})
  chem.term.list <- tryCatch({
    chem.term.list <- paste0(pmc_data$chemical$term, collapse = " | ")
  }, error = function(e) {print("Skipped chem.term.list")})
  chem.id.list <- tryCatch({
    paste(pmc_data$chemical$dbName, pmc_data$chemical$dbIdList$dbId, sep=":", collapse = " | ")
  }, error = function(e) {print("Skipped chem.id.list")})
  gene.term.list <- tryCatch({
    paste0(pmc_data$gene_protein$term, collapse = " | ")
  }, error = function(e) {print("Skipped gene.term.list")})
  gene.id.list <- tryCatch({
    paste(pmc_data$gene_protein$dbName, pmc_data$gene_protein$dbIdList$dbId, sep=":", collapse = " | ")
  }, error = function(e) {print("Skipped gene.id.list")})
  disease.list <- tryCatch({
    paste0(pmc_data$disease$term, collapse = " | ")
  }, error = function(e) {print("Skipped disease.list")})
  
  return(data.frame(pmcid = p,
                    chem.term.list = chem.term.list,
                    chem.id.list = chem.id.list,
                    gene.term.list = gene.term.list,
                    gene.id.list = gene.id.list,
                    disease.list = disease.list)
  )
}) %>% bind_rows()

saveRDS(pmc_tm, "tables/europepmc_tmdata.RDS")
