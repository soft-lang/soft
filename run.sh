#!/bin/bash
psql -X -f install.sql

psql -X -f languages/monkey.sql

rm prog*.pdf

unset FOO
FRAME=10000

# psql -X -t -A -q -c "SET search_path TO soft; SELECT Run(1)"

echo 'digraph {' > prog.dot ; psql -q -E -A -t -X -c 'SET search_path TO soft; SELECT DISTINCT Get_DOT()' >> prog.dot
echo '}' >> prog.dot
FRAME=$((FRAME+1));
dot -Tpdf -o "prog_$FRAME.pdf" prog.dot

while : ; do
    FOO=$(psql -X -t -A -q -c "SET search_path TO soft; SELECT Walk_Tree(1)");
    if [ $FOO == 'f' ]; then
        break
    fi
    echo 'digraph {' > prog.dot ; psql -q -E -A -t -X -c 'SET search_path TO soft; SELECT DISTINCT Get_DOT()' >> prog.dot
    echo '}' >> prog.dot
    FRAME=$((FRAME+1));
    dot -Tpdf -o "prog_$FRAME.pdf" prog.dot
done

open prog*.pdf
