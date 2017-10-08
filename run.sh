#!/bin/bash
psql -X -f install.sql

psql -X -f languages/monkey.sql

psql -X -1 -f import_nodetypes.sql

psql -X -1 -f export_nodetypes.sql

psql -X -1 -f languages/monkey/test.sql

while : ; do
    FOO=$(psql -X -t -A -q -c "SET search_path TO soft; SELECT Run_Test(1)");
    if [ $FOO == 'DONE' ]; then
        break
    fi
done
