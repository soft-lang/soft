#!/bin/sh
echo 'digraph {' > prog.dot ; psql -q -E -A -t -X -c 'set search_path to soft; select distinct Get_DOT()' >> prog.dot
echo '}' >> prog.dot
dot -Tpdf -o "prog.pdf" prog.dot
open prog.pdf
