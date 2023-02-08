--------------------------------------------------------------------------------
-- Identifying vessels operating in Bahia Posesion

-- Author: Max Schofield
-- Date: 15 November 2022
--------------------------------------------------------------------------------

 -- Identify VOI within AoI
 --
 --

--------------------------------------------------------------------------------
WITH

----------------------------------------------------------
-- Define area of interest
----------------------------------------------------------
aoi AS (
  SELECT
    ST_GEOGFROMTEXT( "MULTIPOLYGON ((({bbox[[1,1]]} {bbox[[1,4]]}, {bbox[[1,2]]} {bbox[[1,4]]}, {bbox[[1,2]]} {bbox[[1,3]]}, {bbox[[1,1]]} {bbox[[1,3]]}, {bbox[[1,1]]} {bbox[[1,4]]})))"  ) AS polygon
),

----------------------------------------------------------
-- Best Vessel info
----------------------------------------------------------
vessel_info AS (
  SELECT
    ssvid,
    -- EXTRACT(YEAR FROM activity.last_timestamp) AS year,
    best.best_flag AS best_flag,
    best.best_vessel_class AS best_vessel_class,
    ais_identity.n_shipname_mostcommon.value AS vessel_name,
    -- ais_identity.n_shipname.value AS n_names,
    registry_info.registries_listed AS auths
  FROM
    -- IMPORTANT: change below to most up to date table
    `world-fishing-827.gfw_research.vi_ssvid_byyear_v20221001`
),

----------------------------------------------------------
-- Identify vessels based on raw AIS table
----------------------------------------------------------

voi AS (
  SELECT
    DISTINCT ssvid,
    EXTRACT(year FROM timestamp) AS year,
    EXTRACT(month FROM timestamp) AS month,
  FROM
    `world-fishing-827.pipe_production_v20201001.messages_segmented_*`,
    aoi
  WHERE
    DATE(timestamp) BETWEEN '2021-01-01' AND '2022-11-15'
    -- valid lat and lons
    AND lat BETWEEN -90 and 90
    AND lon BETWEEN -180 and 180
    -- Restrict to AOI
    AND ST_CONTAINS(aoi.polygon, ST_GEOGPOINT(lon, lat))
--    AND EXTRACT(year FROM timestamp) = 2021
--    AND EXTRACT(month FROM timestamp) IN (4,5,6,7)
)



SELECT
  *
FROM
  voi
LEFT JOIN
  vessel_info USING (ssvid)

