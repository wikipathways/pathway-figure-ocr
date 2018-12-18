\c pfocr2018121717;

COPY organism_names(
        organism_id,
	name,
	name_unique,
	name_class
) FROM '/home/pfocr/organism_names.tsv' DELIMITER E'\t' CSV; 

COPY gene2pubmed(organism_id, gene_id, pmid) FROM '/home/pfocr/gene2pubmed.tsv' DELIMITER E'\t' CSV HEADER;
COPY organism2pubmed(organism_id, pmid) FROM '/home/pfocr/organism2pubmed.tsv' DELIMITER E'\t' CSV HEADER;

COPY gene2pubtator(pmid, gene_id) FROM '/home/pfocr/gene2pubtator_uniq.tsv' DELIMITER E'\t' CSV HEADER;
COPY organism2pubtator(pmid, organism_id) FROM '/home/pfocr/organism2pubtator_uniq.tsv' DELIMITER E'\t' CSV HEADER;
 
COPY pmcs(
        journal,
        issn,
        eissn,
        year,
        volume,
        issue,
        page,
        doi,
        pmcid,
        pmid,
        manuscript_id,
        release_date
) FROM '/home/pfocr/PMC-ids.unix.csv' DELIMITER ',' CSV HEADER; 
