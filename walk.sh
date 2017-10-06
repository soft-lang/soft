#!/bin/bash
rm prog*.pdf
rm prog.dot

unset FOO
FRAME=10000

psql -X -t -A -q -c "SET search_path TO soft; SELECT Run('monkey', 'fibonacci', 'EVAL')"

echo 'digraph { rankdir=LR; ' > prog.dot ; psql -q -E -A -t -X -c "SET search_path TO soft; SELECT DISTINCT Get_DOT('monkey', 'fibonacci')" >> prog.dot
echo '}' >> prog.dot
FRAME=$((FRAME+1));
dot -Tpdf -o "prog_$FRAME.pdf" prog.dot

while : ; do
    FOO=$(psql -X -t -A -q -c "SET search_path TO soft; SELECT Walk_Tree('monkey', 'fibonacci')");
    if [ $FOO == 'f' ]; then
        break
    fi
    echo 'digraph { rankdir=LR; ' > prog.dot ; psql -q -E -A -t -X -c "SET search_path TO soft; SELECT DISTINCT Get_DOT('monkey', 'fibonacci')" >> prog.dot
    echo '}' >> prog.dot
    FRAME=$((FRAME+1));
    dot -Tpdf -o "prog_$FRAME.pdf" prog.dot
done

open prog*.pdf
