---------------------------------------------------------------------------
-- pubmed
---------------------------------------------------------------------------

-- # gene counts, grouped by paper, normalized by paper, species and lexicon
WITH pmcids AS (SELECT DISTINCT papers.pmcid, pmcs.pmid
    FROM papers
    INNER JOIN pmcs ON papers.pmcid = pmcs.pmcid
    LEFT JOIN organism2pubtator ON pmcs.pmid = organism2pubtator.pmid
    WHERE organism2pubtator.organism_id = 9606
        OR organism2pubtator.organism_id = 10090
        OR organism2pubtator.organism_id IS NULL)
SELECT pmcid, count(gene_id) as gene_count
FROM pmcids
INNER JOIN gene2pubmed ON pmcids.pmid = gene2pubmed.pmid
INNER JOIN xrefs ON gene2pubmed.gene_id = CAST(xrefs.xref AS int)
GROUP BY pmcid
ORDER BY gene_count DESC;

-- # unique gene count, normalized by paper and species: 2589
WITH pmcids AS (SELECT DISTINCT papers.pmcid, pmcs.pmid
    FROM papers
    INNER JOIN pmcs ON papers.pmcid = pmcs.pmcid
    LEFT JOIN organism2pubtator ON pmcs.pmid = organism2pubtator.pmid
    WHERE organism2pubtator.organism_id = 9606
        OR organism2pubtator.organism_id = 10090
        OR organism2pubtator.organism_id IS NULL)
SELECT count(DISTINCT gene_id) as gene_count
FROM pmcids
INNER JOIN gene2pubmed ON pmcids.pmid = gene2pubmed.pmid;

-- # unique gene count, normalized by paper and lexicon: 815
WITH pmcids AS (SELECT DISTINCT papers.pmcid, pmcs.pmid
    FROM papers
    INNER JOIN pmcs ON papers.pmcid = pmcs.pmcid
    LEFT JOIN organism2pubtator ON pmcs.pmid = organism2pubtator.pmid)
SELECT count(DISTINCT gene_id) as gene_count
FROM pmcids
INNER JOIN gene2pubmed ON pmcids.pmid = gene2pubmed.pmid
INNER JOIN xrefs ON gene2pubmed.gene_id = CAST(xrefs.xref AS int);

-- ## export above for Venn diagram
COPY (WITH pmcids AS (SELECT DISTINCT papers.pmcid, pmcs.pmid
    FROM papers
    INNER JOIN pmcs ON papers.pmcid = pmcs.pmcid
    LEFT JOIN organism2pubtator ON pmcs.pmid = organism2pubtator.pmid)
    SELECT DISTINCT gene_id as ncbi_gene
    FROM pmcids
    INNER JOIN gene2pubmed ON pmcids.pmid = gene2pubmed.pmid
    INNER JOIN xrefs ON gene2pubmed.gene_id = CAST(xrefs.xref AS int)
) TO '/home/pfocr/4k_pubmed_unique_genes_norm_pl.tsv';

-- # unique gene count, normalized by paper, species and lexicon: 800
WITH pmcids AS (SELECT DISTINCT papers.pmcid, pmcs.pmid
    FROM papers
    INNER JOIN pmcs ON papers.pmcid = pmcs.pmcid
    LEFT JOIN organism2pubtator ON pmcs.pmid = organism2pubtator.pmid
    WHERE organism2pubtator.organism_id = 9606
        OR organism2pubtator.organism_id = 10090
        OR organism2pubtator.organism_id IS NULL)
SELECT count(DISTINCT gene_id) as gene_count
FROM pmcids
INNER JOIN gene2pubmed ON pmcids.pmid = gene2pubmed.pmid
INNER JOIN xrefs ON gene2pubmed.gene_id = CAST(xrefs.xref AS int);

-- ## export above for Venn diagram
COPY (WITH pmcids AS (SELECT DISTINCT papers.pmcid, pmcs.pmid
    FROM papers
    INNER JOIN pmcs ON papers.pmcid = pmcs.pmcid
    LEFT JOIN organism2pubtator ON pmcs.pmid = organism2pubtator.pmid
    WHERE organism2pubtator.organism_id = 9606
        OR organism2pubtator.organism_id = 10090
        OR organism2pubtator.organism_id IS NULL)
    SELECT DISTINCT gene_id as ncbi_gene
    FROM pmcids
    INNER JOIN gene2pubmed ON pmcids.pmid = gene2pubmed.pmid
    INNER JOIN xrefs ON gene2pubmed.gene_id = CAST(xrefs.xref AS int)
) TO '/home/pfocr/4k_pubmed_unique_genes_norm_psl.tsv';

---------------------------------------------------------------------------
-- pubtator
---------------------------------------------------------------------------

