#!/bin/bash
psql -X -f install.sql

psql -X -f languages/monkey.sql

rm prog*.pdf

unset FOO
FRAME=100
while : ; do
    FOO=$(psql -X -t -A -q -c "SET search_path TO soft; SELECT Walk_Tree(1)");
    if [ $FOO == 'f' ]; then
        break
    fi
    # echo 'digraph {' > prog.dot ; psql -q -E -A -t -X -c 'SET search_path TO soft; SELECT DISTINCT Get_DOT()' >> prog.dot
    # echo '}' >> prog.dot
    # FRAME=$((FRAME+1));
    # dot -Tpdf -o "prog_$FRAME.pdf" prog.dot
done

echo 'digraph {' > prog.dot ; psql -q -E -A -t -X -c 'SET search_path TO soft; SELECT DISTINCT Get_DOT()' >> prog.dot
echo '}' >> prog.dot
FRAME=$((FRAME+1));
dot -Tpdf -o "prog.pdf" prog.dot

rm prog.dot

open prog.pdf
exit

psql -q -E -A -t -X -c 'UPDATE Nodes SET Visited = 0 WHERE Visited IS NOT NULL;'
psql -q -E -A -t -X -c 'UPDATE Nodes SET Visited = 1 WHERE NodeID = (SELECT NodeID FROM Programs);'

while : ; do
    FOO=$(psql -X -t -A -q -c "SELECT Walk_Tree(1)");
    if [ $FOO == 'f' ]; then
        break
    fi
    echo 'digraph {' > prog.dot ; psql -q -E -A -t -X -c 'select distinct Get_DOT()' >> prog.dot
    echo '}' >> prog.dot
    FRAME=$((FRAME+1));
    dot -Tpdf -o "prog_$FRAME.pdf" prog.dot
done

open prog_*.pdf
