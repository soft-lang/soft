#!/bin/sh
rm ./dot/*.png
./dot.pl
open ./dot/*.png
