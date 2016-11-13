SET CLIENT_ENCODING TO UTF8;
SET STANDARD_CONFORMING_STRINGS TO ON;
BEGIN;
CREATE TABLE "arch_visitor_centers" (gid serial,
"unitcode" varchar(254),
"unitcodeot" varchar(254),
"unitname" varchar(254),
"unitnameot" varchar(254),
"groupcode" varchar(254),
"regioncode" varchar(254),
"programtag" varchar(254),
"usertag" varchar(254),
"createdatf" varchar(254),
"editedatfg" varchar(254),
"mapmethod" varchar(254),
"mapsource" varchar(254),
"sourcedate" date,
"sourcedatf" varchar(254),
"sourcescal" varchar(254),
"xyerror" varchar(254),
"restrictio" varchar(254),
"qualityrev" varchar(254),
"contributo" varchar(254),
"keywords" varchar(254),
"maplabel" varchar(254),
"altname" varchar(254),
"featuretyp" varchar(254),
"descriptio" varchar(254),
"notes" varchar(254),
"metadataid" varchar(254),
"relatedid" varchar(254),
"geometry_i" varchar(254),
"globalid" varchar(254));
ALTER TABLE "arch_visitor_centers" ADD PRIMARY KEY (gid);
SELECT AddGeometryColumn('','arch_visitor_centers','geom','4326','POINT',2);
INSERT INTO "arch_visitor_centers" ("unitcode","unitcodeot","unitname","unitnameot","groupcode","regioncode","programtag","usertag","createdatf","editedatfg","mapmethod","mapsource","sourcedate","sourcedatf","sourcescal","xyerror","restrictio","qualityrev","contributo","keywords","maplabel","altname","featuretyp","descriptio","notes","metadataid","relatedid","geometry_i","globalid",geom) VALUES ('ARCH',NULL,'Arches National Park','Arches NP','SEUG','IMR','IMR','Unknown','Unknown','20131220','Heads-up Digitized','Microsoft, 20100623, Res.(M): 0.3, Acc.(M): 5.4','20100623',NULL,'Unknown','Unknown','Unrestricted','IMR','Park',NULL,NULL,NULL,'Visitor Center','Visitor Center',NULL,NULL,NULL,NULL,'{8D3EB80E-1E7B-46D6-9D0A-0E7DBCD06794}','0101000020E6100000FBFFFFFFAA675BC072FEFFFFEF4E4340');
CREATE INDEX ON "arch_visitor_centers" USING GIST ("geom");
COMMIT;
