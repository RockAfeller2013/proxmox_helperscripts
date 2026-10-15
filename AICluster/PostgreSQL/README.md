# PostegreSQL

- https://community-scripts.org/categories?category=databases&preview=postgresql
- 172.16.0.228:5432
/usr/local/community-scripts/defaults/postgresql.vars
1. Login after install to root
2. pct list
3. pct enter 103
4. passwd
5. echo "ALTER USER postgres with encrypted password 'password';" | sudo -u postgres psql
6. sudo -u postgres psql -c "ALTER USER user1 CREATEDB;"
7. sudo -u postgres psql -c "CREATE USER username1 WITH ENCRYPTED PASSWORD 'password1'; CREATE DATABASE forgejo OWNER username1;"

```bash

sudo -u postgres psql -c "CREATE USER username1 WITH ENCRYPTED PASSWORD 'password1';"
sudo -u postgres psql -c "CREATE DATABASE forgejo OWNER username1;"

sudo -u postgres psql -c "\du"
sudo -u postgres psql -c "\l"


http://172.16.0.228/adminer
localhost
postgress
password

```
