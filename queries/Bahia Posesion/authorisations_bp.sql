--------------------------------------------------------------------------------
-- Pulling authorisation information of vessels with from vessels operating in Bahia Posesion

-- Author: Max Schofield
-- Date: 21 November 2022
--------------------------------------------------------------------------------

 -- VOI from existing table
 -- authorisations from ssvid

--------------------------------------------------------------------------------


WITH

----------------------------------------------------------
-- Define fleet of interest
----------------------------------------------------------

voi AS (
  SELECT
    DISTINCT ssvid
  FROM
    `world-fishing-827.scratch_max.bahia_posesion_raw_ais`
),

----------------------------------------------------------
-- Pull there authorisations
----------------------------------------------------------

auth AS (
  SELECT
    ssvid,
    -- EXTRACT(YEAR FROM activity.last_timestamp) AS year,
    best.best_flag AS best_flag,
    best.best_vessel_class AS best_vessel_class,
    ais_identity.n_shipname_mostcommon.value AS vessel_name,
    -- ais_identity.n_shipname.value AS n_names,
    registry,
    year
  FROM
    -- IMPORTANT: change below to most up to date table
    `world-fishing-827.gfw_research.vi_ssvid_byyear_v20221001`,
    UNNEST(registry_info.registries_listed) AS registry
  WHERE
    year IN (2021, 2022)
),

all_ves AS (
   SELECT
      *
   FROM
      voi
   LEFT JOIN auth USING (ssvid)
)


SELECT * FROM all_ves
