#!/bin/sh
rm -f ./dot/*.png
./dot.pl
open ./dot/*.png
