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

Don't use this: `sudo systemctl start postgresql`

```sh
sudo su - postgres
psql
```

Exit from psql: `\q`.

```sh
exit
```

## Loading Lexicon

Load each of your source lexicon files in order of preference (use filename numbering, e.g., `1_symbol.csv`) to populate unique `xrefs` and `symbols` tables which are then referenced by the `lexicon` table. A temporary `s` table holds _previously seen_ symbols (i.e., from preferred sources) to exclude redundancy across sources. However, many-to-many mappings are expected _within_ a source, e.g., complexes and families.

```sh
# clear tables before inserting new content
delete from lexicon;
delete from xrefs;
delete from symbols;
alter sequence xrefs_id_seq restart with 1;
alter sequence symbols_id_seq restart with 1;

# populate tables from files
create temporary table s (symbol text);
create temporary table t (entrez_id text, symbol text);
\copy t (entrez_id, symbol) from '/home/pfocr/pathway-figure-ocr/lexicon/1_symbol.csv' with (delimiter ',', format csv, header);
insert into xrefs (xref) select entrez_id from t ON CONFLICT DO NOTHING;
insert into symbols (symbol) select symbol from t ON CONFLICT DO NOTHING;
insert into lexicon (symbol_id, xref_id, source) select symbols.id, xrefs.id,'hgnc_symbol' from t inner join xrefs on xrefs.xref=t.entrez_id inner join symbols on symbols.symbol=t.symbol ON CONFLICT DO NOTHING;
insert into s (symbol) select symbol from t;
drop table t;

create temporary table t (entrez_id text, symbol text);
\copy t (entrez_id, symbol) from '/home/pfocr/pathway-figure-ocr/lexicon/2_bioentities.csv' with (delimiter ',', format csv, header);
insert into xrefs (xref) select entrez_id from t ON CONFLICT DO NOTHING;
insert into symbols (symbol) select symbol from t ON CONFLICT DO NOTHING;
insert into lexicon (symbol_id, xref_id, source) select symbols.id, xrefs.id,'bioentities_symbol' from t inner join xrefs on xrefs.xref=t.entrez_id inner join symbols on symbols.symbol=t.symbol where not exists (select 1 from s where t.symbol = s.symbol) ON CONFLICT DO NOTHING;
insert into s (symbol) select symbol from t;
drop table t;

create temporary table t (entrez_id text, symbol text);
\copy t (entrez_id, symbol) from '/home/pfocr/pathway-figure-ocr/lexicon/3_alias_symbol.csv' with (delimiter ',', format csv, header);
insert into xrefs (xref) select entrez_id from t ON CONFLICT DO NOTHING;
insert into symbols (symbol) select symbol from t ON CONFLICT DO NOTHING;
insert into lexicon (symbol_id, xref_id, source) select symbols.id, xrefs.id,'hgnc_alias_symbol' from t inner join xrefs on xrefs.xref=t.entrez_id inner join symbols on symbols.symbol=t.symbol where not exists (select 1 from s where t.symbol = s.symbol) ON CONFLICT DO NOTHING;
insert into s (symbol) select symbol from t;
drop table t;

create temporary table t (entrez_id text, symbol text);
\copy t (entrez_id, symbol) from '/home/pfocr/pathway-figure-ocr/lexicon/4_prev_symbol.csv' with (delimiter ',', format csv, header);
insert into xrefs (xref) select entrez_id from t ON CONFLICT DO NOTHING;
insert into symbols (symbol) select symbol from t ON CONFLICT DO NOTHING;
insert into lexicon (symbol_id, xref_id, source) select symbols.id, xrefs.id,'hgnc_prev_symbol' from t inner join xrefs on xrefs.xref=t.entrez_id inner join symbols on symbols.symbol=t.symbol where not exists (select 1 from s where t.symbol = s.symbol) ON CONFLICT DO NOTHING;
insert into s (symbol) select symbol from t;
drop table t;
drop table s;
```

### Running Database Queries

Anders found the program [pgManage](https://github.com/pgManage/pgManage) easier to use than psql for interactive queries. You can install it by choosing the appropriate package from [releases](https://github.com/pgManage/pgManage/releases), e.g., `pgManage-10.3.0.dmg` for macOS.

#### Create a tunnel

Set up your ssh connection to rely on your SSH key (use `ssh-copy-id`). Then tunnel local port 3333 to remote port 5432:

```
ssh -L 3333:wikipathways-workspace.gladstone.internal:5432 ariutta@wikipathways-workspace.gladstone.internal
```

Next open `pgManage` and create a connection named `pfocr_plus` with:

* Host `127.0.0.1`
* Port `3333`
* DB Name `pfocr_plus`
* SSL Mode: `prefer`
