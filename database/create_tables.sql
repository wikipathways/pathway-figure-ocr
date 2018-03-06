SET ROLE pfocr;

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

CREATE TABLE papers (
        id serial PRIMARY KEY,
	pmcid text UNIQUE NOT NULL CHECK (pmcid <> ''),
	title text,
	url text,
	abstract text,
	date date,
	journal text
);

CREATE TABLE figures (
        id serial PRIMARY KEY,
	paper_id integer REFERENCES papers NOT NULL,
	filepath text UNIQUE NOT NULL CHECK (filepath <> ''),
	figure_number text NOT NULL CHECK (figure_number <> ''),
	caption text
);

CREATE TABLE batches (
        id serial PRIMARY KEY,
	timestamp timestamp DEFAULT CURRENT_TIMESTAMP,
	paper_count integer,
	figure_count integer,
	total_text_gross integer,
	total_text_unique integer,
	total_xrefs_gross integer,
	total_xrefs_unique integer,
	total_hits_gross integer,
	total_hits_unique integer,
	total_new_hs_gross integer,
	total_new_hs_unique integer,
	total_new_overall_gross integer,
	total_new_overall_unique integer
);

CREATE TABLE ocr_processors (
        id serial PRIMARY KEY,
	created timestamp DEFAULT CURRENT_TIMESTAMP,
        engine text NOT NULL CHECK (engine <> ''),
        prepare_image text NOT NULL CHECK (prepare_image <> ''),
        perform_ocr text NOT NULL CHECK (perform_ocr <> ''),
	hash text UNIQUE NOT NULL CHECK (hash <> '')
);

CREATE TABLE batches__ocr_processors (
	PRIMARY KEY (batch_id, ocr_processor_id),
	batch_id integer REFERENCES batches NOT NULL,
	ocr_processor_id integer REFERENCES ocr_processors NOT NULL
); 

CREATE TABLE words (
        id serial PRIMARY KEY,
	word text UNIQUE NOT NULL CHECK (word <> '')
);

CREATE TABLE ocr_processors__figures (
	PRIMARY KEY (ocr_processor_id, figure_id),
	ocr_processor_id integer REFERENCES ocr_processors NOT NULL,
	figure_id integer REFERENCES figures NOT NULL,
	result jsonb
); 

CREATE TABLE ocr_processors__figures__words (
	PRIMARY KEY (ocr_processor_id, figure_id, word_id),
	ocr_processor_id integer REFERENCES ocr_processors NOT NULL,
	figure_id integer REFERENCES figures NOT NULL,
	word_id integer REFERENCES words NOT NULL
);

CREATE VIEW figures__xrefs AS SELECT pmcid, figures.filepath AS figure_filepath, words.word, xrefs.xref
	FROM figures
	INNER JOIN papers ON figures.paper_id = papers.id
	INNER JOIN ocr_processors__figures__words ON figures.id = ocr_processors__figures__words.figure_id
	INNER JOIN words ON ocr_processors__figures__words.word_id = words.id
	INNER JOIN symbols ON words.word = symbols.symbol
	INNER JOIN lexicon ON symbols.id = lexicon.symbol_id
	INNER JOIN xrefs ON lexicon.xref_id = xrefs.id
        GROUP BY pmcid, figure_filepath, word, xref;

CREATE VIEW stats AS SELECT ocr_processors.engine AS ocr_engine,
		ocr_processors.prepare_image AS image_preprocessor,
		COUNT(DISTINCT papers.pmcid) AS paper_count,
		COUNT(DISTINCT figures.filepath) AS figure_count,
		(SELECT COUNT(DISTINCT CONCAT(word_id, '\t', figure_id)) FROM ocr_processors__figures__words) AS hit_count_gross,
		COUNT(DISTINCT words.word) AS hit_count_uniq,
		COUNT(DISTINCT xrefs.xref) AS xref_count_uniq
	FROM figures
	INNER JOIN papers ON figures.paper_id = papers.id
	INNER JOIN ocr_processors__figures__words ON figures.id = ocr_processors__figures__words.figure_id
	INNER JOIN ocr_processors ON ocr_processors__figures__words.ocr_processor_id = ocr_processors.id
	INNER JOIN words ON ocr_processors__figures__words.word_id = words.id
	INNER JOIN symbols ON words.word = symbols.symbol
	INNER JOIN lexicon ON symbols.id = lexicon.symbol_id
	INNER JOIN xrefs ON lexicon.xref_id = xrefs.id
        GROUP BY ocr_engine, image_preprocessor;