-- # gene counts, grouped by paper, normalized by paper, species and lexicon
WITH pmcids AS (SELECT DISTINCT papers.pmcid, pmcs.pmid
    FROM papers
    INNER JOIN pmcs ON papers.pmcid = pmcs.pmcid
    LEFT JOIN organism2pubtator ON pmcs.pmid = organism2pubtator.pmid
    WHERE organism2pubtator.organism_id = 9606
        OR organism2pubtator.organism_id = 10090
        OR organism2pubtator.organism_id IS NULL)
SELECT pmcid, count(gene_id) as gene_count
FROM pmcids
INNER JOIN gene2pubtator ON pmcids.pmid = gene2pubtator.pmid
INNER JOIN xrefs ON gene2pubtator.gene_id = CAST(xrefs.xref as int)
GROUP BY pmcid
ORDER BY gene_count DESC;


-- # unique gene count, normalized by paper: 3886
WITH pmcids AS (SELECT DISTINCT papers.pmcid, pmcs.pmid
    FROM papers
    INNER JOIN pmcs ON papers.pmcid = pmcs.pmcid
    LEFT JOIN organism2pubtator ON pmcs.pmid = organism2pubtator.pmid)
SELECT count(DISTINCT gene_id) as gene_count
FROM pmcids
INNER JOIN gene2pubtator ON pmcids.pmid = gene2pubtator.pmid;


-- # unique gene count, normalized by paper and species: 3215
WITH pmcids AS (SELECT DISTINCT papers.pmcid, pmcs.pmid
    FROM papers
    INNER JOIN pmcs ON papers.pmcid = pmcs.pmcid
    LEFT JOIN organism2pubtator ON pmcs.pmid = organism2pubtator.pmid
    WHERE organism2pubtator.organism_id = 9606
        OR organism2pubtator.organism_id = 10090
        OR organism2pubtator.organism_id IS NULL)
SELECT count(DISTINCT gene_id) as gene_count
FROM pmcids
INNER JOIN gene2pubtator ON pmcids.pmid = gene2pubtator.pmid;


-- # unique gene count, normalized by paper and lexicon: 1851
WITH pmcids AS (SELECT DISTINCT papers.pmcid, pmcs.pmid
    FROM papers
    INNER JOIN pmcs ON papers.pmcid = pmcs.pmcid
    LEFT JOIN organism2pubtator ON pmcs.pmid = organism2pubtator.pmid)
SELECT count(DISTINCT gene_id) as gene_count
FROM pmcids
INNER JOIN gene2pubtator ON pmcids.pmid = gene2pubtator.pmid
INNER JOIN xrefs ON gene2pubtator.gene_id = CAST(xrefs.xref as int);

-- ## export above for Venn diagram
COPY(WITH pmcids AS (SELECT DISTINCT papers.pmcid, pmcs.pmid
    FROM papers
    INNER JOIN pmcs ON papers.pmcid = pmcs.pmcid
    LEFT JOIN organism2pubtator ON pmcs.pmid = organism2pubtator.pmid)
    SELECT DISTINCT gene_id as ncbi_gene
    FROM pmcids
    INNER JOIN gene2pubtator ON pmcids.pmid = gene2pubtator.pmid
    INNER JOIN xrefs ON gene2pubtator.gene_id = CAST(xrefs.xref as int)
) TO '/home/pfocr/4k_pubtator_unique_genes_norm_pl.tsv';


-- # unique gene count, normalized by paper, species and lexicon: 1834
WITH pmcids AS (SELECT DISTINCT papers.pmcid, pmcs.pmid
    FROM papers
    INNER JOIN pmcs ON papers.pmcid = pmcs.pmcid
    LEFT JOIN organism2pubtator ON pmcs.pmid = organism2pubtator.pmid
    WHERE organism2pubtator.organism_id = 9606
        OR organism2pubtator.organism_id = 10090
        OR organism2pubtator.organism_id IS NULL)
SELECT count(DISTINCT gene_id) as gene_count
FROM pmcids
INNER JOIN gene2pubtator ON pmcids.pmid = gene2pubtator.pmid
INNER JOIN xrefs ON gene2pubtator.gene_id = CAST(xrefs.xref as int);

-- ## export above for Venn diagram
COPY(WITH pmcids AS (SELECT DISTINCT papers.pmcid, pmcs.pmid
    FROM papers
    INNER JOIN pmcs ON papers.pmcid = pmcs.pmcid
    LEFT JOIN organism2pubtator ON pmcs.pmid = organism2pubtator.pmid
    WHERE organism2pubtator.organism_id = 9606
        OR organism2pubtator.organism_id = 10090
        OR organism2pubtator.organism_id IS NULL)
    SELECT DISTINCT gene_id as ncbi_gene
    FROM pmcids
    INNER JOIN gene2pubtator ON pmcids.pmid = gene2pubtator.pmid
    INNER JOIN xrefs ON gene2pubtator.gene_id = CAST(xrefs.xref as int)
) TO '/home/pfocr/4k_pubtator_unique_genes_norm_psl.tsv';

