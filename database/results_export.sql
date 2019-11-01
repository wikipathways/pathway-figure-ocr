copy (SELECT pmcid, figures.filepath AS filepath, word , symbols.symbol AS match, source,  xrefs.xref AS entrez, transforms_applied
FROM match_attempts
INNER JOIN figures ON match_attempts.figure_id = figures.id
INNER JOIN papers ON paper_id = papers.id
INNER JOIN symbols ON match_attempts.symbol_id = symbols.id
INNER JOIN lexicon ON symbols.id = lexicon.symbol_id
INNER JOIN xrefs ON xrefs.id = lexicon.xref_id
ORDER BY pmcid, filepath, symbols.symbol, xrefs.xref) 
to '/tmp/results_redo2.csv' with csv;
