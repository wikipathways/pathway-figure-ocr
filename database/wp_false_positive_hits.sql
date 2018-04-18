SELECT DISTINCT xrefs.xref, symbols.symbol
FROM (SELECT xref FROM figures__xrefs EXCEPT SELECT xref FROM xrefs_wp_hs) as xrefs_not_in_wp_hs
INNER JOIN xrefs ON xrefs_not_in_wp_hs.xref = xrefs.xref
INNER JOIN lexicon ON xrefs.id = lexicon.xref_id
INNER JOIN symbols ON lexicon.symbol_id = symbols.id;
