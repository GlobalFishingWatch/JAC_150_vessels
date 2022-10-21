---------------------------------------------------------------------------
-- Establish table of raw AIS for 150 vessels operating in squid grounds
-- Table created as this is an expensive query
-- 2021 to date
-- Author: Max Schofield
-- Date: 19 October 2022
---------------------------------------------------------------------------

CREATE TABLE `world-fishing-827.scratch_max.raw_AIS_150_mmsi_prefix_2021_20Oct2022` AS


-- pull data from raw AIS table as ssvid table misses some vessels
WITH all_vessels AS (
  SELECT DISTINCT
  type,
  ssvid,
  timestamp,
  shipname,
  callsign,
  lat,
  lon,
  speed
FROM `pipe_ais_sources_v20201001.normalized_spire_*`
WHERE SUBSTRING(ssvid, 1, 3) = '150'
  AND DATE(timestamp) BETWEEN DATE("2021-01-01") AND CURRENT_DATE()),

-- pull out the shapefile for two squid fishing grounds of interest
squid_grounds AS (
  SELECT
  peru_hs,
  argentina_hs
  FROM
  `ocean_shapefiles_all_purpose.squid_fleet_regions_v20201005`),

-- identify vessels with transmissions in either South Atlantic or SW Pacific fishing grounds
operated_in_squid_grounds AS (
  SELECT DISTINCT ssvid
  FROM all_vessels, squid_grounds
  WHERE ST_CONTAINS(squid_grounds.peru_hs, ST_GEOGPOINT(lon, lat))
    OR ST_CONTAINS(squid_grounds.argentina_hs, ST_GEOGPOINT(lon, lat))
  -- ST_CONTAINS(ST_GEOGFROMTEXT("POLYGON ((-150 -50,-130 -50,-130 -4,-150 -4,-150 -50))"),
      -- ST_GEOGPOINT(lon, lat))
)

-- get AIS data from vessels in the squid grounds
SELECT *
FROM all_vessels
WHERE ssvid IN (SELECT ssvid FROM operated_in_squid_grounds)

