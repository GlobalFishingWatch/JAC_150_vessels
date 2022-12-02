---------------------------------------------------------------------------
-- Get encounters for a VoI based on MMSI
-- Author: Max Schofield
-- Date: 01 December 2022
---------------------------------------------------------------------------


  ---SET your dates  of interest

CREATE TEMP FUNCTION START_DATE() AS (DATE('2021-01-01'));
CREATE TEMP FUNCTION END_DATE() AS (DATE('2022-11-30'));


WITH


-- aoi AS (
--  SELECT
--   ST_GEOGFROMTEXT( "MULTIPOLYGON ((({bbox[[1,1]]} {bbox[[1,4]]}, {bbox[[1,2]]} {bbox[[1,4]]}, {bbox[[1,2]]} {bbox[[1,3]]}, {bbox[[1,1]]} {bbox[[1,3]]}, {bbox[[1,1]]} {bbox[[1,4]]})))"  ) AS polygon
-- ),
aoi AS(
  SELECT
    ST_GEOGFROMTEXT( "MULTIPOLYGON ((( -69.40 -52.31, -69.13 -52.31, -69.13 -52.20, -69.40 -52.20, -69.40 -52.31 )))" ) AS polygon
),

  -------------------------
  -- pull out encounters for voi and time period of interest
  -- assume encounters are only two vessels
  --
  -------------------------

encounters AS (
  SELECT
    event_id,
    JSON_EXTRACT_SCALAR(event_vessels,"$[0].ssvid") AS v1_ssvid,
    JSON_EXTRACT_SCALAR(event_vessels,"$[0].name") AS v1_name,
    JSON_EXTRACT_SCALAR(event_vessels,"$[0].type") AS v1_type,
    JSON_EXTRACT_SCALAR(event_vessels,"$[0].flag") AS v1_flag,
    JSON_EXTRACT_SCALAR(event_vessels,"$[1].ssvid") AS v2_ssvid,
    JSON_EXTRACT_SCALAR(event_vessels,"$[1].name") AS v2_name,
    JSON_EXTRACT_SCALAR(event_vessels,"$[1].type") AS v2_type,
    JSON_EXTRACT_SCALAR(event_vessels,"$[1].flag") AS v2_flag,
    event_start,
    event_end,
    lat_mean,
    lon_mean,
    regions_mean_position.eez AS eez,
    regions_mean_position.rfmo AS rfmo,
    JSON_EXTRACT(event_info,"$.median_distance_km") AS median_distance_km,
    JSON_EXTRACT(event_info,"$.median_speed_knots") AS median_speed_knots,
    SPLIT(event_id, ".")[ORDINAL(1)] AS event,
    CAST (event_start AS DATE) event_date,
    EXTRACT(YEAR FROM event_start) AS year
  FROM `world-fishing-827.pipe_production_v20201001.published_events_encounters`, aoi
  WHERE
    ST_CONTAINS(aoi.polygon, ST_GEOGPOINT(lon_mean, lat_mean))
    AND DATE(event_start) >= START_DATE()
    AND DATE(event_end) <= END_DATE()
    AND lat_mean < 90
    AND lat_mean > -90
    AND lon_mean < 180
    AND lon_mean > -180)

SELECT *
FROM encounters
