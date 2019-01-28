CREATE DATABASE pfocr2018121717;
\c pfocr2018121717;
/*SET ROLE pfocr;*/

CREATE TABLE organism_names(
        organism_id integer NOT NULL,
	name text,
	name_unique text UNIQUE,
	name_class text
);

CREATE TABLE xrefs (
        id serial PRIMARY KEY,
	xref text UNIQUE NOT NULL CHECK (xref <> '')
);

CREATE TABLE xrefs_wp_hs (
	xref text UNIQUE NOT NULL CHECK (xref <> '')
);

CREATE TABLE symbols (
        id serial PRIMARY KEY,
	symbol text UNIQUE NOT NULL CHECK (symbol <> '')
);

CREATE TABLE lexicon (
        PRIMARY KEY (symbol_id, xref_id),
	symbol_id integer REFERENCES symbols NOT NULL,
	xref_id integer REFERENCES xrefs NOT NULL,
	source text 
);

CREATE TABLE gene2pubmed (
	PRIMARY KEY (gene_id, pmid),
	organism_id integer NOT NULL,
	gene_id integer NOT NULL,
	pmid integer NOT NULL
);

CREATE TABLE organism2pubmed (
	PRIMARY KEY (organism_id, pmid),
	organism_id integer NOT NULL,
	pmid integer NOT NULL
);

CREATE TABLE organism2pubtator (
	PRIMARY KEY (pmid, organism_id),
	pmid integer NOT NULL,
	organism_id integer NOT NULL,
	mentions text,
	resource text
);

/* PMID	NCBI_Gene	Mentions	Resource */
CREATE TABLE gene2pubtator (
	PRIMARY KEY (pmid, gene_id),
	pmid integer NOT NULL,
	gene_id integer NOT NULL,
	mentions text,
	resource text
);

CREATE TABLE pmcs (
        pmcid text PRIMARY KEY,
        pmid integer UNIQUE,
        journal text CHECK (journal <> ''),
        title text,
        abstract text,
        issn text,
        eissn text,
        year integer,
        volume text,
        issue text,
        page text,
        doi text,
        manuscript_id text,
        release_date text
);

CREATE TABLE papers (
        id serial PRIMARY KEY,
        url text,
	date date,
	organism_id integer NOT NULL,
        pmcid text REFERENCES pmcs
);      

CREATE TABLE figures (
        id serial PRIMARY KEY,
	paper_id integer REFERENCES papers NOT NULL,
	filepath text UNIQUE NOT NULL CHECK (filepath <> ''),
	figure_number text NOT NULL CHECK (figure_number <> ''),
	caption text,
	resolution integer,
	hash text
);

CREATE TABLE ocr_processors (
        id serial PRIMARY KEY,
	created timestamp DEFAULT CURRENT_TIMESTAMP,
        engine text NOT NULL CHECK (engine <> ''),
        prepare_image text NOT NULL CHECK (prepare_image <> ''),
        perform_ocr text NOT NULL CHECK (perform_ocr <> ''),
	hash text UNIQUE NOT NULL CHECK (hash <> '')
);

CREATE TABLE matchers (
        id serial PRIMARY KEY,
	created timestamp DEFAULT CURRENT_TIMESTAMP,
	transforms jsonb UNIQUE NOT NULL
);

CREATE TABLE summaries (
	PRIMARY KEY (ocr_processor_id, matcher_id),
	matcher_id integer REFERENCES matchers NOT NULL,
	ocr_processor_id integer REFERENCES ocr_processors NOT NULL,
	timestamp timestamp DEFAULT CURRENT_TIMESTAMP,
	paper_count integer,
	nonwordless_paper_count integer,
	figure_count integer,
	nonwordless_figure_count integer,
	word_count_gross integer,
	word_count_unique integer,
	hit_count_gross integer,
	hit_count_unique integer,
	xref_count_gross integer,
	xref_count_unique integer,
	xref_not_in_wp_hs_count integer
);

CREATE TABLE ocr_processors__figures (
	PRIMARY KEY (ocr_processor_id, figure_id),
	ocr_processor_id integer REFERENCES ocr_processors NOT NULL,
	figure_id integer REFERENCES figures NOT NULL,
	result jsonb
); 

