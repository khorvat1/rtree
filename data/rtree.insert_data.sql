DELETE FROM rtree.index_table;

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
