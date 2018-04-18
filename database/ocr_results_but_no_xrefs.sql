WITH hit_counts_by_figure AS (
	SELECT figure_id, COUNT(transformed_word_id) AS hit_count
	FROM match_attempts
	GROUP BY figure_id
)
SELECT figure_id, resolution, figure_number
FROM hit_counts_by_figure
INNER JOIN figures ON hit_counts_by_figure.figure_id = figures.id
WHERE hit_count = 0;
