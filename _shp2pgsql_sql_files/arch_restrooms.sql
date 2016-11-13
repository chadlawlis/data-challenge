SET CLIENT_ENCODING TO UTF8;
SET STANDARD_CONFORMING_STRINGS TO ON;
BEGIN;
CREATE TABLE "arch_restrooms" (gid serial,
"objectid" numeric(10,0),
"area" numeric,
"perimeter" numeric,
"arch_bldgs" numeric(10,0),
"arch_bld_1" numeric(10,0),
"id" numeric,
"name" varchar(254),
"asset_numb" numeric(10,0),
"bldg_numbe" varchar(254),
"bldg_name" varchar(254),
"gps" varchar(254),
"shape_leng" numeric,
"orig_fid" numeric(10,0),
"globalid" varchar(254));
ALTER TABLE "arch_restrooms" ADD PRIMARY KEY (gid);
SELECT AddGeometryColumn('','arch_restrooms','geom','4326','POINT',2);
INSERT INTO "arch_restrooms" ("objectid","area","perimeter","arch_bldgs","arch_bld_1","id","name","asset_numb","bldg_numbe","bldg_name","gps","shape_leng","orig_fid","globalid",geom) VALUES ('4','0.000000000000000','0.000000000000000','0','0','0.000000000000000',NULL,'89299',NULL,'Wolfe Ranch BMS restroom','N','22.118016019999999','0','{C56AA541-E27A-4314-89B4-71760388B41E}','0101000020E6100000879624E44A615BC00FE327541E5E4340');
INSERT INTO "arch_restrooms" ("objectid","area","perimeter","arch_bldgs","arch_bld_1","id","name","asset_numb","bldg_numbe","bldg_name","gps","shape_leng","orig_fid","globalid",geom) VALUES ('6','0.000000000000000','0.000000000000000','0','0','0.000000000000000',NULL,'63592','AB55V','Delicate Arch Viewpoint vault toilet','N','18.505130340000001','1','{01B2A6D9-7525-4B6E-9AD5-97A7EA2A5BD7}','0101000020E6100000D78145A11A605BC07AF6FABBF85D4340');
CREATE INDEX ON "arch_restrooms" USING GIST ("geom");
COMMIT;
