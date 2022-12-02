-------------------------------------
-- Query to identify squid vessel
-- positions in each previously defined
-- squid fishing region.
--
-- Code adapted from NM global squid paper
-- MS 25Nov2022
--
--
WITH
-------------------------------------
-- Squid regions. These are also defined
-- in BQ
-------------------------------------
aoi AS (
  SELECT
    *
  FROM
    paper_global_squid.final_squid_regions_v20220525),
-------------------------------------
-- Positions for vessels ID'd in Bahia Posesion in 2021 or 2022
-------------------------------------
squid_vessel_positions AS (
  SELECT
    *
  FROM
    `world-fishing-827.scratch_max.bahiaposession_voi_ais_2021_2022_v2`),

-------------------------------------
-- Fishing and presence in individual
-- squid regions
-------------------------------------
--
-------------------------------------
-- NW Pacific
-------------------------------------
ssvid_in_nw_pacific AS (
  SELECT
    ssvid,
    EXTRACT(year FROM date) AS year,
    EXTRACT(month FROM date) as month,
    date,
    'nw_pacific' AS aoi,
    COUNT(*) positions,
    SUM(hours) total_hours,
    SUM(IF(night_loitering = 1, hours, 0)) AS fishing_hours
  FROM
    squid_vessel_positions
  WHERE
    IF(
      ST_CONTAINS((SELECT geometry FROM aoi WHERE area = 'nw_pacific'),
        ST_GEOGPOINT(lon,lat)),
    TRUE,
    FALSE)
  GROUP BY 1,2,3,4),
-------------------------------------
-- SE Pacific
-------------------------------------
ssvid_in_se_pacific AS (
  SELECT
    ssvid,
    EXTRACT(year FROM date) AS year,
    EXTRACT(month FROM date) as month,
    date,
    'se_pacific' AS aoi,
    COUNT(*) positions,
    SUM(hours) total_hours,
    SUM(IF(night_loitering = 1, hours, 0)) AS fishing_hours
  FROM
    squid_vessel_positions
  WHERE
  IF(
    ST_CONTAINS((SELECT geometry FROM aoi WHERE area = 'se_pacific'),
    ST_GEOGPOINT(lon, lat)),
    TRUE,
    FALSE)
  GROUP BY 1,2,3,4),
-------------------------------------
-- SW Atlantic
-------------------------------------
ssvid_in_sw_atlantic AS (
  SELECT
    ssvid,
    EXTRACT(year FROM date) AS year,
    EXTRACT(month FROM date) as month,
    date,
    'sw_atlantic' AS aoi,
    COUNT(*) positions,
    SUM(hours) total_hours,
    SUM(IF(night_loitering = 1, hours, 0)) AS fishing_hours
  FROM
    squid_vessel_positions
  WHERE
    IF(
      ST_CONTAINS((SELECT geometry FROM aoi WHERE area = 'sw_atlantic'),
      ST_GEOGPOINT(lon,lat)),
    TRUE,
    FALSE)
  GROUP BY 1,2,3,4),
-------------------------------------
-- NW Indian
-------------------------------------
ssvid_in_nw_indian AS (
  SELECT
    ssvid,
    EXTRACT(year FROM date) AS year,
    EXTRACT(month FROM date) as month,
    date,
    'nw_indian' AS aoi,
    COUNT(*) positions,
    SUM(hours) total_hours,
    SUM(IF(night_loitering = 1, hours, 0)) AS fishing_hours
  FROM
    squid_vessel_positions
  WHERE
    IF(ST_CONTAINS((SELECT geometry FROM aoi WHERE area = 'nw_indian'),
      ST_GEOGPOINT(lon,lat)),
      TRUE,
      FALSE)
    GROUP BY 1,2,3,4),

-------------------------------------
-- Bahia Posesion
-------------------------------------
bahia_posesion AS(
  SELECT
    ST_GEOGFROMTEXT( "MULTIPOLYGON ((( -69.40 -52.31, -69.13 -52.31, -69.13 -52.20, -69.40 -52.20, -69.40 -52.31 )))" ) AS polygon
),

ssvid_in_bp AS (
  SELECT
    ssvid,
    EXTRACT(year FROM date) AS year,
    EXTRACT(month FROM date) as month,
    date,
    'bahia_posesion' AS aoi,
    COUNT(*) positions,
    SUM(hours) total_hours,
    SUM(IF(night_loitering = 1, hours, 0)) AS fishing_hours
  FROM
    squid_vessel_positions,bahia_posesion
  WHERE
    IF(ST_CONTAINS(bahia_posesion.polygon,
      ST_GEOGPOINT(lon,lat)),
      TRUE,
      FALSE)
    GROUP BY 1,2,3,4),

-------------------------------------
-- Combine fishing/presence from all
-- squid regions
-------------------------------------
ssvid_regions_combined AS (
  SELECT
    *
  FROM (
    SELECT * FROM ssvid_in_nw_pacific
    UNION ALL
    SELECT * FROM ssvid_in_se_pacific
    UNION ALL
    SELECT * FROM ssvid_in_sw_atlantic
    UNION ALL
    SELECT * FROM ssvid_in_nw_indian
    UNION ALL
    SELECT * FROM ssvid_in_bp
    )
  -- LEFT JOIN(
  --   SELECT * FROM full_light_vessels)
  --   USING (ssvid)
  -- WHERE
  --   date BETWEEN CAST(first_timestamp AS DATE) AND CAST(last_timestamp AS DATE)
  )
-------------------------------------
--Identify any vessels (SSVID) represented
-- twice because of two gear types
-------------------------------------
-- dups AS (
--   SELECT
--     ssvid
--   FROM (
--     SELECT
--       ssvid,
--       COUNT(*) counts
--     FROM (
--       SELECT
--         ssvid,
--         geartype
--       FROM
--         ssvid_regions_combined
--       GROUP BY
--         1,2 )
--     GROUP BY
--     1 )
--   WHERE
--     counts = 2 )
-------------------------------------
-- Remove the duplicates by keeping
-- the non-squidjigger label (typically)
-- this will be 'lift-netter'
-------------------------------------

-- SELECT * FROM ssvid_in_nw_pacific LIMIT 20

SELECT
  *
FROM
  ssvid_regions_combined
-- LEFT JOIN (SELECT eez_id, territory1_iso3 FROM `world-fishing-827.gfw_research.eez_info`) USING (eez_id)

  -- (
  --   SELECT
  --     *
  --   FROM
  --     ssvid_regions_combined
  --   WHERE
  --     ssvid IN (SELECT ssvid FROM dups) AND
  --     geartype != 'squid_jigger'
  --   UNION ALL
  --   SELECT
  --     *
  --   FROM
  --     ssvid_regions_combined
  --   WHERE
  --     ssvid NOT IN (SELECT ssvid FROM dups WHERE ssvid IS NOT NULL)
  --   )
