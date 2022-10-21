---------------------------------------------------------------------------
-- Use voi to extract fishing encounters of 150 vessels operating in squid grounds
-- 2021 to date
-- Author: Max Schofield
-- code adapted from Cians Patrol support code
-- Date: 21 October 2022
---------------------------------------------------------------------------


  ---SET your date minimum of interest
CREATE TEMP FUNCTION minimum() AS (DATE('2021-01-01'));

---SET your date maximum of interest
CREATE TEMP FUNCTION maximum() AS (DATE('2022-10-20'));


WITH
  voi_summary AS (
    SELECT DISTINCT ssvid,
        COUNT(lat) AS transmissions,
        COUNT(DISTINCT shipname) AS num_names,
        MAX(DATE(timestamp)) AS last_trans
    FROM `world-fishing-827.scratch_max.raw_AIS_150_mmsi_prefix_2021_20Oct2022`
    GROUP BY ssvid
  ),
  -------------------------
  -- pull out encounters from voi
  -------------------------

  encounters AS (
    SELECT
      event_id,
      JSON_EXTRACT_SCALAR(event_vessels,"$[0].ssvid") AS ssvid,
      vessel_id,
      event_start,
      event_end,
      lat_mean,
      lon_mean,
      event_vessels,
      JSON_EXTRACT(event_info,"$.median_distance_km") AS median_distance_km,
      JSON_EXTRACT(event_info,"$.median_speed_knots") AS median_speed_knots,
      SPLIT(event_id, ".")[ORDINAL(1)] AS event,
      CAST (event_start AS DATE) event_date,
      EXTRACT(YEAR FROM event_start) AS year
    FROM `world-fishing-827.pipe_production_v20201001.published_events_encounters`
    WHERE
      JSON_EXTRACT_SCALAR(event_vessels,"$[0].ssvid") IN (SELECT ssvid FROM voi_summary)
      AND DATE(event_start) >= minimum()
      AND DATE(event_end) <= maximum()
      AND lat_mean < 90
      AND lat_mean > -90
      AND lon_mean < 180
      AND lon_mean > -180),


    ----------------------------------------------------------------------
    -- create curated carrier list
    -- Remember to change the database version to the most recent version
    -- time range of carriers should overlap with the time of encounters to ensure they are actively transmitting during
    -- as carriers during the time of encounters
    ----------------------------------------------------------------------
    carrier_vessels AS (
        SELECT
          mmsi AS carrier_ssvid,
          flag AS carrier_flag,
          year
        FROM
          `world-fishing-827.vessel_database.carrier_vessels_byyear_v20220901`
        WHERE
          year >= 2021
        ),

    ----------------------------------------------------------------------
    -- fishing vessels
    ---Note here that for the current year UNLESS the NN has been run for that year, you may be missing vessels in this
    -- list, an option is to also include fishing vessels from 2020 OR to pull from the on_fishing_list_best list in
    -- vi_ssvid table
    ----------------------------------------------------------------------
    fishing_vessels AS (
    SELECT
        ssvid AS fv_ssvid,
        year,
        best_vessel_class AS fv_best_vessel_class,
        best_flag AS fv_flag,
    FROM
        `gfw_research.fishing_vessels_ssvid_v20220901`
    WHERE
        year >= 2021
    ),

    ----------------------------------------------------------------------
    --Join vessel the carrier encountered
    --because there is one row per vessel (therefore two rows per encounter) just join again with the encounter dataset
    --on the unqiue event id but specify it must be the non-carrier ssvid this time
    ----------------------------------------------------------------------
    encounter_carriers as(
        SELECT
        *
        FROM encounters
        INNER JOIN
            carrier_vessels
        ON
            encounters.ssvid = carrier_vessels.carrier_ssvid
            AND EXTRACT(year FROM encounters.event_start) = carrier_vessels.year),

    ---------------
    -- no encounters with carriers
    -- make one row per encounter with both vessels ssvid included.
    ----------------

    all_encounters as (
        SELECT
            ssvid AS v1_ssvid,
            v2_ssvid,
            event_start,
            event_end,
            lat_mean as mean_lat,
            lon_mean as mean_lon,
            median_distance_km,
            median_speed_knots,
            (TIMESTAMP_DIFF(event_end,event_start,minute)/60) event_duration_hr,
            a.event AS event,
            event_date
        FROM
          (SELECT
              *
          FROM
              encounters) a
        JOIN
          (SELECT
              ssvid AS v2_ssvid,
              event
          FROM
              encounters) b
        ON a.event = b.event
        WHERE ssvid != v2_ssvid
        GROUP BY
            1,2,3,4,5,6,7,8,9,10,11),

    ---------------
    -- add fishing vessel best information for vessel 2
    ----------------

    fv_sv_encs as(
        SELECT
            event,
            event_start,
            event_end,
            mean_lat,
            mean_lon,
            event_Duration_hr,
            median_speed_knots,
            v1_ssvid,
            fv_ssvid AS v2_ssvid,
            fv_best_vessel_class AS v2_best_vessel_class,
            fv_flag AS v2_fv_flag
        FROM all_encounters
        INNER JOIN
            fishing_vessels
        ON
            all_encounters.v2_ssvid = fishing_vessels.fv_ssvid
            AND EXTRACT(year FROM all_encounters.event_start) = fishing_vessels.year),

    ---------------
    -- add fishing vessel best information for vessel 1
    -- use seperate table for simipicity and to try make it work!
    ----------------

    add_f1_best_info AS(
          SELECT
            event,
            event_start,
            event_end,
            mean_lat,
            mean_lon,
            event_Duration_hr,
            median_speed_knots,
            v1_ssvid,
            fv_best_vessel_class AS v1_best_vessel_class,
            fv_flag AS v1_fv_flag,
            v2_ssvid,
            v2_best_vessel_class,
            v2_fv_flag
        FROM fv_sv_encs
        LEFT JOIN
            fishing_vessels
        ON
            fv_sv_encs.v1_ssvid = fishing_vessels.fv_ssvid
            AND EXTRACT(year FROM fv_sv_encs.event_start) = fishing_vessels.year)


    ----------------------------------------------------------------------
    -- filter encounters that occurred in aoi
    ----------------------------------------------------------------------
    -- fv_enc_aoi AS (
    --     SELECT
    --         event,
    --         event_start,
    --         event_end,
    --         mean_lat,
    --         mean_lon,
    --         event_Duration_hr,
    --         median_speed_knots,
    --         carrier_ssvid,
    --         fv_ssvid,
    --         fv_best_vessel_class,
    --         fv_flag
    --     FROM fv_sv_encs , aoi
    --     WHERE
    --         ST_CONTAINS(aoi.polygon, ST_GEOGPOINT(mean_lon, mean_lat))
    -- )
-- ----------------------------------------------------------------------
-- Return
----------------------------------------------------------------------
  SELECT *
  FROM add_f1_best_info
