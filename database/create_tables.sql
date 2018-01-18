SET ROLE pfocr;

CREATE TABLE xrefs (
        id serial PRIMARY KEY,
	xref text UNIQUE NOT NULL
);

CREATE TABLE symbols (
        id serial PRIMARY KEY,
	symbol text UNIQUE NOT NULL
);

CREATE TABLE lexicon (
        PRIMARY KEY (symbol_id, xref_id),
	symbol_id integer REFERENCES symbols NOT NULL,
	xref_id integer REFERENCES xrefs NOT NULL,
	source text 
);

CREATE TABLE papers (
        id serial PRIMARY KEY,
	pmcid text UNIQUE NOT NULL,
	title text,
	url text,
	abstract text,
	date date,
	journal text
);

CREATE TABLE figures (
        id serial PRIMARY KEY,
	paper_id integer REFERENCES papers NOT NULL,
	path2img text UNIQUE NOT NULL,
	figure_number text NOT NULL,
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

CREATE TABLE runs (
        id serial PRIMARY KEY,
	timestamp timestamp DEFAULT CURRENT_TIMESTAMP,
	batch_id integer REFERENCES batches NOT NULL,
        ocr_engine text NOT NULL,
        processing jsonb NOT NULL
);

CREATE TABLE words (
        id serial PRIMARY KEY,
	word text UNIQUE NOT NULL
);

CREATE TABLE runs_figures (
	PRIMARY KEY (run_id, figure_id),
	run_id integer REFERENCES runs NOT NULL,
	figure_id integer REFERENCES figures NOT NULL,
	result jsonb
); 

CREATE TABLE runs_figures_words (
	PRIMARY KEY (run_id, figure_id, word_id),
	run_id integer REFERENCES runs NOT NULL,
	figure_id integer REFERENCES figures NOT NULL,
	word_id integer REFERENCES words NOT NULL
);

CREATE VIEW words_lexicon AS SELECT words.id AS word_id, words.word, symbols.symbol, xrefs.id AS xref_id, xrefs.xref, lexicon.source
	FROM words
	INNER JOIN symbols ON words.word = symbols.symbol
	INNER JOIN lexicon ON symbols.id = lexicon.symbol_id
	INNER JOIN xrefs ON lexicon.xref_id = xrefs.id;

CREATE VIEW figures_xrefs AS SELECT figures.id AS figure_id, words_lexicon.xref, words_lexicon.symbol, figures.path2img, runs_figures_words.run_id
	FROM figures
	INNER JOIN runs_figures_words ON figures.id = runs_figures_words.figure_id
	INNER JOIN words_lexicon ON runs_figures_words.word_id = words_lexicon.word_id;

