-- get all port calls for VOI


WITH
------------------------------------------------------------
-- Port Events Source data
-- adjust the time range here
------------------------------------------------------------
port_events AS (
  SELECT
    visit_id,
    vessel_id,
    ssvid,
    start_timestamp,
    end_timestamp,
    duration_hrs,
    confidence,
    e.timestamp as event_timestamp,
    e.vessel_lat as event_lat,
    e.vessel_lon as event_lon,
    e.anchorage_id as anchorage_id,
    e.event_type as event_type
  FROM `pipe_production_v20201001.proto_port_visits`
  LEFT JOIN UNNEST (events) e
  WHERE start_timestamp BETWEEN timestamp("2020-01-01")
    AND timestamp("2022-12-31")
    AND confidence>=2),

------------------------------------------------------------
-- Mapping vessel_id to SSVID
------------------------------------------------------------
anchorages AS (
SELECT
  *
FROM
  `world-fishing-827.gfw_research.named_anchorages`),

port_visits_voi AS (
  SELECT
  * EXCEPT (s2id)
  FROM(
    SELECT
      visit_id,
      vessel_id,
      ssvid,
      start_timestamp,
      end_timestamp,
      duration_hrs,
      confidence,
      event_timestamp,
      event_lat,
      event_lon,
      anchorage_id,
      event_type
    FROM
     port_events)a
  JOIN(
    SELECT
      s2id,
      label,
      sublabel,
      iso3,
      distance_from_shore_m,
      at_dock
    FROM
      anchorages)b
  ON
    a.anchorage_id=b.s2id
  WHERE
    CAST(ssvid AS int64) IN (SELECT * FROM `scratch_max.150_voi_ssvid`))

SELECT
  DISTINCT  iso3,
  label,
  ssvid,
  count(DISTINCT visit_id) AS visits
FROM port_visits_voi
GROUP BY iso3, label, ssvid
ORDER BY iso3
-- SELECT * FROM anchorages
