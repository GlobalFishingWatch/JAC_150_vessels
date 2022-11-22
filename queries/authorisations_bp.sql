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
  JOIN
    voi USING (ssvid)
  WHERE
    year IN (2021, 2022)
),


sprfmo AS(
  SELECT
    DISTINCT ssvid
  FROM
    auth
  WHERE
    registry IN ('CHINASPRFMO', 'SPRFMO', 'SPRFMO2')
),


chn_dwf AS(
  SELECT
    DISTINCT ssvid
  FROM
    auth
  WHERE
    registry IN ('CHINAFISHING') AND
    ssvid NOT IN (SELECT ssvid FROM sprfmo)
),

imo AS(
  SELECT
    DISTINCT ssvid
  FROM
    auth
  WHERE
    registry IN ('IMO', 'IMO3')AND
    ssvid NOT IN (SELECT ssvid FROM chn_dwf)
),


IUU AS(
  SELECT
    DISTINCT ssvid
  FROM
    auth
  WHERE
    registry IN ('IUU')
),

-- grouped_auth AS (
--   SELECT
--     DISTINCT ssvid,
--     CASE
--       WHEN ssvid IN (SELECT ssvid FROM chn_dwf) AND ssvid IN (SELECT ssvid FROM squid_rfmo) AND ssvid IN (SELECT ssvid FROM imo) THEN 'chn_sprfmo_imo'
--       WHEN (ssvid IN (SELECT ssvid FROM chn_dwf) AND ssvid IN (SELECT ssvid FROM squid_rfmo)) THEN 'chn_sprfmo'
--       WHEN (ssvid IN (SELECT ssvid FROM chn_dwf) AND ssvid IN (SELECT ssvid FROM imo)) THEN 'chn_imo'
--       WHEN (ssvid IN (SELECT ssvid FROM imo) AND ssvid IN (SELECT ssvid FROM squid_rfmo)) THEN 'sprfmo_imo'
--       WHEN ssvid IN (SELECT ssvid FROM chn_dwf) OR
--            ssvid IN (SELECT ssvid FROM chn_dwf) OR
--            ssvid IN (SELECT ssvid FROM imo) THEN 'one'
--       ELSE 'none'
--     END AS authorisation
--   FROM
--     auth
-- )


grouped_auth AS (
  SELECT
    DISTINCT ssvid,
    CASE
      WHEN ssvid IN (SELECT ssvid FROM sprfmo) THEN 'SPRFMO'
      WHEN ssvid IN (SELECT ssvid FROM chn_dwf)  THEN 'CHN_DWF'
      WHEN ssvid IN (SELECT ssvid FROM imo)  THEN 'IMO'
      ELSE 'none'
    END AS authorisation
  FROM
    auth
)

SELECT * FROM auth
