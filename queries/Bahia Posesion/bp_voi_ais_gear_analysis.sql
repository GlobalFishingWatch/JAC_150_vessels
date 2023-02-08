
CREATE TEMP FUNCTION START_DATE() AS (DATE('{date_start}'));
CREATE TEMP FUNCTION END_DATE() AS (DATE('{date_end}'));
-- CREATE TEMP FUNCTION START_DATE() AS (DATE('2022-01-01'));
-- CREATE TEMP FUNCTION END_DATE() AS (DATE('2022-01-30'));


SELECT
  ssvid,
  lon,
  lat,
  timestamp,
  speed_knots,
  -1 * elevation_m AS depth_m,
  distance_from_shore_m/1000 AS distance_from_shore_km,
  nnet_score
FROM
   `pipe_production_v20201001.research_messages`
WHERE
  seg_id IN (
    SELECT seg_id
    FROM `gfw_research.pipe_v20201001_segs`
    WHERE
    overlapping_and_short IS FALSE AND
    good_seg IS TRUE) AND
  ssvid = '{voi}' AND
  timestamp BETWEEN TIMESTAMP(START_DATE()) AND TIMESTAMP(END_DATE()) AND
  nnet_score IS NOT NULL
ORDER BY
  timestamp
