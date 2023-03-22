-- 1) HAI HANG 3 30 Nov
-- 2) FU YUAN YU 715 19 December
-- 3) LU RONG YUAN YU 715 25 July
-- 4) FU YUAN YU 9995 28 Dec 2022 (after intrep)
CREATE TEMP FUNCTION minimum_suff() AS ("20200101");
CREATE TEMP FUNCTION maximum_suff() AS ("20221231");

CREATE TEMP FUNCTION minimum_date() AS (DATE("2020-01-01"));
CREATE TEMP FUNCTION maximum_date() AS (DATE("2022-12-31"));
------------------------------
-- get daily segment identities
------------------------------
WITH daily_identity AS (
SELECT
  seg_id,
  ssvid,
  EXTRACT(DATE FROM timestamp) AS day,
  shipnames.value AS shipname,
  shipnames.count AS shipname_count
  FROM
  `world-fishing-827.pipe_production_v20201001.segments_*`,
  UNNEST(shipnames) AS shipnames
  WHERE _TABLE_SUFFIX BETWEEN minimum_suff() AND maximum_suff()
  AND ssvid IN (SELECT CAST(ssvid AS string) FROM `world-fishing-827.scratch_max.150_voi_ssvid`)
  -- AND ssvid = '150400453'
  AND NOT REGEXP_CONTAINS(shipnames.value, r"[^a-zA-Z0-9\s]+") -- removes LUS<]_YUANYU 715 because contains special characters
  AND NOT REGEXP_CONTAINS(shipnames.value, r"0XX$") -- removes LURONGYUANYU 0XX because it matches

),
------------------------------
-- get daily segment locations
------------------------------
seg_location AS (
  SELECT
  seg_id,
  EXTRACT(DATE FROM first_timestamp) AS day,
  avg_lat_lon
  FROM
  pipe_production_v20201001.research_segs_daily
  WHERE
    -- ssvid = '150400453'
    ssvid IN (SELECT CAST(ssvid AS string) FROM `world-fishing-827.scratch_max.150_voi_ssvid`)
    AND EXTRACT(DATE FROM first_timestamp) BETWEEN minimum_date() AND maximum_date()
)
------------------------------
-- Merge
------------------------------
SELECT
  *
  FROM
  daily_identity
  INNER JOIN
  seg_location
  USING (seg_id, day)
  ORDER BY ssvid, day
