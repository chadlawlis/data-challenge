#!/bin/bash

for f in *.shp
do
    shp2pgsql -I -s 4326 $f `basename $f .shp` > `basename $f .shp`.sql
done

for f in *.sql
do
    psql -d nps -f $f
done