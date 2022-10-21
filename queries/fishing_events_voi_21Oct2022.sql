---------------------------------------------------------------------------
-- Use voi to extract fishing events of 150 vessels operating in squid grounds
-- 2021 to date
-- Author: Max Schofield
-- Date: 19 October 2022
---------------------------------------------------------------------------

---SET your date minimum of interest
CREATE TEMP FUNCTION minimum() AS (DATE("2021-01-01"));
---SET your date maximum of interest
CREATE TEMP FUNCTION maximum() AS (CURRENT_DATE());


WITH
#############################################################
-- extract fishing event information
-- for dates of interest
event_summary AS (
  SELECT
    JSON_EXTRACT_SCALAR(event_vessels, "$[0].ssvid") as ssvid,
    event_type,
    event_start,
    event_end,
    -- calculate fishing event duration
    (TIMESTAMP_DIFF(event_end, event_start, second)/3600) as event_duration_hr,
    lat_mean,
    lon_mean,
    -- extract event information
    JSON_EXTRACT_SCALAR(event_info,
        "$.message_count") AS message_count,
    JSON_EXTRACT_SCALAR(event_info,
        "$.distance_km") AS distance_km,
    JSON_EXTRACT_SCALAR(event_info,
        "$.avg_speed_knots") AS avg_speed_knots,
  FROM
    `world-fishing-827.pipe_production_v20201001.proto_events_fishing`
  WHERE
    -- restrict to date range of interest
    DATE(event_start)<=maximum()
    AND DATE(event_end)>=minimum() ),

#############################################################
-- join fishing events with vessel information
event_vi AS (
SELECT
   event_summary.*,
   vesselinfo.best.best_vessel_class AS best_best_vessel_class,
   vesselinfo.best.best_flag AS best_best_flag,
   vesselinfo.ssvid AS main_vessel_ssvid
  FROM
   event_summary
  LEFT JOIN
   `gfw_research.vi_ssvid_v20210706` AS vesselinfo
  USING
   (ssvid)
  WHERE
   EXTRACT(YEAR from event_start) BETWEEN EXTRACT(YEAR from activity.first_timestamp) AND  EXTRACT(YEAR from activity.last_timestamp)
   AND ssvid IN (SELECT DISTINCT ssvid FROM `world-fishing-827.scratch_max.raw_AIS_150_mmsi_prefix_2021_20Oct2022`)),

#############################################################
-- define area of interest using BQ shapefile - IATTC RFMO or ICCAT
iattc as(
  SELECT
    st_GeogFromText(string_field_1, make_valid=>TRUE) AS iattc
  FROM
    `ocean_shapefiles_all_purpose.IATTC_shape_feb2021`),

iccat as(
  SELECT
   st_GeogFromText(string_field_1, make_valid=>TRUE) AS iccat
  FROM
    --`ocean_shapefiles_all_purpose.ICCAT_shape_feb2021`),
    `ocean_shapefiles_all_purpose.ICCAT_shape_feb2021`)


#############################################################
-- identify fishing events in area of interest (IATTC)
--iattc_fishing_events AS(
  SELECT
    ssvid,
    best_best_vessel_class,
    best_best_flag,
    event_type,
    event_start,
    event_end,
    event_duration_hr,
    lat_mean,
    lon_mean,
    message_count,
    distance_km,
    avg_speed_knots,
  FROM
    event_vi, iattc
  WHERE
    --ST_CONTAINS(iattc.iattc, ST_GEOGPOINT(lon_mean, lat_mean))),
    ST_CONTAINS(iattc.iattc, ST_GEOGPOINT(lon_mean, lat_mean))

--iccat_fishing_events AS(
--  SELECT
--    ssvid,
--    best_best_vessel_class,
--    best_best_flag,
--    event_type,
--    event_start,
--    event_end,
--    event_duration_hr,
--    lat_mean,
--    lon_mean,
--  FROM
--    event_vi, iccat
--  WHERE
--    ST_CONTAINS(iccat.iccat, ST_GEOGPOINT(lon_mean, lat_mean))),


#############################################################
--iattc_count AS (
--  SELECT
--    DISTINCT ssvid,
--    COUNT(event_type) AS iattc_fishing_events
--  FROM
--    iattc_fishing_events
--  GROUP BY ssvid)

--SELECT
--  DISTINCT ssvid,
--  COUNT(event_type) AS iccat_fishing_events,
--  iattc_fishing_events
--FROM
--  iccat_fishing_events
--RIGHT JOIN
--  (SELECT DISTINCT ssvid, COUNT(event_type) AS iattc_fishing_events
--  FROM iattc_fishing_events GROUP BY ssvid) AS iattc USING (ssvid)
--GROUP BY ssvid,iattc_fishing_events


