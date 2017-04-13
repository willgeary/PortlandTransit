

###### Load libraries ------------

library(data.table)
library(magrittr)
library(dplyr)
library(sf)
library(sp)
library(rgdal)
library(ggplot2)
library(ggthemes)
library(gganimate)



###### Load GTFS data ------------

# Indicate GTFS file
  gtfs_file <- "./data.zip"

# read GTFS text files
  routes <- fread(unzip (gtfs_file, "routes.txt"))         # get route_id
  trips <- fread(unzip (gtfs_file, "trips.txt"))           # get trip_id
  stop_times <- fread(unzip (gtfs_file, "stop_times.txt")) # get stop_id
  stops <- fread(unzip (gtfs_file, "stops.txt"))           # get stop_id + lat long
  shapes <- fread(unzip (gtfs_file, "shapes.txt"))         # get stop_id + lat long

# convert coordinates to numeric
  shapes[, shape_pt_lat := as.numeric(shape_pt_lat) ][, shape_pt_lon := as.numeric(shape_pt_lon) ]
  stops[, stop_lon := as.numeric(stop_lon) ][, stop_lat := as.numeric(stop_lat) ]


###### Find locations of stop_id along route shapes ------------

# Convert stops and shapes into sf format

 # stops
   coordinates(stops) = ~stop_lon+stop_lat
   stops_sf = st_as_sf(stops)
 # shapes
   coordinates(shapes) = ~shape_pt_lon+shape_pt_lat
   shapes_sf = st_as_sf(shapes)


# assign CRS / spatial projection
   st_crs(stops_sf) <- st_crs("+proj=longlat +ellps=WGS84")
   st_crs(shapes_sf) <- st_crs("+proj=longlat +ellps=WGS84")


# Creater a 10 meter buffer around each stop
  ?st_buffer(x, dist, nQuadSegs = 30)

# Overlay stop buffers with lat/long points of route shapes



###### Bind all datasets together ------------

total_df <- left_join(stop_times, stops, by="stop_id")
total_df <- left_join(total_df, trips, by="trip_id")
total_df <- left_join(total_df, routes, by="route_id") %>% setDT()


###### Interpolate time between arrival times for each route/trip/direction ------------

data.table







