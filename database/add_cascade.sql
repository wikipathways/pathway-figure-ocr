/*\c pfocr20191102_93k;*/
/*SET ROLE pfocr;*/

ALTER TABLE figures
DROP CONSTRAINT figures_paper_id_fkey,
ADD CONSTRAINT figures_paper_id_fkey
   FOREIGN KEY (paper_id)
   REFERENCES papers(id)
   ON DELETE CASCADE;

ALTER TABLE summaries
DROP CONSTRAINT summaries_matcher_id_fkey,
ADD CONSTRAINT summaries_matcher_id_fkey
   FOREIGN KEY (matcher_id)
   REFERENCES matchers(id)
   ON DELETE CASCADE;

ALTER TABLE summaries
DROP CONSTRAINT summaries_ocr_processor_id_fkey,
ADD CONSTRAINT summaries_ocr_processor_id_fkey
   FOREIGN KEY (ocr_processor_id)
   REFERENCES ocr_processors(id)
   ON DELETE CASCADE;

ALTER TABLE ocr_processors__figures
DROP CONSTRAINT ocr_processors__figures_ocr_processor_id_fkey,
ADD CONSTRAINT ocr_processors__figures_ocr_processor_id_fkey
   FOREIGN KEY (ocr_processor_id)
   REFERENCES ocr_processors(id)
   ON DELETE CASCADE;

ALTER TABLE ocr_processors__figures
DROP CONSTRAINT ocr_processors__figures_figure_id_fkey,
ADD CONSTRAINT ocr_processors__figures_figure_id_fkey
   FOREIGN KEY (figure_id)
   REFERENCES figures(id)
   ON DELETE CASCADE;

ALTER TABLE match_attempts
DROP CONSTRAINT match_attempts_ocr_processor_id_fkey,
ADD CONSTRAINT match_attempts_ocr_processor_id_fkey
   FOREIGN KEY (ocr_processor_id)
   REFERENCES ocr_processors(id)
   ON DELETE CASCADE;

ALTER TABLE match_attempts
DROP CONSTRAINT match_attempts_matcher_id_fkey,
ADD CONSTRAINT match_attempts_matcher_id_fkey
   FOREIGN KEY (matcher_id)
   REFERENCES matchers(id)
   ON DELETE CASCADE;

ALTER TABLE match_attempts
DROP CONSTRAINT match_attempts_figure_id_fkey,
ADD CONSTRAINT match_attempts_figure_id_fkey
   FOREIGN KEY (figure_id)
   REFERENCES figures(id)
   ON DELETE CASCADE;

ALTER TABLE match_attempts
DROP CONSTRAINT match_attempts_transformed_word_id_fkey,
ADD CONSTRAINT match_attempts_transformed_word_id_fkey
   FOREIGN KEY (transformed_word_id)
   REFERENCES transformed_words(id)
   ON DELETE CASCADE;

ALTER TABLE match_attempts
DROP CONSTRAINT match_attempts_symbol_id_fkey,
ADD CONSTRAINT match_attempts_symbol_id_fkey
   FOREIGN KEY (symbol_id)
   REFERENCES symbols(id)
   ON DELETE CASCADE;
