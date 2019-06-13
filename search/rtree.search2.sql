with recursive rtree(id) as (
  SELECT id
	FROM rtree.index_table
	WHERE level = ( SELECT max(a.level) FROM rtree.index_table a)

  UNION ALL
  SELECT
    b.id
  FROM rtree a
  INNER JOIN rtree.index_table b
    ON b.parent_id = a.id
  WHERE ST_Intersects(b.bbox, ST_GeomFromText('POINT(-111 36)',4326))
)

SELECT *
FROM rtree a
INNER JOIN rtree.units b
  ON b.index_id = a.id
WHERE ST_Intersects(b.geometry, ST_GeomFromText('POINT(-111 36)',4326))
