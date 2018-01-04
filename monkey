#!/bin/bash
./install &&
cp languages/monkey/node_types.csv node_types.csv &&
cp languages/monkey/error_types.csv error_types.csv &&
psql -q -X -f languages/monkey.sql &&
mv node_types.csv languages/monkey/node_types.csv &&
mv error_types.csv languages/monkey/error_types.csv &&
while true ; do clear ; \
psql -c "SELECT Language, Phase, OK, COUNT(*) FROM View_Tests GROUP BY 1,2,3 ORDER BY 1,2,3;" ; \
psql -c "SELECT * FROM View_Tests WHERE NOT OK ORDER BY TestID;" ; \
psql -c "SELECT pid,application_name,wait_event_type,wait_event,state,query FROM pg_stat_activity ORDER BY pid;" ; \
sleep 5; done
