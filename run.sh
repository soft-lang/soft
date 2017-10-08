#!/bin/bash
psql -q -X -f install.sql

psql -q -X -f languages/monkey.sql

psql -q -X -1 -v ON_ERROR_STOP=1 -f load_nodetypes.sql

psql -q -X -1 -f languages/monkey/test.sql

while : ; do
    FOO=$(psql -X -t -A -q -c "SET search_path TO soft; SELECT Run_Test(1)");
    if [ $FOO == 'DONE' ]; then
        break
    fi
done
