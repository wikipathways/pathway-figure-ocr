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
