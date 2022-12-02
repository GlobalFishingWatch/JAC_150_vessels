-------------------------------------
-- Query to identify squid vessel
-- positions in each EEZ
--
-- MS 25Nov2022
--
-- use existing Bahia Posesion table of AIS for activity
-- been having trouble with joins from eez_activity not working because of INT and string
--
-------------------------------------
--
WITH

eez_activity AS(
  SELECT
    ssvid,
    EXTRACT(year FROM date) AS year,
    EXTRACT(month FROM date) as month,
    date,
    CAST(eez_id AS int) AS eez_id,
    -- e.territory_iso3 AS eez,
    COUNT(*) positions,
    SUM(hours) total_hours,
    SUM(IF(night_loitering = 1, hours, 0)) AS fishing_hours
  FROM
    `world-fishing-827.scratch_max.bahiaposession_voi_ais_2021_2022_v2` bp
  WHERE eez_id IS NOT NULL
  GROUP BY 1,2,3,4,5
),

-- pull out the eez info
eez_info AS (
  SELECT eez_id, territory1_iso3 AS eez FROM `world-fishing-827.gfw_research.eez_info`
)

SELECT
  *
FROM
  eez_activity
LEFT JOIN eez_info e USING (eez_id)
