SET ROLE pfocr;

CREATE TABLE xrefs (
        id serial PRIMARY KEY,
	xref text UNIQUE NOT NULL
);

CREATE TABLE lexicon (
        id serial PRIMARY KEY,
	symbol text UNIQUE NOT NULL,
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
	timestamp timestamp NOT NULL,
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
        timestamp timestamp NOT NULL,
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

CREATE VIEW words_lexicon AS
	SELECT lexicon.id AS lexicon_id, lexicon.xref_id, words.id AS word_id, lexicon.symbol, words.word, lexicon.source
	FROM words
	INNER JOIN lexicon ON words.word = lexicon.symbol;

CREATE VIEW figures_xrefs AS
	SELECT figures.id AS figure_id, xrefs.id AS xref_id, figures.path2img, lexicon.symbol, words.word, xrefs.xref, runs.ocr_engine, runs.processing
	FROM figures
	INNER JOIN runs_figures_words ON figures.id = runs_figures_words.figure_id
	INNER JOIN runs ON runs_figures_words.run_id = runs.id
	INNER JOIN words_lexicon ON runs_figures_words.word_id = words_lexicon.word_id
	INNER JOIN words ON words_lexicon.word_id = words.id
	INNER JOIN lexicon ON words_lexicon.lexicon_id = lexicon.id
	INNER JOIN xrefs ON words_lexicon.xref_id = xrefs.id;
