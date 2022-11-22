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

-- aoi AS(
-- SELECT
--   ST_GEOGFROMTEXT( "MULTIPOLYGON ((( -8 7, 3 7, 3 0, -8 0, -8 7 )))" ) AS polygon
-- ),

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
    year
  FROM
    -- IMPORTANT: change below to most up to date table
    `world-fishing-827.gfw_research.vi_ssvid_byyear_v20221001`
),

----------------------------------------------------------
-- Define lists of high/med/low confidence fishing vessels
----------------------------------------------------------
--
-- HIGH: MMSI in the fishing_vessels_ssvid table.
-- These are vessels on our best fishing list and that have reliable AIS data
--
high_confidence AS (
   SELECT DISTINCT
     ssvid,
     best_vessel_class,
     'high' as confidence,
     year
   FROM `world-fishing-827.gfw_research.fishing_vessels_ssvid_v20221001`
   ),
--
-- MED: All MMSI on our best fishing list not included in the high category.
-- These are likely fishing vessels that primarily get excluded due to data issues
-- (e.g. spoofing, offsetting, low activity)
--
med_confidence AS (
  SELECT DISTINCT
    ssvid,
    best.best_vessel_class,
    'med' as confidence,
    year
  FROM `world-fishing-827.gfw_research.vi_ssvid_byyear_v20221001`
  WHERE on_fishing_list_best
  AND ssvid NOT IN (
    SELECT ssvid
    FROM high_confidence
    )
  ),
--
-- LOW: MMSI that are on one of our three source fishing lists (registry, neural net, self-reported)
-- but not included in either the med or high list. These are MMSI for which we have minimal
-- or conflicting evidence that they are a fishing vessel.
--
low_confidence AS (
  SELECT
    ssvid,
    best.best_vessel_class,
    'low' as confidence,
    year
  FROM `world-fishing-827.gfw_research.vi_ssvid_byyear_v20221001`
  WHERE (
    on_fishing_list_nn
    OR on_fishing_list_known
    OR on_fishing_list_sr
    )
  AND ssvid NOT IN (SELECT ssvid FROM high_confidence)
  AND ssvid NOT IN (SELECT ssvid FROM med_confidence)
  ),



----------------------------------------------------------
-- Find vessels in messaged scored DB within aoi
----------------------------------------------------------
fishing AS (
  SELECT
    COUNT (DISTINCT ssvid) AS vessels,
    EXTRACT(month FROM _partitiontime) as month,
    EXTRACT(year FROM _partitiontime) as year,
    best_flag,
    best_vessel_class,
    -- CASE
    --   WHEN ssvid IN (SELECT ssvid FROM high_confidence) THEN 'high'
    --   WHEN ssvid IN (SELECT ssvid FROM med_confidence) THEN 'medium'
    --   WHEN ssvid IN (SELECT ssvid FROM low_confidence) THEN 'low'
    --   ELSE NULL
    --   END AS confidence
  /*
  Query the pipe_vYYYYMMDD_fishing table to reduce query
  size since we are only interested in fishing vessels
  */
  FROM
    `pipe_production_v20201001.research_messages`
    , aoi
    LEFT JOIN UNNEST(regions.eez) AS eez
    LEFT JOIN fishing_vessels USING (ssvid)
  -- Restrict query to specific time range
  WHERE
    -- filter to only include data from 2022
    _partitiontime BETWEEN '2021-01-01' AND '2022-11-15'

    -- Use eez code to restrict to Chile
    AND eez IN ('8465')

    -- Restrict to AOI
    AND ST_CONTAINS(aoi.polygon, ST_GEOGPOINT(lon, lat))

  GROUP BY year, month, best_flag, best_vessel_class
  )

SELECT
  *
FROM
  fishing
  -- Use spatial join to restrict to aoi
