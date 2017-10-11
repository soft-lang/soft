#!/bin/bash
./install.pl > install.sql
psql -X -f install.sql
rm install.sql
echo Generating Graphviz DOT images for all steps...
./dot.sh
