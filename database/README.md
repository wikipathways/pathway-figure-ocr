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
First, load each of your source lexicon files to populate a temporary xrefs table, from which a unique selection populates the final xres table.

```sh
create temporary table x (xref text);
create temporary table t (entrez_id text, n_symbol text);
\copy t (entrez_id, n_symbol) from '/home/pfocr/pathway-figure-ocr/lexicon/n_symbol.csv' with (delimiter ',', format csv, header);
insert into x (xref) select entrez_id from t;
drop table t;

create temporary table t (entrez_id text, n_symbol text);
\copy t (entrez_id, n_symbol) from '/home/pfocr/pathway-figure-ocr/lexicon/n_alias_symbol.csv' with (delimiter ',', format csv, header);
insert into x (xref) select entrez_id from t;
drop table t;

create temporary table t (entrez_id text, n_symbol text);
\copy t (entrez_id, n_symbol) from '/home/pfocr/pathway-figure-ocr/lexicon/n_prev_symbol.csv' with (delimiter ',', format csv, header);
insert into x (xref) select entrez_id from t;
drop table t;

create temporary table t (n_symbol text, entrez_id text);
\copy t (n_symbol, entrez_id) from '/home/pfocr/pathway-figure-ocr/lexicon/n_bioentities.csv' with (delimiter ',', format csv, header);
insert into x (xref) select entrez_id from t;
drop table t;

insert into xrefs (xref) select distinct xref from x;
drop table x;
```

Then, load each file again to to populate the lexicon table that references xrefs.id. Symbols should not be unique within a source. Encode the source preference by ascending numeric prefixes for future consideration, e.g., 1_hgnc_symbol.

```sh
create temporary table t (entrez_id text, n_symbol text);
\copy t (entrez_id, n_symbol) from '/home/pfocr/pathway-figure-ocr/lexicon/n_symbol.csv' with (delimiter ',', format csv, header);
insert into lexicon (symbol, xref_id, source) select t.n_symbol, xrefs.id,'1_hgnc_symbol' from t inner join xrefs on xrefs.xref=t.entrez_id;
drop table t;

create temporary table t (entrez_id text, n_symbol text);
\copy t (entrez_id, n_symbol) from '/home/pfocr/pathway-figure-ocr/lexicon/n_alias_symbol.csv' with (delimiter ',', format csv, header);
insert into lexicon (symbol, xref_id, source) select t.n_symbol, xrefs.id,'3_hgnc_alias_symbol' from t inner join xrefs on xrefs.xref=t.entrez_id;
drop table t;

create temporary table t (entrez_id text, n_symbol text);
\copy t (entrez_id, n_symbol) from '/home/pfocr/pathway-figure-ocr/lexicon/n_prev_symbol.csv' with (delimiter ',', format csv, header);
insert into lexicon (symbol, xref_id, source) select t.n_symbol, xrefs.id,'4_hgnc_prev_symbol' from t inner join xrefs on xrefs.xref=t.entrez_id;
drop table t;

create temporary table t (entrez_id text, n_symbol text);
\copy t (n_symbol, entrez_id) from '/home/pfocr/pathway-figure-ocr/lexicon/n_bioentities.csv' with (delimiter ',', format csv, header);
insert into lexicon (symbol, xref_id, source) select t.n_symbol, xrefs.id,'2_bioentities_symbol' from t inner join xrefs on xrefs.xref=t.entrez_id;
drop table t;
```

