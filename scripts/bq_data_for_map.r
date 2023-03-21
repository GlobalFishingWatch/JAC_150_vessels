# aggregate the data to rasterfy on map, need fields lat, lon, timestamp, ssvid, and a value to work with
# map_df <- focal %>% mutate(lat_bin = round(lat, 1), lon_bin = round(lon, 1)) %>%
#   group_by(ssvid, timestamp, lat_bin, lon_bin) %>%
#     summarise(positions = n(),
#               vessels = n_distinct(ssvid))
#
# map_df %>%
#   bigrquery::bq_table_upload(x = bigrquery::bq_table(project = "world-fishing-827",
#                                                    dataset = "scratch_max",
#                                                    table = "150_voi_from_R"),
#                             values = .)
# GFW map query
# SELECT
# CAST(ssvid AS STRING) AS id,
# timestamp,
# lat_bin AS lat,
# lon_bin AS lon,
# CAST(positions AS FLOAT64)AS value,
# FROM `world-fishing-827.scratch_max.150_voi_from_R`