CREATE TABLE transformed_words (
        id serial PRIMARY KEY,
	transformed_word text UNIQUE NOT NULL CHECK (transformed_word <> '')
);

CREATE TABLE match_attempts (
	id serial PRIMARY KEY,
	ocr_processor_id integer REFERENCES ocr_processors NOT NULL,
	matcher_id integer REFERENCES matchers NOT NULL,
	transforms_applied text NOT NULL CHECK (transforms_applied <> ''),
	figure_id integer REFERENCES figures NOT NULL,
	word text NOT NULL CHECK (word <> ''),
	transformed_word_id integer REFERENCES transformed_words,
	symbol_id integer REFERENCES symbols,
	UNIQUE (ocr_processor_id, matcher_id, figure_id, transformed_word_id)
);

CREATE UNIQUE INDEX match_attempts_null_unique_idx
ON match_attempts (ocr_processor_id, matcher_id, figure_id, transformed_word_id)
WHERE transformed_word_id IS NULL;

CREATE VIEW figures__xrefs AS WITH hgnc AS (
	SELECT xref_id, symbol
		FROM lexicon
		INNER JOIN symbols ON lexicon.symbol_id = symbols.id
		WHERE source = 'hgnc_symbol')
	SELECT pmcid,
		figures.filepath AS figure_filepath,
		match_attempts.word,
		transformed_words.transformed_word,
		symbols.symbol,
		hgnc.symbol as hgnc_symbol,
		xrefs.xref,
		lexicon.source,
		match_attempts.transforms_applied
                FROM match_attempts
                INNER JOIN figures ON match_attempts.figure_id = figures.id
                INNER JOIN papers ON figures.paper_id = papers.id
                INNER JOIN transformed_words ON match_attempts.transformed_word_id = transformed_words.id
                INNER JOIN symbols ON match_attempts.symbol_id = symbols.id
                INNER JOIN lexicon ON symbols.id = lexicon.symbol_id
                INNER JOIN xrefs ON lexicon.xref_id = xrefs.id
                INNER JOIN hgnc ON lexicon.xref_id = hgnc.xref_id
                GROUP BY pmcid, figure_filepath, transformed_word, symbols.symbol, xref, hgnc.symbol, word, source, transforms_applied;

CREATE VIEW stats AS SELECT ocr_processors.engine AS ocr_engine,
		ocr_processors.prepare_image AS image_preprocessor,
		(SELECT COUNT(id) FROM papers) AS paper_count,
		COUNT(DISTINCT papers.pmcid) AS nonwordless_paper_count,
		(SELECT COUNT(id) FROM figures) AS figure_count,
		COUNT(DISTINCT figures.filepath) AS nonwordless_figure_count,
		(SELECT COUNT(DISTINCT CONCAT(word, '\t', figure_id)) FROM match_attempts) AS word_count_gross,
		COUNT(DISTINCT word) AS word_count_unique,
		(SELECT COUNT(DISTINCT CONCAT(transformed_word, '\t', figure_filepath)) FROM figures__xrefs) AS hit_count_gross,
		(SELECT COUNT(DISTINCT transformed_word) FROM figures__xrefs) AS hit_count_unique,
		(SELECT COUNT(DISTINCT CONCAT(xref, '\t', figure_filepath)) FROM figures__xrefs) AS xref_count_gross,
		(SELECT COUNT(DISTINCT xref) FROM figures__xrefs) AS xref_count_unique,
		(SELECT COUNT(DISTINCT xref) FROM (SELECT xref FROM figures__xrefs EXCEPT SELECT xref FROM xrefs_wp_hs) as xrefs_not_in_wp_hs) as xref_not_in_wp_hs_count
	FROM figures
	INNER JOIN papers ON figures.paper_id = papers.id
	INNER JOIN match_attempts ON figures.id = match_attempts.figure_id
	INNER JOIN ocr_processors ON match_attempts.ocr_processor_id = ocr_processors.id
	INNER JOIN transformed_words ON match_attempts.transformed_word_id = transformed_words.id
	INNER JOIN symbols ON match_attempts.symbol_id = symbols.id
	INNER JOIN lexicon ON symbols.id = lexicon.symbol_id
	INNER JOIN xrefs ON lexicon.xref_id = xrefs.id
        GROUP BY ocr_engine, image_preprocessor;
