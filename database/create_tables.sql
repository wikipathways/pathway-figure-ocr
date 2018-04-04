CREATE DATABASE pfocr;
\c pfocr;
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
	caption text,
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
	figure_count integer,
	word_count_gross integer,
	word_count_unique integer,
	hit_count_gross integer,
	hit_count_unique integer,
	xref_count_gross integer,
	xref_count_unique integer,
	new_hs_gross integer,
	new_hs_unique integer,
	new_overall_gross integer,
	new_overall_unique integer
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
	PRIMARY KEY (ocr_processor_id, figure_id, transformed_word_id),
	ocr_processor_id integer REFERENCES ocr_processors NOT NULL,
	figure_id integer REFERENCES figures NOT NULL,
	word text NOT NULL CHECK (word <> ''),
	transformed_word_id integer REFERENCES transformed_words,
	transforms_applied text NOT NULL CHECK (transforms_applied <> '')
);

CREATE VIEW figures__xrefs AS SELECT pmcid,
			figures.filepath AS figure_filepath,
			match_attempts.word,
			transformed_words.transformed_word,
			xrefs.xref,
			lexicon.source,
			match_attempts.transforms_applied
		FROM figures
		INNER JOIN papers ON figures.paper_id = papers.id
		INNER JOIN match_attempts ON figures.id = match_attempts.figure_id
		INNER JOIN transformed_words ON match_attempts.transformed_word_id = transformed_words.id
		INNER JOIN symbols ON UPPER(transformed_words.transformed_word) = UPPER(symbols.symbol)
		INNER JOIN lexicon ON symbols.id = lexicon.symbol_id
		INNER JOIN xrefs ON lexicon.xref_id = xrefs.id
		GROUP BY pmcid, figure_filepath, transformed_word, xref, word, source, transforms_applied;

CREATE VIEW stats AS SELECT ocr_processors.engine AS ocr_engine,
		ocr_processors.prepare_image AS image_preprocessor,
		COUNT(DISTINCT papers.pmcid) AS paper_count,
		COUNT(DISTINCT figures.filepath) AS figure_count,
		(SELECT COUNT(DISTINCT CONCAT(word, '\t', figure_id)) FROM match_attempts) AS word_count_gross,
		COUNT(DISTINCT word) AS word_count_unique,
		(SELECT COUNT(DISTINCT CONCAT(transformed_word, '\t', figure_filepath)) FROM figures__xrefs) AS hit_count_gross,
		COUNT(DISTINCT transformed_word) AS hit_count_unique,
		COUNT(DISTINCT xrefs.xref) AS xref_count_unique
	FROM figures
	INNER JOIN papers ON figures.paper_id = papers.id
	INNER JOIN match_attempts ON figures.id = match_attempts.figure_id
	INNER JOIN ocr_processors ON match_attempts.ocr_processor_id = ocr_processors.id
	INNER JOIN transformed_words ON match_attempts.transformed_word_id = transformed_words.id
	INNER JOIN symbols ON UPPER(transformed_words.transformed_word) = UPPER(symbols.symbol)
	INNER JOIN lexicon ON symbols.id = lexicon.symbol_id
	INNER JOIN xrefs ON lexicon.xref_id = xrefs.id
        GROUP BY ocr_engine, image_preprocessor;
