 ---------------------------------------------------------------------------
-- Identify the locations where a vessel changes identity information
-- Max Schofield
-- 20 March 2023
---------------------------------------------------------------------------

 -- store dates to save repeats
CREATE TEMP FUNCTION minimum() AS (DATE("2022-01-01"));
CREATE TEMP FUNCTION maximum() AS (DATE("2022-01-10"));

-- store table suffix to save repeats
CREATE TEMP FUNCTION min_suff() AS ("20210901");
CREATE TEMP FUNCTION max_suff() AS ("20230101");


-- test example is LU RONG YUAN YU 715 (150400453)
-- example from this intrep: https://drive.google.com/drive/folders/1GDsTE_ueDnnFBM5tX18tm0Y4xZWVMvQ3 identity changes in table at top of page 6
--  Between September 2021 and December 2022
-- Name changes to identify are
-- 1) HAI HANG 3 30 Nov
-- 2) FU YUAN YU 715 19 December
-- 3) LU RONG YUAN YU 715 25 July
-- 4) FU YUAN YU 9995 28 Dec 2022 (after intrep)


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
    ssvid   = '150400453'
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
SELECT *
FROM static_messages
WHERE static_name != prev_name

