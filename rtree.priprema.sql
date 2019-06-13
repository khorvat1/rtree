DROP SEQUENCE rtree.rtee_sequence CASCADE;
CREATE SEQUENCE rtree.rtee_sequence START WITH 1;

DROP TABLE rtree.units;
DROP TABLE rtree.index_table;

CREATE TABLE rtree.units(
  id bigint NOT NULL DEFAULT nextval('rtree.rtee_sequence'),
  geometry geometry(MultiPolygon,4326),
  short_name character varying(10),
  name character varying(50),
  index_id bigint
);

ALTER TABLE rtree.units ADD PRIMARY KEY (id);

CREATE TABLE rtree.index_table(
  id bigint NOT NULL DEFAULT nextval('rtree.rtee_sequence'),
  bbox geometry(Polygon,4326),
  level integer,
  parent_id bigint
);

ALTER TABLE rtree.index_table ADD PRIMARY KEY (id);

ALTER TABLE rtree.units ADD CONSTRAINT units_fk1
  FOREIGN KEY (index_id)
  REFERENCES rtree.index_table(id)
  ON DELETE CASCADE;

ALTER TABLE rtree.index_table ADD CONSTRAINT index_table_fk1
  FOREIGN KEY (parent_id)
  REFERENCES rtree.index_table(id)
  ON DELETE CASCADE;


INSERT INTO rtree.units
( id
, geometry
, short_name
, name
, index_id
)
SELECT
  nextval('rtree.rtee_sequence')
, wkb_geometry
, fips
, name
, NULL
  FROM import.boundaries;

DO $$
DECLARE
  indexId  bigint;
  rec       record;
BEGIN

  FOR rec IN
    SELECT u.*
    FROM rtree.units u
  LOOP
    --
    indexId := nextval('rtree.rtee_sequence');
    INSERT INTO rtree.index_table(
      id,
      bbox,
      level,
      parent_id
    )
    SELECT
      indexId,
      ST_Envelope(rec.geometry),
      0,
      null;

    UPDATE rtree.units
      SET index_id = indexId
      WHERE id = rec.id;

  END LOOP;

END $$;

--array za kreiranje indexa
DROP TYPE rtree.spatial_units CASCADE;
CREATE TYPE rtree.spatial_units AS(
  id  bigint,
  bbox geometry(Polygon,4326)
);

--konstante
CREATE FUNCTION rtree.get_node_elements()
  RETURNS int IMMUTABLE LANGUAGE SQL AS 'SELECT 5';
