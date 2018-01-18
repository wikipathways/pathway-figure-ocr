## Installation

```sh
adduser postgres
nix-setup-user postgres
sudo mkdir /home/postgres/data
sudo chown -R postgres:pfocr /home/postgres/data
sudo chmod -R 0700 /home/postgres/data
```

```sh
sudo su - postgres
nix-env -iA nixos.postgresql
initdb data
exit
```

Create a file like the one currently found at /etc/systemd/system/postgresql.service

```sh
sudo systemctl enable postgresql
sudo systemctl start postgresql
```

```sh
sudo su - postgres
psql
```

Exit from psql: `\q`.

```sh
exit
```

## Loading Lexicon 
Load each of your source lexicon files (in order of preference) to populate a unique xrefs and symbols tables which are then referenced by the lexicon table. A temporary s table holds *previously seen* symbols from preferred sources to exclude redundancy across sources. However, many-to-many mappings are expected *within* a source, e.g., complexes and families.

```sh
create temporary table s (symbol text);
create temporary table t (entrez_id text, n_symbol text);
\copy t (entrez_id, n_symbol) from '/home/pfocr/pathway-figure-ocr/lexicon/1_n_symbol.csv' with (delimiter ',', format csv, header);
insert into xrefs (xref) select entrez_id from t ON CONFLICT DO NOTHING;
insert into symbols (symbol) select n_symbol from t ON CONFLICT DO NOTHING;
insert into lexicon (symbol_id, xref_id, source) select symbols.id, xrefs.id,'hgnc_symbol' from t inner join xrefs on xrefs.xref=t.entrez_id inner join symbols on symbols.symbol=t.n_symbol ON CONFLICT DO NOTHING;
insert into s (symbol) select n_symbol from t;
drop table t;

create temporary table t (entrez_id text, n_symbol text);
\copy t (n_symbol, entrez_id) from '/home/pfocr/pathway-figure-ocr/lexicon/2_n_bioentities.csv' with (delimiter ',', format csv, header);
insert into xrefs (xref) select entrez_id from t ON CONFLICT DO NOTHING;
insert into symbols (symbol) select n_symbol from t ON CONFLICT DO NOTHING;
insert into lexicon (symbol_id, xref_id, source) select symbols.id, xrefs.id,'bioentities_symbol' from t inner join xrefs on xrefs.xref=t.entrez_id inner join symbols on symbols.symbol=t.n_symbol where not exists (select 1 from s where t.n_symbol = s.symbol) ON CONFLICT DO NOTHING;
insert into s (symbol) select n_symbol from t;
drop table t;

create temporary table t (entrez_id text, n_symbol text);
\copy t (entrez_id, n_symbol) from '/home/pfocr/pathway-figure-ocr/lexicon/3_n_alias_symbol.csv' with (delimiter ',', format csv, header);
insert into xrefs (xref) select entrez_id from t ON CONFLICT DO NOTHING;
insert into symbols (symbol) select n_symbol from t ON CONFLICT DO NOTHING;
insert into lexicon (symbol_id, xref_id, source) select symbols.id, xrefs.id,'hgnc_alias_symbol' from t inner join xrefs on xrefs.xref=t.entrez_id inner join symbols on symbols.symbol=t.n_symbol where not exists (select 1 from s where t.n_symbol = s.symbol) ON CONFLICT DO NOTHING;
insert into s (symbol) select n_symbol from t;
drop table t;

create temporary table t (entrez_id text, n_symbol text);
\copy t (entrez_id, n_symbol) from '/home/pfocr/pathway-figure-ocr/lexicon/4_n_prev_symbol.csv' with (delimiter ',', format csv, header);
insert into xrefs (xref) select entrez_id from t ON CONFLICT DO NOTHING;
insert into symbols (symbol) select n_symbol from t ON CONFLICT DO NOTHING;
insert into lexicon (symbol_id, xref_id, source) select symbols.id, xrefs.id,'hgnc_prev_symbol' from t inner join xrefs on xrefs.xref=t.entrez_id inner join symbols on symbols.symbol=t.n_symbol where not exists (select 1 from s where t.n_symbol = s.symbol) ON CONFLICT DO NOTHING;
insert into s (symbol) select n_symbol from t;
drop table t;
drop table s;
```

