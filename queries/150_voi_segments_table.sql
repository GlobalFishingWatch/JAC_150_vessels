CREATE TABLE `world-fishing-827.scratch_max.AIS_segs_150_mmsi_prefix_2021_20Oct2022` AS

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
  FROM `world-fishing-827.pipe_production_v20201001.messages_segmented_20230205`
  WHERE SUBSTRING(ssvid, 1, 3) = '150'
  AND DATE(timestamp) BETWEEN DATE("2020-01-01") AND DATE("2022-12-31"))


SELECT *
  FROM all_vessels
