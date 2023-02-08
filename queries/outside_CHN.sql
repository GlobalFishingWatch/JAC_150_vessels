WITH all_vessels AS (
  SELECT
    *
  FROM
    `world-fishing-827.scratch_max.raw_AIS_150_mmsi_prefix_2020_2022`
  WHERE
    lon BETWEEN -180 AND 180 AND
    lat BETWEEN -90 AND 90),

-- pull out Chinese EEZ
CHN_EEZ AS (
  SELECT
    wkt
  FROM
    `world-fishing-827.ocean_shapefiles_all_purpose.marine_regions_v11`
  WHERE
    ISO_SOV1 = 'CHN' AND
    POL_TYPE = '200NM'
),

CHN_EEZ_land AS (
  SELECT
    *
  FROM
    `world-fishing-827.pipe_regions_layers.EEZ_land_union_v3_202003`
  WHERE
    ISO_SOV1 = 'CHN' AND
    POL_TYPE = 'Union EEZ and country'
)

-- SELECT wkt FROM CHN_EEZ

-- identify vessels with transmissions outside CHN EEZ
  SELECT
    ssvid,
    timestamp,
    type,
    shipname,
    callsign,
    lat,
    lon,
    speed,
  FROM
    all_vessels, CHN_EEZ_land
  WHERE NOT
    ST_CONTAINS(CHN_EEZ_land.geometry, ST_GEOGPOINT(lon, lat))
