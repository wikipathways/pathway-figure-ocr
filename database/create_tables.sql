/* as any user that has been granted the pfocr role:
psql pfocr
//*/

SET ROLE pfocr;

CREATE TABLE xrefs (
        id serial PRIMARY KEY,
	xref text UNIQUE NOT NULL
);

CREATE TABLE lexicon (
        id serial PRIMARY KEY,
	/* NOTE: an alias can be the official symbol, a deprecated symbol/name, a synonym, etc. */
	alias text UNIQUE NOT NULL,
	/* TODO: we'll have to watch for any collisions that could result from normalization */
	normalized_alias text UNIQUE NOT NULL,
	xref_id integer REFERENCES xrefs NOT NULL
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

CREATE TABLE runs (
        id serial PRIMARY KEY,
	timestamp timestamp NOT NULL,
	ocr_engine text NOT NULL,
	/* List the step(s) we took when doing the processing.
	   Use the format of a JSON array, e.g.,
	   ["convert INPUT_PATH -rotate "270" OUTPUT_PATH", "ocr", "uppercase"]
	*/
	processing jsonb NOT NULL,
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

CREATE TABLE words (
        id serial PRIMARY KEY,
	word text UNIQUE NOT NULL,
	normalized_word text UNIQUE NOT NULL
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
	word_id integer REFERENCES words NOT NULL,
	position text NOT NULL
);

/* TODO: use CREATE MATERIALIZED VIEW so we don't have to recalculate these views from scratch every time.
https://www.postgresql.org/docs/9.6/static/sql-creatematerializedview.html
*/
CREATE VIEW words_lexicon AS
	SELECT DISTINCT lexicon.id AS lexicon_id, lexicon.xref_id, words.id AS word_id
	FROM words
	INNER JOIN lexicon ON words.normalized_word = lexicon.normalized_alias;

CREATE VIEW figures_xrefs AS
	SELECT figures.path2img, lexicon.alias, words.word, xrefs.xref, runs_figures_words.position, runs.ocr_engine, runs.processing
	FROM figures
	INNER JOIN runs_figures_words ON figures.id = runs_figures_words.figure_id
	INNER JOIN runs ON runs_figures_words.run_id = runs.id
	INNER JOIN words_lexicon ON runs_figures_words.word_id = words_lexicon.word_id
	INNER JOIN words ON words_lexicon.word_id = words.id
	INNER JOIN lexicon ON words_lexicon.lexicon_id = lexicon.id
	INNER JOIN xrefs ON words_lexicon.xref_id = xrefs.id;
