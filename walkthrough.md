#Using Postgres for Data Aggregation and Cleanup
######POSTED ON 27 JANUARY 2015 BY CHAD LAWLIS

The NPMap team is constantly wrangling datasets of varying formats both large and small, all of which must play nicely together to seamlessly feed into our [Places](http://www.nps.gov/npmap/tools/) system. In this post we are going to walk through how to use [Postgres](http://postgresapp.com/documentation/) to combine a table from CartoDB with a set of five shapefiles provided from our friends at [Arches National Park](http://www.nps.gov/arch/index.htm). The goal is to produce a final aggregated `output.geojson` file that we can plot on a map. 

##Required Software

Before we get started, you will need the following installed on your computer:
* [Postgres.app](http://postgresapp.com/), which contains a full-featured PostgreSQL installation for Mac.
  * *Note: Windows users, check out [LearnOSM's documentation](http://learnosm.org/en/osm-data/setting-up-postgresql/) to learn how to run PostgreSQL with the PostGIS spatial extension on a PC. Not all code in this tutorial will apply across platforms.*

Refer to the [Postgres](http://postgresapp.com/documentation/), [PostgreSQL](http://www.postgresql.org/docs/9.4/static/index.html), and [PostGIS](http://postgis.net/documentation) documentation for other guidance as needed along the way.

##Getting Started

###CartoDB

For this exercise we are provided with a CartoDB table with username: `nps` and table name: `points_of_interest` containing points of interest for the entire National Park Service, including Arches National Park. [CartoDB's SQL API](http://docs.cartodb.com/cartodb-platform/sql-api.html) allows you to interact with the table as if you were running SQL statements against a normal PostgreSQL database. This is a public table so anyone with the username and table name can select data without authentication through the API.

To query the database, a request follows this general structure:

```
http://{account}.cartodb.com/api/v2/sql?q={SQL statement}
```

So, let's take a peek at the data starting with one row and the table schema:

```
http://nps.cartodb.com/api/v2/sql?q=SELECT * FROM points_of_interest LIMIT 1;
```

Returns:

```json
{
	"rows": [
		{
			"version": 1,
			"name": "Boundary Oak Trailhead",
			"places_id": "9bd8530a-6725-43ef-8013-8537b235723e",
			"unit_code": "abli",
			"type": "Trailhead",
			"tags": "{\"name\": \"Boundary Oak Trailhead\", \"highway\": \"trailhead\", \"nps:places_id\": \"9bd8530a-6725-43ef-8013-8537b235723e\", \"nps:unit_code\": \"abli\"}",
			"the_geom": "0101000020E6100000B9CDAF413A6F55C099FAD40C04C44240",
			"cartodb_id": 192533,
			"created_at": "2015-01-16T22:27:13Z",
			"updated_at": "2015-01-16T22:27:13Z",
			"the_geom_webmercator": "0101000020110F000054AF30D94D3462C10FBF9EA0A6375141"
		}
	],
	"time": 0.001,
	"fields": {
		"version": {
			"type": "number"
		},
		"name": {
			"type": "string"
		},
		"places_id": {
			"type": "string"
		},
		"unit_code": {
			"type": "string"
		},
		"type": {
			"type": "string"
		},
		"tags": {
			"type": "string"
		},
		"the_geom": {
			"type": "geometry"
		},
		"cartodb_id": {
			"type": "number"
		},
		"created_at": {
			"type": "date"
		},
		"updated_at": {
			"type": "date"
		},
		"the_geom_webmercator": {
			"type": "geometry"
		}
	},
	"total_rows": 1
}
```

*Protip: install [this JSON Formatter extension](https://github.com/callumlocke/json-formatter) for Chrome to parse JSON in browser rather than trying to decipher the raw (unformatted) code.*

Next, let's take a look at the table's [Spatial Reference System (SRS)](http://en.wikipedia.org/wiki/Spatial_reference_system). By default, CartoDB's geometry field `the_geom` is in [WGS 84 (EPSG:4326)](http://spatialreference.org/ref/epsg/wgs-84/). Let's run a query to confirm:

```
http://nps.cartodb.com/api/v2/sql?q=SELECT ST_SRID(the_geom) FROM points_of_interest LIMIT 1;
```

Returns:

```json
{"rows":[{"st_srid":4326}],"time":0.002,"fields":{"st_srid":{"type":"number"}},"total_rows":1}
```

The [SRID](http://en.wikipedia.org/wiki/SRID) is the Spatial Reference System Identifier, which at 4326 confirms the table is in WGS 84. CartoDB also stores a hidden field `the_geom_webmercator` in the table, which is a projected conversion of `the_geom` in [WGS84 Web Mercator (EPSG:3857)](http://spatialreference.org/ref/sr-org/7483/). We are going to use the default WGS 84 EPSG:4326 because it outputs latitude and longitude in decimal degrees which play nicely with [Leaflet](http://leafletjs.com/reference.html#latlng), [GitHub](https://help.github.com/articles/mapping-geojson-files-on-github/#troubleshooting), and others.

Now, let's make a GET request to the API to download the data. CartoDB can export in a variety of formats including `CSV`, `SHP`, and `GeoJSON` among others. Let's export as `SHP` (shapefile) by adding `format=SHP` to the query. In our final `output.geojson` we are only looking to include the `name`, `type`, `unit_code`, and `geometry` fields so we can limit this in our query as well:

```
http://nps.cartodb.com/api/v2/sql?format=CSV&q=SELECT name, type, unit_code, the_geom FROM points_of_interest;
```

This will download a zipped shapefile `cartodb-query.zip`. Unzip and rename all files to `poi` (`poi.shp`, `poi.dbf`, etc). 

###Shapefiles

Download the shapefiles from Arches National Park by cloning their [GitHub repo](https://github.com/nationalparkservice/data-challenge-lawlis) to your local machine. In Terminal, navigate to your desired directory and enter:

```
git clone https://github.com/nationalparkservice/data-challenge-lawlis.git
```

Move the `poi` files to the same directory as the Arches shapefiles. Take a look at their projection by running a quick [GDAL](http://www.gdal.org/) command using the [ogrinfo](http://www.gdal.org/ogrinfo.html) utility, which is included in the Postgres installation:

```
ogrinfo arch_campgrounds.shp -al -so
```

Returns:

```
~/Downloads/_nps (git::master) ▶ ogrinfo arch_campgrounds.shp -al -so
INFO: Open of `arch_campgrounds.shp'
      using driver `ESRI Shapefile' successful.

Layer name: arch_campgrounds
Geometry: Point
Feature Count: 1
Extent: (622584.109000, 4293012.370000) - (622584.109000, 4293012.370000)
Layer SRS WKT:
PROJCS["NAD_1983_UTM_Zone_12N",
    GEOGCS["GCS_North_American_1983",
        DATUM["North_American_Datum_1983",
            SPHEROID["GRS_1980",6378137,298.257222101]],
        PRIMEM["Greenwich",0],
        UNIT["Degree",0.017453292519943295]],
    PROJECTION["Transverse_Mercator"],
    PARAMETER["latitude_of_origin",0],
    PARAMETER["central_meridian",-111],
    PARAMETER["scale_factor",0.9996],
    PARAMETER["false_easting",500000],
    PARAMETER["false_northing",0],
    UNIT["Meter",1]]
Easting: Real (24.15)
Northing: Real (24.15)
Name: String (254.0)
GlobalID: String (254.0)
```

Repeat for each shapefile, which confirms that all are projected in [NAD_1983_UTM_Zone_12N (EPSG:26912)](http://spatialreference.org/ref/epsg/nad83-utm-zone-12n/). For location accuracy and performance it is important for all data to conform to one SRS so let's convert to WGS 84 using GDAL's [ogr2ogr](http://www.gdal.org/ogr2ogr.html) utility:

```
ogr2ogr arch_campgrounds_4326.shp arch_campgrounds.shp -t_srs EPSG:4326 -f "ESRI Shapefile"
ogr2ogr arch_parking_4326.shp arch_parking.shp -t_srs EPSG:4326 -f "ESRI Shapefile"
ogr2ogr arch_restrooms_4326.shp arch_restrooms.shp -t_srs EPSG:4326 -f "ESRI Shapefile"
ogr2ogr arch_trailheads_4326.shp arch_trailheads.shp -t_srs EPSG:4326 -f "ESRI Shapefile"
ogr2ogr arch_visitor_centers_4326.shp arch_visitor_centers.shp -t_srs EPSG:4326 -f "ESRI Shapefile"
```

Let's move these into a child directory and rename them, given the filename will be used as the table name in the PostgreSQL database. Move the `poi` export to this directory as well. You can batch rename files quickly through the command line in the directory housing your data:

```
mv arch_campgrounds_4326.dbf arch_campgrounds.dbf
mv arch_campgrounds_4326.prj arch_campgrounds.prj
mv arch_campgrounds_4326.qpj arch_campgrounds.qpj
mv arch_campgrounds_4326.shp arch_campgrounds.shp
mv arch_campgrounds_4326.shx arch_campgrounds.shx
mv arch_parking_4326.dbf arch_parking.dbf
mv arch_parking_4326.prj arch_parking.prj
mv arch_parking_4326.qpj arch_parking.qpj
mv arch_parking_4326.shp arch_parking.shp
mv arch_parking_4326.shx arch_parking.shx
mv arch_restrooms_4326.dbf arch_restrooms.dbf
mv arch_restrooms_4326.prj arch_restrooms.prj
mv arch_restrooms_4326.qpj arch_restrooms.qpj
mv arch_restrooms_4326.shp arch_restrooms.shp
mv arch_restrooms_4326.shx arch_restrooms.shx
mv arch_trailheads_4326.dbf arch_trailheads.dbf
mv arch_trailheads_4326.prj arch_trailheads.prj
mv arch_trailheads_4326.qpj arch_trailheads.qpj
mv arch_trailheads_4326.shp arch_trailheads.shp
mv arch_trailheads_4326.shx arch_trailheads.shx
mv arch_visitor_centers_4326.dbf arch_visitor_centers.dbf
mv arch_visitor_centers_4326.prj arch_visitor_centers.prj
mv arch_visitor_centers_4326.qpj arch_visitor_centers.qpj
mv arch_visitor_centers_4326.shp arch_visitor_centers.shp
mv arch_visitor_centers_4326.shx arch_visitor_centers.shx
```

##Using psql for Data Aggregation and Final Export

[psql](http://postgresapp.com/documentation/cli-tools.html) is the PostgreSQL command line interface to your database. In Terminal navigate to the directory housing your data. Create a database `nps` and establish a PostGIS spatial extension through the following commands:

```
~/Downloads/_nps (git::master) ▶ createdb nps
~/Downloads/_nps (git::master) ▶ psql -U chad -d nps -c "create extension postgis;"
CREATE EXTENSION
```

Rather than import each file into the PostgreSQL database individually we can automate this through a shell script. Create the `loadfiles.sh` shell script using the following code and add to the same directory housing your data. This will import each shapefile into the `nps` database while maintaining WGS 84 SRS (4326 = SRID below):

```sh
#!/bin/bash

for f in *.shp
do
    shp2pgsql -I -s 4326 $f `basename $f .shp` > `basename $f .shp`.sql
done

for f in *.sql
do
    psql -d nps -f $f
done
```

(Credit: [Boundless](http://suite.opengeo.org/4.1/dataadmin/pgGettingStarted/shp2pgsql.html#bash) for the script). Learn more about the shp2pgsql data loader [here](http://postgis.refractions.net/documentation/manual-1.3/ch04.html#id2571948). Now run the script in Terminal:

```
~/Downloads/_nps/ (git::master) ▶ sh loadfiles.sh
```

Run the command `psql -U chad -d nps -c "\dt"` to confirm that the files were successfully imported into the `nps` database:

```
~/Downloads/_nps (git::master) ▶ psql -U chad -d nps -c "\dt"
               List of relations
 Schema |         Name         | Type  | Owner
--------+----------------------+-------+-------
 public | arch_campgrounds     | table | chad
 public | arch_parking         | table | chad
 public | arch_restrooms       | table | chad
 public | arch_trailheads      | table | chad
 public | arch_visitor_centers | table | chad
 public | poi                  | table | chad
 public | spatial_ref_sys      | table | chad
(7 rows)
```

Before we move on let's get a feel for the newly imported data. Run the following query against each table to view a snippet of its contents as well as the table structure:

```
 psql -U chad -d nps -c "select * from arch_trailheads limit 10;"
 ```
 
 Returns:
 
 ```
~/Downloads/_nps (git::master) ▶ psql -U chad -d nps -c "select * from arch_trailheads limit 10;"
 gid |          name           |                globalid                |                        geom
-----+-------------------------+----------------------------------------+----------------------------------------------------
   1 | Devils Garden           | {30AFD9B9-3118-48B4-B388-E0CF27D4DFF0} | 0101000020E6100000C27980E714665BC0A47E217235644340
   2 | Fiery Furnace           | {E2EDAD37-90EC-4CEA-92E6-163B9A670F01} | 0101000020E6100000E6BFC91A38645BC07C856B8A195F4340
   3 | Delicate Arch Viewpoint | {B5F34B77-B745-4484-AF10-077D77ED416C} | 0101000020E61000002085090018605BC0ED8772C4F15D4340
   4 | Delicate Arch           | {D9F001C8-236B-4668-B2C3-9DE4ED8D7385} | 0101000020E61000008FD02F2952615BC0308BAAF0285E4340
   5 | The Windows             | {14E8939E-D120-4CCF-9B4D-658C401B4C83} | 0101000020E6100000262ACCE058625BC08D83746EF3574340
   6 | Balanced Rock           | {CE9A83C2-C767-4EB6-BE30-A609CD0607B4} | 0101000020E6100000896DAB6638645BC0E3C577E3D2594340
   7 | Courthouse Towers       | {278A9751-CE5D-4B18-AA7C-30036BA90DE8} | 0101000020E61000003BF257EE65665BC01582313677514340
   8 | Park Avenue             | {23047B43-3364-4581-9D31-D9361EFF522D} | 0101000020E6100000DF6D2F6161665BC04E48C463EA4F4340
   9 | Broken Arch CG South    | {5381E10D-1FDC-45E2-A83C-2AB698F60617} | 0101000020E610000041E19FB883655BC03BD5AD5BF7624340
  10 | Broken Arch CG North    | {BBCDD600-A089-4727-8723-BF8A228EB0F7} | 0101000020E6100000826957708E655BC02ABC81151C634340
(10 rows)
```

Run the following query against each table to calculate the total number of rows to expect in the final output:

```
 psql -U chad -d nps -c "select count(*) from arch_trailheads;"
```

Returns:

```
~/Downloads/_nps (git::master) ▶ psql -U chad -d nps -c "select count(*) from arch_trailheads;"
 count
-------
    15
(1 row)
```

Repeat for each Arches shapefile. For the `poi` table:

```
 psql -U chad -d nps -c "select count(*) from poi;"
```

Returns:

```
~/Downloads/_nps (git::master) ▶ psql -U chad -d nps -c "select count(*) from poi;"
 count
-------
 10812
(1 row)
```

Looks like there are a total of 37 rows from the five Arches shapefiles and 10,812 from the CartoDB `poi`shapefile for a grand total of 10,849 rows expected in our final output. We will confirm this after combining the tables and exporting the final `output.geojson`.

Now let's merge the `poi` table with the Arches data to create a final `output` table including only the `name`, `type`, `unit_code`, and `geom` fields:

```
psql -U chad -d nps -c "create table output as select name, 'Campground' as type, 'arch' as unit_code, geom from arch_campgrounds union all select Name as name, 'Parking' as type, 'arch' as unit_code, geom from arch_parking union all select Bldg_name as name, 'Restroom' as type, 'arch' as unit_code, geom from arch_restrooms union all select Name as name, 'Trailhead' as type, 'arch' as unit_code, geom from arch_trailheads union all select UnitName as name, 'Visitor Center' as type, 'arch' as unit_code, geom from arch_visitor_centers union all select name, type, unit_code, geom from poi;"
```

Take another look at the structured `SQL` to get a better feel for the query. Notice as we populate the `type` and `unit_code` fields on the fly for the Arches tables given these are a known and constant value for each dataset (`unit_code = 'arch'`for all Arches tables, `type = 'Campground'` for `arch_campgrounds`, `type = 'Parking'` for `arch_parking`, etc):

```sql
create table output as
	select name, 'Campground' as type, 'arch' as unit_code, geom
	from arch_campgrounds
	union all
	select Name as name, 'Parking' as type, 'arch' as unit_code, geom
	from arch_parking
	union all
	select Bldg_name as name, 'Restroom' as type, 'arch' as unit_code, geom
	from arch_restrooms
	union all
	select Name as name, 'Trailhead' as type, 'arch' as unit_code, geom
	from arch_trailheads
	union all
	select UnitName as name, 'Visitor Center' as type, 'arch' as unit_code, geom
	from arch_visitor_centers
	union all
	select name, type, unit_code, geom
	from poi;"
```

Now, run the COUNT query once more on the `output` table to confirm all 10,849 rows were combined successfully:

```
psql -U chad -d nps -c "select count(*) from output;"
```

Returns:

```
~/Downloads/_nps (git::master) ▶ psql -U chad -d nps -c "select count(*) from output;"
 count
-------
 10849
(1 row)
```

Success! Finally, we are ready to export the table as the final `output.geojson` file:

```
ogr2ogr -f "GeoJSON" output.geojson PG:"host=localhost user=chad dbname=nps password=<password>" "output"
```

This will download to your pwd (present working directory). And there you go! You are now ready to plot this in your application of choice ([QGIS](http://www.qgis.org/en/site/), [TileMill](https://www.mapbox.com/tilemill/), [CartoDB](http://cartodb.com/), etc) to visualize and explore the data.

[Check out the data on GitHub](https://github.com/nationalparkservice/data-challenge-lawlis/blob/master/output.geojson) which automatically renders GeoJSON files onto OpenStreetMap in browser. Below is another glimpse of the data overlaying [US State data](http://www.census.gov/cgi-bin/geo/shapefiles2014/file-download) from the US Census Bureau

![](https://farm8.staticflickr.com/7440/16193066338_d109a89903_c.jpg)

*Note: the point in the bottom left is in American Samoa while the point in the far right is in Guam. The map is zoomed to the `output.geojson` layer extent with default QGIS styling, just as a preview*