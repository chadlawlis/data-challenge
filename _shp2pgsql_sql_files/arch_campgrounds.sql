SET CLIENT_ENCODING TO UTF8;
SET STANDARD_CONFORMING_STRINGS TO ON;
BEGIN;
CREATE TABLE "arch_campgrounds" (gid serial,
"easting" numeric,
"northing" numeric,
"name" varchar(254),
"globalid" varchar(254));
ALTER TABLE "arch_campgrounds" ADD PRIMARY KEY (gid);
SELECT AddGeometryColumn('','arch_campgrounds','geom','4326','POINT',2);
INSERT INTO "arch_campgrounds" ("easting","northing","name","globalid",geom) VALUES ('622584.109000000054948','4293012.370000000111759','Arches','{DB8F5D33-A7CA-42CC-9156-DD297EEA030F}','0101000020E610000088170DB4AE655BC01F6D9B727F634340');
CREATE INDEX ON "arch_campgrounds" USING GIST ("geom");
COMMIT;
