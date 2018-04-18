SELECT xrefs_wp_hs.xref
FROM xrefs_wp_hs
LEFT OUTER JOIN xrefs ON xrefs_wp_hs.xref = xrefs.xref
WHERE xrefs.id IS NULL;
