
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


#---------------------------------------------------------------------------------
# ```{r, echo=FALSE}
# q_voi_segs <- c("SELECT * FROM `world-fishing-827.scratch_max.AIS_segs_150_mmsi_prefix_2021_20Oct2022`")
#
# # these segments should exclude bitflipped data
# segs_150 <- fishwatchr::gfw_query(query = q_voi_segs,
#                                   run_query = TRUE,
#                                   con = con)$data
#
# not_gear_segs <- filter(segs_150, !ssvid %in% c(likely_gear$ssvid))
#
# # look at vessel numbers in each df
# n_distinct(not_gear_segs$ssvid)
# n_distinct(segs_150$ssvid)
# n_distinct(data$ssvid)
#
#
# # write out non-gear segments to see if the data of interest is still there.
# not_gear_segs %>% write_csv(here::here("data", ".", paste0("150_non_gear_segs_",str_replace_all(Sys.Date(), '-','_'),".csv")))
# # segments remove too much data

#```

#-------------------------------------------------------------------------------
# LU RONG YUAN YU 715 indidvidual vessel analysis
# mmsi_412331284 <- c("
# SELECT
#   *
# FROM `world-fishing-827.pipe_production_v20201001.messages_segmented_20221111`
# WHERE
#   ssvid = '412331284' AND
#   DATE(timestamp) BETWEEN '2020-11-01' AND DATE(CURRENT_DATE())")
#
#
# mmsi_412331284_ais <- fishwatchr::gfw_query(query = mmsi_412331284,
#                                             run_query = TRUE,
#                                             con = con)$data
# head(mmsi_412331284_ais)
#
# mmsi_412331284_ais$regions[1]$eez
#
#
# out_dat <- dplyr::select(mmsi_412331284_ais, source, type, ssvid, timestamp,
#                          lon, lat, speed, course, heading, shipname, callsign,
#                          destination, imo, shiptype, receiver_type, receiver,
#                          length, width, status)
# write.csv(out_dat, 'LRYY715 412331284.csv', row.names = F)
#
# mmsi_150400453 <- c("
# SELECT
#   *
# FROM `world-fishing-827.pipe_production_v20201001.messages_scored_20221111`
# WHERE
#   ssvid = '150400453' AND
#   DATE(timestamp) BETWEEN '2020-11-01' AND DATE(CURRENT_DATE())")
#
#
# mmsi_150400453_ais  <- fishwatchr::gfw_query(query = mmsi_150400453,
#                                              run_query = TRUE,
#                                              con = con)$data
# head(mmsi_150400453_ais)
#
#
# out_dat2 <- dplyr::select(mmsi_150400453_ais, source, type, ssvid, timestamp,
#                           lon, lat, speed, course, heading, shipname, callsign,
#                           destination, imo, shiptype, receiver_type, receiver,
#                           length, width, status)
# write.csv(out_dat2, 'LRYY715 150400453.csv', row.names = F)

