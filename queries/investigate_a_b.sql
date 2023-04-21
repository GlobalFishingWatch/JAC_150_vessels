-- Examine research messages from voi in 2023 to look at spoofing.

 WITH

  activity AS (
    SELECT
    msgid,
    ssvid,
    seg_id,
    timestamp,
    lat,
    lon,
    speed_knots,
    heading,
    course,
    meters_to_prev,
    implied_speed_knots,
    hours,
    night,
    nnet_score,
    logistic_score,
    night_loitering,
    type,
    source,
    receiver_type,
    distance_from_port_m,
    distance_from_shore_m,
    distance_from_sat_km,
    is_fishing_vessel
    FROM
      `pipe_production_v20201001.research_messages`
    LEFT JOIN UNNEST(regions.eez) AS eez
    -- Restrict query to specific time range
    WHERE
    -- filter to only include data from the patrol period over the last 3 years
    _partitiontime BETWEEN '2020-01-01' AND '2023-03-31'
    -- AND EXTRACT(MONTH FROM _partitiontime) IN (2,3)
    -- Use eez code to restrict to Sierra Leone EEZ
    -- AND eez IN ('8390')
    -- Use aoi to restrict to SLE buffer (including EEZ)

    --AND ssvid IN ('150402944', '150400453', '150402949', '150402940', '150402947', '150402951')
    AND ssvid IN (SELECT CAST(ssvid AS string) FROM `world-fishing-827.scratch_max.150_voi_ssvid`)
    OR ssvid IN ('412331285', '412420574', '412334074', '412420659','412440717', '412440716', '412336962', '412331283',
                          '412331284', '412331282', '412331281', '412331279')
      )

  SELECT
    *,
    CASE
      WHEN type IN ('AIS.1', 'AIS.3') THEN  'A'
      WHEN type IN ('AIS.18', 'AIS.19') THEN  'B'
      ELSE 'OTH'
    END AS AIS_class
  FROM activity
