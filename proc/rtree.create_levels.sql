CREATE OR REPLACE FUNCTION rtree.create_levels (units_array rtree.spatial_units[], razina integer)
  RETURNS void AS $$

DECLARE

  parent_nodes  rtree.spatial_units[];
  current_node  bigint;
  geometry      geometry;

BEGIN
  --
  parent_nodes = rtree.create_nodes(units_array, razina + 1);
  IF array_length(parent_nodes, 1) = 1 THEN
    --root je već insertan
  ELSE
    PERFORM rtree.create_levels(parent_nodes, razina + 1);
  END IF;

END;
$$ LANGUAGE plpgsql;
