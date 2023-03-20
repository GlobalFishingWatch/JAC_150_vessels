 ---------------------------------------------------------------------------
-- Identify the locations where a vessel changes identity information
-- Max Schofield
-- 20 March 2023
---------------------------------------------------------------------------

 -- store dates to save repeats
CREATE TEMP FUNCTION minimum() AS (DATE("2022-01-01"));
CREATE TEMP FUNCTION maximum() AS (DATE("2022-01-10"));

-- store table suffix to save repeats
CREATE TEMP FUNCTION min_suff() AS ("20200101");
CREATE TEMP FUNCTION max_suff() AS ("20230101");

WITH

-- identify all messages from vessels of interest.
-- add shipname to non positional messages from next shipname in data i.e. next static positional messages
all_messages AS (
  SELECT
    *,
    CASE
      WHEN shipname IS NULL
        THEN
          FIRST_VALUE(shipname IGNORE NULLS)
            OVER (
              PARTITION BY ssvid
              ORDER BY timestamp
              ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING)
        ELSE shipname
      END AS static_name
  FROM `world-fishing-827.pipe_production_v20201001.messages_segmented_*`
  WHERE
    _TABLE_SUFFIX BETWEEN  min_suff() AND max_suff() AND
    ssvid   IN (SELECT CAST(ssvid AS string) FROM `world-fishing-827.scratch_max.150_voi_ssvid`)
  ORDER BY timestamp
),

-- add next row name to df to spot name changes
all_messages2 AS (SELECT
  *,
  LEAD(static_name) OVER(PARTITION BY ssvid ORDER BY timestamp) AS prev_name
FROM all_messages),

-- pull out the static messages
-- attribute latitude and longitude to these based on next non-null value
static_messages AS (
  SELECT
    *,
    CASE
      WHEN lat IS NULL THEN
        FIRST_VALUE(lat IGNORE NULLS)
          OVER (
            PARTITION BY ssvid
            ORDER BY timestamp
            ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING)
        ELSE lat
    END AS next_lat,
    CASE
      WHEN lon IS NULL THEN
        FIRST_VALUE(lon IGNORE NULLS)
          OVER (
            PARTITION BY ssvid
            ORDER BY timestamp
            ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING)
        ELSE lon
    END AS next_lon,
  FROM all_messages2
  WHERE
    -- DATE(timestamp) BETWEEN minimum() AND maximum() AND
    type IN ('AIS.5', 'AIS.24', 'AIS.19')
)

-- identify rows with a change in names within the static message data.
SELECT * FROM static_messages
WHERE static_name != prev_name
