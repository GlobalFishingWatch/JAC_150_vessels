
# write it out to visaulise
# write.csv(outside_chn_more_then10, '../data/active_outside_chn.csv', row.names = F)


# # look at data dropped by the more then 10 criteria
# removed <- data %>% filter(!ssvid %in% (more_then10$ssvid))
# write.csv(removed, '../data/removed.csv', row.names = F)
# check_ids <-  removed %>% group_by(ssvid) %>% summarise(trans=n()) %>% filter(trans>10)
#
# check <- filter(removed,  ssvid %in% check_ids$ssvid)
# write.csv(check, '../data/check.csv', row.names = F)
# # working as expected


# filter the whole dataset to only retain the active outside of china vessels (with their china transmissions)
focal <- all_150_ais %>% filter(ssvid %in% unique(outside_chn_more_then10$ssvid))
focal <- focal[!is.na(focal$lat) & !is.na(focal$lon) ,]
# focal <- voi_ais %>% filter(ssvid %in% unique(active_outside_chn$ssvid))
# write.csv(focal, '../data/all_ais_150_active.csv', row.names = F)

# voi %>% group_by(ssvid) %>% arrange(ssvid, timestamp) %>% mutate(time = difftime(timestamp, lag(timestamp)))

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
