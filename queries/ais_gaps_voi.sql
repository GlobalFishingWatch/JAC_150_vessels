-------------------------------------------------------------------------------
-- Query: AIS gap events for 150 voi
--
-- Max Schofield
-- Date: 17 March 2023
--------------------------------------------------------------------------------

  ---SET your date minimum of interest
CREATE TEMP FUNCTION minimum() AS (DATE('2020-01-01'));

---SET your date maximum of interest
CREATE TEMP FUNCTION maximum() AS (DATE('2022-12-31'));


WITH

  ----------------------------------------------------------
  -- Define lists of high/med/low confidence fishing vessels
  ----------------------------------------------------------

  voi AS (
    SELECT
      DISTINCT identity.ssvid,
      identity.n_shipname AS vessel_name,
      identity.n_callsign AS ircs,
      identity.imo,
      identity.flag,
    FROM
    -- IMPORTANT: change below to most up to date table
      `world-fishing-827.vessel_database.all_vessels_v20230201`
      LEFT JOIN UNNEST(feature.geartype)
    WHERE
      identity.ssvid IN (SELECT CAST(ssvid AS string) FROM `world-fishing-827.scratch_max.150_voi_ssvid`)
      OR identity.ssvid IN ('412331285', '412420574', '412334074', '412420659','412440717', '412440716', '412336962', '412331283',
                            '412331285', '412331284', '412331282', '412331281', '412331279')
    ),




  ------------------------------------------------------------------------
  -- Select gaps in AOI
  ------------------------------------------------------------------------
  gaps AS (
  SELECT
      *,
      EXTRACT(year from gap_start) as year,
  FROM
    `world-fishing-827.pipe_production_v20201001.proto_ais_gap_events`
  WHERE
  -- limit to gap events longer than 12 hours as satellite reception can vary considerably over shorter timeframes
      gap_hours >= 12
  -- spatial filter for distance to shore - set to 10 nm to exclude gaps near port
      -- AND (gap_start_distance_from_shore_m > 1852*10 AND gap_end_distance_from_shore_m > 1852*10)
  -- restrict to vessels with 5 or more positions per day to exclude poor transmission
      -- AND (positions_per_day_off > 5 AND positions_per_day_on > 5)

  -- restrict to gaps that started and ended in period of interest
  AND DATE(gap_start) BETWEEN '2022-02-01' AND '2023-02-02'

  -- restrict to gap events where the vessel had transmitted on AIS at least 19 times in the 12 hours before the gap
  -- event occurred. This was identified as threshold for potential AIS disabling
      -- AND positions_12_hours_before_sat >= 19
     -- spatial filter for only positions within aoi
      -- AND ST_CONTAINS(aoi.polygon, ST_GEOGPOINT(gap_start_lon, gap_start_lat))
      -- AND ST_CONTAINS(aoi.polygon, ST_GEOGPOINT(gap_end_lon, gap_end_lat))
  ),

  ------------------------------------------------------------------------
  -- Append vessel info to gaps
  ------------------------------------------------------------------------
  fishing_gaps AS (
      SELECT
       *
      FROM
        gaps
      JOIN voi USING(ssvid)
  )

------------------------------------------------------------------------
-- Return gaps
------------------------------------------------------------------------

SELECT
  DISTINCT(gap_id) AS uniq,
  ssvid,
  -- vessel_name,
  -- -- geartype,
  -- imo,
  -- ircs,
  -- flag,
  gap_start AS gap_start_timestamp,
  gap_end AS gap_end_timestamp,
  gap_hours,
  gap_distance_m,
  gap_implied_speed_knots,
  gap_start_lat,
  gap_start_lon,
  gap_end_lat,
  gap_end_lon,
  gap_start_receiver_type,
  gap_end_receiver_type,
  is_closed,
FROM
  fishing_gaps
WHERE
  gap_implied_speed_knots > 15
ORDER BY gap_start_timestamp
