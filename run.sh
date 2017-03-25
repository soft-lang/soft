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
    FOO=$(psql -X -t -A -q -c "SELECT soft.Execute_Visit_Functions(1)");
    if [ $FOO == 'f' ]; then
        break
    fi
    echo 'digraph {' > prog.dot ; psql -q -E -A -t -X -c 'select distinct soft.Get_DOT()' >> prog.dot
    echo '}' >> prog.dot
    FRAME=$((FRAME+1));
    dot -Tpdf -o "prog_$FRAME.pdf" prog.dot
done

open prog_0.pdf
exit;

psql -q -E -A -t -X -c 'UPDATE soft.Nodes SET Visited = Visited + 1 WHERE NodeID = (SELECT NodeID FROM soft.Programs)'

# psql -q -E -A -t -X -c 'SELECT soft.Free_Variables()'

psql -q -E -A -t -X -c 'UPDATE soft.Nodes SET Visited = 0;'

psql -q -E -A -t -X -c 'UPDATE soft.Nodes SET Visited = 1 WHERE NodeID = (SELECT NodeID FROM soft.Programs)'

psql -q -E -A -t -X -c 'SELECT soft.If_Statements()'

psql -q -E -A -t -X -c 'SELECT soft.Function_Declarations()'

echo 'digraph {' > prog.dot ; psql -q -E -A -t -X -c 'select distinct soft.Get_DOT()' >> prog.dot
echo '}' >> prog.dot
dot -Tpdf -o prog_0.pdf prog.dot

open prog_0.pdf

exit;

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
