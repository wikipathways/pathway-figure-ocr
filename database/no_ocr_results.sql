SELECT figures.id, resolution, figure_number
FROM figures
LEFT OUTER JOIN match_attempts ON figures.id = match_attempts.figure_id
WHERE match_attempts.id IS NULL;
