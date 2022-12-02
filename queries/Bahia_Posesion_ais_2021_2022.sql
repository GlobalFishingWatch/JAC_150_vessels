-------------------------------------
-- Query to get positions for all
-- squid vessels observed in Bahia Posesion in 2020 & 2021
--
-- Adapted form example squid code from NM
--
-- MS 25Nov2022
-- creates BQ table `world-fishing-827.scratch_max.bahiaposession_voi_ais_2021_2022`
-------------------------------------
-- DROP TABLE `world-fishing-827.scratch_max.bahiaposession_voi_ais_2021_2022`;
CREATE TABLE `world-fishing-827.scratch_max.bahiaposession_voi_ais_2021_2022_v2` AS

WITH
-------------------------------------
-- noise filter
-------------------------------------
good_segments AS (
  SELECT
    seg_id
  FROM
    `pipe_production_v20201001.research_segs`
  WHERE
    good_seg IS TRUE
    AND positions > 5
    AND overlapping_and_short IS FALSE ),
-------------------------------------
-- Get positions from 2017 through 2021
-- (will later be filtered to just 2020)
-- note: special list of squid ssvid
-------------------------------------
squid_vessel_positions AS (
  SELECT
    ssvid,
    lon,
    lat,
    EXTRACT(date FROM timestamp) as date,
    night_loitering,
    hours,
    eez_id
  FROM
    `pipe_production_v20201001.research_messages`
  LEFT JOIN UNNEST(regions.eez) AS eez_id
  WHERE
    _PARTITIONTIME BETWEEN TIMESTAMP("2021-01-01") AND TIMESTAMP("2022-12-31") AND
    seg_id IN (SELECT seg_id FROM good_segments) AND
    ssvid IN (SELECT ssvid FROM `world-fishing-827.scratch_max.bahia_posesion_raw_ais`)
)

-- LEFT JOIN (SELECT eez_id, territory1_iso3 FROM `world-fishing-827.gfw_research.eez_info`) USING (eez_id)


-------------------------------------
-- Final table
-------------------------------------
SELECT * FROM squid_vessel_positions
