#!/bin/bash
psql -X -f install.sql
psql -X -f languages/monkey.sql

rm prog_*.gif
rm prog_*.pdf

echo 'digraph {' > prog.dot ; psql -q -E -A -t -X -c 'select distinct soft.Get_DOT()' >> prog.dot
echo '}' >> prog.dot
dot -Tpdf -o prog_0.pdf prog.dot

unset FOO
FRAME=100
while : ; do
    FOO=$(psql -X -t -A -q -c "SELECT soft.Execute_Bonsai_Functions(1)");
    if [ $FOO == 'f' ]; then
        break
    fi
    # echo 'digraph {' > prog.dot ; psql -q -E -A -t -X -c 'select distinct soft.Get_DOT()' >> prog.dot
    # echo '}' >> prog.dot
    # FRAME=$((FRAME+1));
    # dot -Tpdf -o "prog_$FRAME.pdf" prog.dot
done

psql -q -E -A -t -X -c 'UPDATE soft.Nodes SET Visited = 0 WHERE Visited IS NOT NULL;'
psql -q -E -A -t -X -c 'UPDATE soft.Nodes SET Visited = 1 WHERE NodeID = (SELECT NodeID FROM soft.Programs);'

while : ; do
    FOO=$(psql -X -t -A -q -c "SELECT soft.Walk_Tree(1)");
    if [ $FOO == 'f' ]; then
        break
    fi
    echo 'digraph {' > prog.dot ; psql -q -E -A -t -X -c 'select distinct soft.Get_DOT()' >> prog.dot
    echo '}' >> prog.dot
    FRAME=$((FRAME+1));
    dot -Tpdf -o "prog_$FRAME.pdf" prog.dot
done

open prog_*.pdf
