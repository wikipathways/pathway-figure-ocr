SELECT figures.filepath, symbols.symbol, xrefs.xref
FROM match_attempts
INNER JOIN figures ON match_attempts.figure_id = figures.id
INNER JOIN symbols ON match_attempts.symbol_id = symbols.id
INNER JOIN lexicon ON symbols.id = lexicon.symbol_id
INNER JOIN xrefs ON xrefs.id = lexicon.xref_id
LEFT OUTER JOIN xrefs_wp_hs ON xrefs.xref = xrefs_wp_hs.xref
WHERE xrefs_wp_hs.xref IS NULL
ORDER BY figures.filepath, symbols.symbol, xrefs.xref;
