#!/bin/bash
# In another terminal, run:
# while true ; do PGUSER=pgcronjob PGDATABASE=$USER ./pgcronjob ; psql -X -f install.sql ; done
killall perl # to kill pgcronjob
sleep 1
./install &&
cp languages/monkey/node_types.csv node_types.csv &&
cp languages/monkey/error_types.csv error_types.csv &&
psql -q -X -f languages/monkey.sql &&
mv node_types.csv languages/monkey/node_types.csv &&
mv error_types.csv languages/monkey/error_types.csv &&
while true ; do psql -c "SELECT OK, COUNT(*) FROM View_Tests GROUP BY OK;"; psql -c "SELECT * FROM View_Tests WHERE NOT OK;"; sleep 1; done
