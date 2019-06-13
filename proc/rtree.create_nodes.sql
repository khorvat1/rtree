-- DROP FUNCTION rtree.create_nodes(rtree.spatial_units[],integer);
CREATE OR REPLACE FUNCTION rtree.create_nodes (units_array rtree.spatial_units[], level integer)
  RETURNS rtree.spatial_units[] AS $$

DECLARE

  parent_nodes  rtree.spatial_units[];
  sorted_elements rtree.spatial_units[];
  min_leaf_count  integer;
  slice_count integer;
  capacity  integer;
  counter integer;
  counterInner integer;
  element rtree.spatial_units;
  slice_id  bigint;

BEGIN
  --
  min_leaf_count = ceil(array_length(units_array, 1)::float / rtree.get_node_elements()::float);
  RAISE NOTICE 'minLeafCount %',min_leaf_count;

  --sortiraj po x koordinati
  SELECT ARRAY(
      SELECT ROW(a.id, a.bbox)
      FROM unnest(units_array) as a
      ORDER BY ST_X(ST_Centroid(a.bbox))
  ) INTO sorted_elements;

  slice_count := ceil(sqrt(min_leaf_count::float));
  capacity = ceil(array_length(sorted_elements, 1)::float / slice_count::float);

  RAISE NOTICE 'slice_count % capacity %', slice_count, capacity;

  TRUNCATE slices;

  --za broj sliceva koji se kreiraju
  FOR counter IN 1..slice_count LOOP
    --idi po arrayu elemenata i dodaj određeni broj sliceva u temp tablicu slices
    slice_id := nextval('rtree.rtee_sequence');
    counterInner := 0;
    
    FOREACH element IN ARRAY sorted_elements LOOP
      EXIT WHEN counterInner >= capacity;

        --dodaj element u slice
        INSERT INTO slices
        ( id,
          child
        )
          SELECT
          slice_id,
          element;
      counterInner := counterInner + 1;
      sorted_elements := array_remove(sorted_elements, element);

    END LOOP;--za insert elemenata u slice

  END LOOP;--za kreiranje sliceva

  --za svaki vertical slice
  parent_nodes := rtree.create_vertical_slices (level);
  RETURN parent_nodes;

END;
$$ LANGUAGE plpgsql;
