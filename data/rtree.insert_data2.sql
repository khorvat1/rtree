TRUNCATE TABLE rtree.index_table CASCADE;
TRUNCATE TABLE rtree.units CASCADE;

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
, hasc_2
, name_2
, NULL
  FROM import.usa_adm_units
  where hasc_2 <> 'US.AK.AW';

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
