#!/bin/bash
./install
cp languages/monkey/node_types.csv node_types.csv
psql -q -X -f languages/monkey.sql
mv node_types.csv languages/monkey/node_types.csv
