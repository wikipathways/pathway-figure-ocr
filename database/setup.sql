/* Run this file as the postgres user:
sudo su - postgres
psql
\i /home/pfocr/pathway-figure-ocr/database/setup.sql
*/

CREATE ROLE pfocr;

CREATE USER ariutta WITH SUPERUSER CREATEDB IN ROLE pfocr;
CREATE DATABASE ariutta WITH owner = ariutta;

CREATE USER apico WITH SUPERUSER CREATEDB IN ROLE pfocr;
CREATE DATABASE apico WITH owner = apico;

CREATE USER khanspers WITH SUPERUSER CREATEDB IN ROLE pfocr;
CREATE DATABASE khanspers WITH owner = khanspers;

CREATE DATABASE pfocr WITH owner = pfocr;

/* switch to pfocr database:
\c pfocr
\i /home/pfocr/pathway-figure-ocr/database/create_tables.sql
*/
