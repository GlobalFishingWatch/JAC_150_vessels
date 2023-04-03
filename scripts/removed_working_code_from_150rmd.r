
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



# plot one section of code in equal eartth

# g1 <- filter(lryy715_time_lines, group == '150400453_3')
#
# g1_et <- g1 %>% mutate(time_diff = difftime( timestamp, lag(timestamp), units = c("days")))
# max(g1_et$time_diff, na.rm=t)
# min(g1_et$time_diff, na.rm=t)
#
# test <- filter(lryy715_time_lines, ssvid == '150400453',
#                between(as.Date(timestamp), as.Date('2021-09-15'), as.Date('2021-09-30')))
#
#
# test_q <- c("SELECT *
# FROM `world-fishing-827.pipe_production_v20201001.research_messages`
# WHERE
#   DATE(_PARTITIONTIME) BETWEEN '2021-09-15' AND '2021-09-30'
#   AND ssvid = '150400453'
#   AND seg_id IN (SELECT seg_id FROM world-fishing-827.pipe_production_v20201001.research_segs WHERE good_seg IS TRUE AND overlapping_and_short IS FALSE)")
# good_seg <- fishwatchr::gfw_query(query = test_q,
#                                   run_query = TRUE,
#                                   con = con)$data
#
# bounding <- transform_box(xlim = c(-110, -30),
#                           ylim = c(0, -60),
#                           output_crs = fishwatchr::gfw_projections("South Atlantic")$proj_string)
#
# View(good_seg %>% arrange(timestamp))
#
# test_g1 <- good_seg %>%
#   filter(!is.na(lat)) %>%
#   arrange(timestamp) %>%
#   sf::st_as_sf(.,
#                coords = c("lon", "lat"),
#                crs = 4326) %>%
#   group_by(ssvid) %>%
#   summarize() %>%
#   sf::st_cast(., "LINESTRING") %>%
#   fishwatchr::recenter_sf(., center = new_center)
#
# ggplot() +
#   geom_gfw_outline(center = new_center,
#                    theme = "dark") +
#   geom_gfw_land(center = new_center) +
#   geom_sf(
#     data = test_g1,
#     aes(color = ssvid, group = ssvid) #,
#     #color = fishwatchr::gfw_palettes$secondary[2]
#   ) +
#   # geom_sf(
#   #   data = recenter_lryy715_points,
#   #   color = fishwatchr::gfw_palettes$secondary[1],
#   #   size = 0.5
#   # ) +
#   theme_gfw_map(theme = "light")
#
# ggplot(good_seg %>% arrange(timestamp)) +
#   geom_path(aes(x=lon, y=lat))


# light centered map removed


# create bounding box for plot to set bounds
bounding <- transform_box(xlim = c(-95, -30),
                          ylim = c(0, -55),
                          output_crs = gfw_projections("Equal Earth")$proj)

# make a
regional_map_light <- gfw_map(theme = 'light', res = 10) +
  coord_sf(xlim = c(bounding$box_out[['xmin']], bounding$box_out[['xmax']]),
           ylim = c(bounding$box_out[['ymin']], bounding$box_out[['ymax']]),
           crs = bounding$out_crs)

daily_identity_points <- filter(daily_identity, !is.na(shipname_g)) %>%
  sf::st_as_sf(.,
               coords = c("lon", "lat"),
               crs = 4326)

# daily_identity_points_trans <- st_transform(daily_identity_points, crs=bounding$out_crs)
daily_identity_points_trans <- st_transform(daily_identity_points, crs=4326)

map <- ggplot() +
  # geom_gfw_outline(center = new_center,
  #                  theme = "dark")
  # regional_map_light +
  geom_gfw_land(theme = 'light', proj = gfw_projections("Equal Earth")$proj) +
  geom_gfw_eez(proj = gfw_projections("Equal Earth")$proj, colour='black') +
  geom_sf(
    # data = daily_identity,
    #   aes(x=lon, y=lat, color = shipname_g),
    data = dplyr::select(daily_identity_points_trans,-avg_lat_lon),
    aes( color = shipname_g),
    size = 1.5
    #color = fishwatchr::gfw_palettes$secondary[2]
  ) +
  #geom_gfw_eez(theme = 'light', center = new_center, alpha = 0.2) +
  # scale_colour_manual(values = gfw_palettes$tracks) +
  theme_gfw_map(theme = "light") +
  theme(legend.position="right", ) +
  labs(colour = 'Name Group') +
  coord_sf(xlim = c(bounding$box_out[['xmin']], bounding$box_out[['xmax']]),
           ylim = c(bounding$box_out[['ymin']], bounding$box_out[['ymax']]),
           crs = bounding$out_crs)


#-------------------------------------------------------------------------------
# spoofing query
# SELECT
# *
#   FROM
# `world-fishing-827.gfw_research_precursors.offsetting_year_seg_v20230126`
# WHERE
# ssvid IN (SELECT CAST(ssvid AS string) FROM `world-fishing-827.scratch_max.150_voi_ssvid`)
# OR ssvid IN ('412331285', '412420574', '412334074', '412420659','412440717', '412440716', '412336962', '412331283',
#              '412331285', '412331284', '412331282', '412331281', '412331279')
# AND year IN (2020, 2021, 2022)


# -----------------------------------------------------------------------------
# implausible speed query
#
# WITH implausible_speeds AS(
#   SELECT
#   *
#     FROM `world-fishing-827.pipe_production_v20201001.research_messages`
#   WHERE
#   DATE(_partitiontime) BETWEEN "2020-01-01" AND "2022-12-31"
#   AND implied_speed_knots > 20
# )
#
# SELECT
# * EXCEPT (regions)
# FROM implausible_speeds
# WHERE
# ssvid IN (SELECT CAST(ssvid AS string) FROM `world-fishing-827.scratch_max.150_voi_ssvid`)
# OR ssvid IN ('412331285', '412420574', '412334074', '412420659','412440717', '412440716', '412336962', '412331283',
#              '412331285', '412331284', '412331282', '412331281', '412331279')
