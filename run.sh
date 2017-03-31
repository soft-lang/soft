#!/bin/bash
psql -X -f install.sql
psql -X -f languages/monkey.sql

rm prog_*.gif
rm prog_*.pdf

echo 'digraph {' > prog.dot ; psql -q -E -A -t -X -c 'select distinct Get_DOT()' >> prog.dot
echo '}' >> prog.dot
dot -Tpdf -o prog_0.pdf prog.dot

open prog_*.pdf
exit

unset FOO
FRAME=100
while : ; do
    FOO=$(psql -X -t -A -q -c "SELECT Execute_Bonsai_Functions(1)");
    if [ $FOO == 'f' ]; then
        break
    fi
    # echo 'digraph {' > prog.dot ; psql -q -E -A -t -X -c 'select distinct Get_DOT()' >> prog.dot
    # echo '}' >> prog.dot
    # FRAME=$((FRAME+1));
    # dot -Tpdf -o "prog_$FRAME.pdf" prog.dot
done

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