---------------------------------------------------------------------------
-- pfocr
---------------------------------------------------------------------------

-- # gene counts, grouped by paper, normalized by paper, species and lexicon
WITH pmcids AS (SELECT DISTINCT papers.id AS paper_id, papers.pmcid, pmcs.pmid
    FROM papers
    INNER JOIN pmcs ON papers.pmcid = pmcs.pmcid
    LEFT JOIN organism2pubtator ON pmcs.pmid = organism2pubtator.pmid
    WHERE organism2pubtator.organism_id = 9606
        OR organism2pubtator.organism_id = 10090
        OR organism2pubtator.organism_id IS NULL)
SELECT pmcid, count(xrefs.xref) as gene_count
FROM pmcids
INNER JOIN figures ON pmcids.paper_id = figures.paper_id
INNER JOIN match_attempts ON figures.id = match_attempts.figure_id
INNER JOIN lexicon ON match_attempts.symbol_id = lexicon.symbol_id
INNER JOIN xrefs ON lexicon.xref_id = xrefs.id
GROUP BY pmcid
ORDER BY gene_count DESC;


-- # unique gene count, normalized by paper and lexicon: 4137
WITH pmcids AS (SELECT DISTINCT papers.id AS paper_id, papers.pmcid, pmcs.pmid
    FROM papers
    INNER JOIN pmcs ON papers.pmcid = pmcs.pmcid)
SELECT count(DISTINCT xrefs.xref) as gene_count
FROM pmcids
INNER JOIN figures ON pmcids.paper_id = figures.paper_id
INNER JOIN match_attempts ON figures.id = match_attempts.figure_id
INNER JOIN lexicon ON match_attempts.symbol_id = lexicon.symbol_id
INNER JOIN xrefs ON lexicon.xref_id = xrefs.id;

-- ## export above for Venn diagram
COPY(
    WITH pmcids AS (SELECT DISTINCT papers.id AS paper_id, papers.pmcid, pmcs.pmid
        FROM papers
        INNER JOIN pmcs ON papers.pmcid = pmcs.pmcid)
    SELECT DISTINCT xrefs.xref as ncbi_gene
    FROM pmcids
    INNER JOIN figures ON pmcids.paper_id = figures.paper_id
    INNER JOIN match_attempts ON figures.id = match_attempts.figure_id
    INNER JOIN lexicon ON match_attempts.symbol_id = lexicon.symbol_id
    INNER JOIN xrefs ON lexicon.xref_id = xrefs.id
) TO '/home/pfocr/4k_pfocr_unique_genes_norm_pl.tsv';


-- # unique gene count, normalized by paper, species and lexicon: 3901
WITH pmcids AS (SELECT DISTINCT papers.id AS paper_id, papers.pmcid, pmcs.pmid
    FROM papers
    INNER JOIN pmcs ON papers.pmcid = pmcs.pmcid
    LEFT JOIN organism2pubtator ON pmcs.pmid = organism2pubtator.pmid
    WHERE organism2pubtator.organism_id = 9606
        OR organism2pubtator.organism_id = 10090
        OR organism2pubtator.organism_id IS NULL)
SELECT count(DISTINCT xrefs.xref) as gene_count
FROM pmcids
INNER JOIN figures ON pmcids.paper_id = figures.paper_id
INNER JOIN match_attempts ON figures.id = match_attempts.figure_id
INNER JOIN lexicon ON match_attempts.symbol_id = lexicon.symbol_id
INNER JOIN xrefs ON lexicon.xref_id = xrefs.id;

-- ## export above for Venn diagram
COPY(WITH pmcids AS (SELECT DISTINCT papers.id AS paper_id, papers.pmcid, pmcs.pmid
    FROM papers
    INNER JOIN pmcs ON papers.pmcid = pmcs.pmcid
    LEFT JOIN organism2pubtator ON pmcs.pmid = organism2pubtator.pmid
    WHERE organism2pubtator.organism_id = 9606
        OR organism2pubtator.organism_id = 10090
        OR organism2pubtator.organism_id IS NULL)
    SELECT DISTINCT xrefs.xref as ncbi_gene
    FROM pmcids
    INNER JOIN figures ON pmcids.paper_id = figures.paper_id
    INNER JOIN match_attempts ON figures.id = match_attempts.figure_id
    INNER JOIN lexicon ON match_attempts.symbol_id = lexicon.symbol_id
    INNER JOIN xrefs ON lexicon.xref_id = xrefs.id
) TO '/home/pfocr/4k_pfocr_unique_genes_norm_psl.tsv';
