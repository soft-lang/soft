#!/bin/sh
rm ./dot/*.pdf
./dot.pl
open ./dot/*.pdf
