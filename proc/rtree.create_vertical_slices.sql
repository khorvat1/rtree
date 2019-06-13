
CREATE OR REPLACE FUNCTION rtree.create_vertical_slices (level integer)
  RETURNS rtree.spatial_units[] AS $$

DECLARE

  current_node  bigint;
  slice_id  bigint;
  children rtree.spatial_units[];
  children_ids  bigint[];
  child_element rtree.spatial_units;
  parent_nodes  rtree.spatial_units[];
  node rtree.spatial_units%ROWTYPE;
  geometry  geometry;
  counter integer;
  innerCounter integer;

BEGIN

  FOR slice_id
    IN SELECT DISTINCT(id)
    FROM slices
    ORDER BY id
  LOOP

    --sortiraj po Y
    SELECT ARRAY(
      SELECT child
      FROM slices
      WHERE id = slice_id
      ORDER BY ST_Y(ST_Centroid((child).bbox))
    ) INTO children;

    current_node := nextval('rtree.rtee_sequence');
    INSERT INTO rtree.index_table(id, bbox, level, parent_id)
      SELECT current_node, null, level, null;
    innerCounter := 0;
    counter := 0;

    FOREACH child_element IN ARRAY children LOOP
      IF innerCounter >= rtree.get_node_elements() THEN
        SELECT INTO node current_node as id, geometry as bbox;
        parent_nodes := array_append(parent_nodes, node);

        current_node := nextval('rtree.rtee_sequence');
        INSERT INTO rtree.index_table(id, bbox, level, parent_id)
          SELECT current_node, null, level, null;
        innerCounter := 0;
      END IF;

      IF innerCounter = 0 THEN
        geometry := child_element.bbox;
      ELSE
        geometry := ST_Envelope(ST_Union(geometry, child_element.bbox));
      END IF;

      UPDATE rtree.index_table
        SET bbox = geometry
        WHERE id = current_node;

      UPDATE rtree.index_table
        SET parent_id = current_node
        WHERE id = child_element.id;

      innerCounter := innerCounter + 1;
      counter := counter + 1;

      RAISE NOTICE 'current_node %', current_node;

      IF counter >= array_length(children, 1) THEN
        SELECT INTO node current_node as id, geometry as bbox;
        parent_nodes := array_append(parent_nodes, node);
      END IF;

    END LOOP;

  END LOOP;
  
  RETURN parent_nodes;

END;
$$ LANGUAGE plpgsql;
