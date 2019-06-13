CREATE OR REPLACE FUNCTION rtree.create_rtee ()
  RETURNS void AS $$

DECLARE

  units_array rtree.spatial_units[];

BEGIN

  CREATE TEMP TABLE slices(
    id  bigint,
    child rtree.spatial_units
  );

  SELECT ARRAY(
    SELECT ROW(it.id, it.bbox)
    FROM rtree.units u
    INNER JOIN rtree.index_table it
      ON it.id = u.index_id
  ) INTO units_array;
  
  PERFORM rtree.create_levels(units_array, 0);

  DROP TABLE slices;

END;
$$ LANGUAGE plpgsql;
