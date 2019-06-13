CREATE OR REPLACE FUNCTION rtree.start_search(geom geometry)
  RETURNS TABLE (id bigint, name character varying(50)) AS $$
DECLARE
  root      rtree.index_table%ROWTYPE;
  max_level integer;
BEGIN

  SELECT max(a.level)
    INTO max_level
    FROM rtree.index_table a;

  SELECT a.*
    INTO root
    FROM rtree.index_table a
    WHERE a.level = max_level;

  IF ST_Intersects(root.bbox, geom) THEN
    CREATE TEMP TABLE result (LIKE rtree.units) ON COMMIT DROP;
    PERFORM rtree.search(geom, root.id);
    RETURN QUERY SELECT a.id, a.name FROM result a;

  ELSE
    RAISE NOTICE 'geom nije u rootu';
  END IF;

END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION rtree.search (geom geometry, node_id bigint)
  RETURNS void AS $$
DECLARE

  node  rtree.index_table%ROWTYPE;
  child rtree.index_table%ROWTYPE;

BEGIN

  SELECT a.*
    INTO node
    FROM rtree.index_table a
    WHERE a.id = node_id;

  RAISE NOTICE 'node % lev %', node_id, node.level;

  IF node.level <> 0 THEN
    FOR child IN
      SELECT a.*
      FROM rtree.index_table a
      WHERE a.parent_id = node.id
      AND ST_Intersects(a.bbox, geom)
    LOOP
    IF node.level = 1 THEN
      RAISE NOTICE 'search for chiled of level 1'; END IF;
      PERFORM rtree.search (geom, child.id);
    END LOOP;
  ELSE
  RAISE NOTICE 'hit';
    INSERT INTO result
      SELECT a.*
      FROM rtree.units a
      WHERE a.index_id = node.id
      AND ST_Intersects(a.geometry, geom);
  END IF;

END;
$$ LANGUAGE plpgsql;
