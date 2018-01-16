/* as postgres user:
psql
*/

CREATE ROLE pfocr;
CREATE DATABASE pfocr;
ALTER DATABASE pfocr OWNER TO pfocr;

CREATE USER ariutta WITH CREATEDB IN ROLE pfocr;
CREATE DATABASE ariutta;
ALTER DATABASE ariutta OWNER TO ariutta;

CREATE USER apico WITH CREATEDB IN ROLE pfocr;
CREATE DATABASE apico;
ALTER DATABASE apico OWNER TO apico;

CREATE USER khanspers WITH CREATEDB IN ROLE pfocr;
CREATE DATABASE khanspers;
ALTER DATABASE khanspers OWNER TO khanspers;

/* switch to pfocr database:
\c pfocr
or
\q
psql pfocr
//*/
