--------------------------------------------------------------------------------
-- Pulling raw AIS from vessels operating in Bahia Posesion

-- Author: Max Schofield
-- Date: 15 November 2022
--------------------------------------------------------------------------------

 -- AIS based on bounding box
 -- time period 01 Jan 2021 to 15 Nov 2022

--------------------------------------------------------------------------------


CREATE TABLE `world-fishing-827.scratch_max.bahia_posesion_raw_ais` AS

WITH

----------------------------------------------------------
-- Define area of interest
----------------------------------------------------------
-- aoi AS (
--   SELECT
--     ST_GEOGFROMTEXT( "MULTIPOLYGON ((({bbox[[1,1]]} {bbox[[1,4]]}, {bbox[[1,2]]} {bbox[[1,4]]}, {bbox[[1,2]]} {bbox[[1,3]]}, {bbox[[1,1]]} {bbox[[1,3]]}, {bbox[[1,1]]} {bbox[[1,4]]})))"  ) AS polygon
-- ),

aoi AS(
  SELECT
    ST_GEOGFROMTEXT( "MULTIPOLYGON ((( -69.40 -52.31, -69.13 -52.31, -69.13 -52.20, -69.40 -52.20, -69.40 -52.31 )))" ) AS polygon
),

----------------------------------------------------------
-- Best Vessel info
----------------------------------------------------------
fishing_vessels AS (
  SELECT
    ssvid,
    -- EXTRACT(YEAR FROM activity.last_timestamp) AS year,
    best.best_flag AS best_flag,
    best.best_vessel_class AS best_vessel_class,
    ais_identity.n_shipname_mostcommon.value AS vessel_name,
    -- ais_identity.n_shipname.value AS n_names,
    registry_info.registries_listed AS auths,
    year
  FROM
    -- IMPORTANT: change below to most up to date table
    `world-fishing-827.gfw_research.vi_ssvid_byyear_v20221001`
),

----------------------------------------------------------
-- Identify vessels based on raw AIS
----------------------------------------------------------
-- FROM `pipe_ais_sources_v20201001.normalized_spire_*`

aoi_raw_ais_spire AS (
  SELECT
    *
  FROM
    `pipe_ais_sources_v20220628.normalized_spire_*`,
    aoi
    LEFT JOIN fishing_vessels USING (ssvid)
  -- Restrict query to specific time range
  WHERE
    -- filter to only include data from 2022
    DATE(timestamp) BETWEEN '2021-01-01' AND '2022-11-15'
    -- Restrict to AOI
    AND ST_CONTAINS(aoi.polygon, ST_GEOGPOINT(lon, lat))
  ),

aoi_raw_ais_orbcom AS (
  SELECT
    *
  FROM
    `pipe_ais_sources_v20220628.normalized_orbcomm_*`,
    aoi
    LEFT JOIN fishing_vessels USING (ssvid)
  -- Restrict query to specific time range
  WHERE
    -- filter to only include data from 2022
    DATE(timestamp) BETWEEN '2021-01-01' AND '2022-11-15'
    -- Restrict to AOI
    AND ST_CONTAINS(aoi.polygon, ST_GEOGPOINT(lon, lat))
  ),

-- combined_aoi_ais AS (
--   select * from aoi_raw_ais_spire
-- UNION
--   (select * from aoi_raw_ais_orbcom MINUS select * from aoi_raw_ais_spire)
-- )

combined_aoi_ais AS (
  SELECT ssvid, timestamp, lon, lat, speed FROM aoi_raw_ais_spire
  UNION DISTINCT
  SELECT ssvid, timestamp, lon, lat, speed FROM aoi_raw_ais_orbcom
)


SELECT
  *
FROM
  combined_aoi_ais
ORDER BY timestamp
