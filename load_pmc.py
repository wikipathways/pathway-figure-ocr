from pathlib import Path
import psycopg2
import re

pmcid_re = re.compile('^(PMC\d+)__(.+)')

conn = psycopg2.connect("dbname=pfocr")
cur = conn.cursor()

p = Path(Path(__file__).parent)
figure_paths = list(p.glob('../pmc/20150501/images_pruned/*.jpg'))
for figure_path in figure_paths:
	path2img = str(figure_path.resolve())
	name_components = pmcid_re.match(figure_path.stem)
	if name_components:
		pmcid = name_components[1]
		figure_number = name_components[2]
		#print(pmcid)
		#print(figure_number)
		cur.execute("INSERT INTO papers (pmcid) VALUES (%s) ON CONFLICT DO NOTHING;", (pmcid, ))
		cur.execute("INSERT INTO figures (path2img, figure_number, paper_id) VALUES (%s, %s, (SELECT id FROM papers WHERE pmcid=%s)) ON CONFLICT DO NOTHING;", (path2img, figure_number, pmcid))

#cur.execute("SELECT * FROM papers;")
#cur.fetchone()
conn.commit()
cur.close()
