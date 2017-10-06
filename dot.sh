#!/bin/sh
echo 'digraph { rankdir=LR; ' > prog.dot ; psql -q -E -A -t -X -c "set search_path to soft; select distinct Get_DOT('monkey', 'fibonacci')" >> prog.dot
echo '}' >> prog.dot
dot -Tpdf -o "prog.pdf" prog.dot
open prog.pdf
