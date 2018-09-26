

GTFS_EdgeWithTime_SelHH <- function(dir_GTFS, dir_final, HHstart = 06, HHend=14, output = "shp"){
  

    # 1) load libraries -----------------------------------------------------------
    Packages <- c("data.table", "chron", "lubridate", "sp", "sf")
    lapply(Packages, library, character.only = TRUE)
    rm(Packages)
    
    # 2) creates "edges" with minimum travel_time (in minutes) between stop_idO and stop_idD ----
    
    # Open stop_times file:
    stop_times <- fread(paste(dir_GTFS, "stop_times.txt", sep = "/"))[,.(trip_id, stop_sequence, arrival_time, departure_time, stop_id)]
    stop_times <- stop_times[as.numeric(substr(arrival_time,1,2)) >= HHstart & as.numeric(substr(arrival_time,1,2)) < HHend]
    
    
    # Create empty data table for the stop_times output; define required columns
    Names_edges <- c("stop_idO", "stop_id", "travel_time")
    edges <- setNames(data.table(matrix(nrow = 0, ncol = 3)), Names_edges)
    
    # OD nodes & travel time between them for all trips  
    for(trip in unlist(unique(stop_times[,.(trip_id)])) ){
      
      # select stop_times for selected trip
      TempST <- stop_times[trip_id == trip]  
      
      if(nrow(TempST) > 1){
        TempST[, c("stop_idO", "travel_time") := list(shift(stop_id), 
                                                      round(as.numeric(times(chron(times = chron(times = arrival_time) - 
                                                                                     (chron(times = shift(departure_time)) ))))*60*24, 2) ) ] 
      
        # add rows (except first) to edges
        edges <- rbind(edges, TempST[-1,..Names_edges])
        rm(TempST, trip) }
    }
    
    # group edges selecting minumum travel time and set names "O"=origin, "D"=destination, "travel_time" (in minutes)
    edges <- edges[, .(min(travel_time)), by = c("stop_idO", "stop_id")]
    setnames(edges, -1, c("stop_idD", "travel_time"))
    
    # remove unnecessary files
    rm(Names_edges, stop_times)
    
    # 3) add stops coordinates (origin and destinations X, Y in columns OX, OY, DX, DY) ----
    # Open stops file:
    stops <- fread(paste(dir_GTFS, "stops.txt", sep = "/"))
    
    # merge orgins to gets their coordinates: origin
    edges <- merge(edges, stops[, .(stop_id, stop_lon, stop_lat)], by.x="stop_idO", by.y = "stop_id")
    setnames(edges, c("stop_lon", "stop_lat"), c("OX", "OY"))
    
    edges <- merge(edges, stops[, .(stop_id, stop_lon, stop_lat)], by.x="stop_idD", by.y = "stop_id")
    setnames(edges, c("stop_lon", "stop_lat"), c("DX", "DY"))
    
    # create the directory for the output
    dir.create(dir_final)
    
    # (optional) save output as txt file
    if(output == "txt" | output == "all" ){
      fwrite(edges, paste(dir_final, "edges.txt", sep = "/")) }
    
    # 4) create spatial representation and save outputs to shapefile
    # using this stackoverflow Q&A as an inspiration: 
    # https://stackoverflow.com/questions/20531066/convert-begin-and-end-coordinates-into-spatial-lines-in-r
    
    if(output == "shp" | output == "all" ){
      # create a raw list to story lines
      edges_sf <- vector("list", nrow(edges))
      
      # Create list of simple feature geometries (linestrings)
      for (i in seq_along(edges_sf)){
        edges_sf[[i]] <- st_linestring(as.matrix(rbind(setnames(edges[i,.(OX, OY)], 
                                                        c("CoordX", "CoordY")), setnames(edges[i,.(DX, DY)], c("CoordX", "CoordY")))))
      }
      rm(i) # remove it as it is no needed anymore. 
      
      # Create simple feature geometry list column
      edges_sfc <- st_sfc(edges_sf, crs = "+proj=longlat +datum=WGS84")
      
      # populate data attached to lines by values from original edges file:
      edges_sf = st_sf(id = 1:nrow(edges), 
                       travel_time = edges[,.(travel_time)], 
                       stop_idO =  edges[,.(stop_idO)], 
                       stop_idD =  edges[,.(stop_idD)], 
                       geometry = edges_sfc)
      
      # save output as shapefile
      st_write(edges_sf, paste(dir_final, "edges_sf.shp", sep="/"), delete_layer = TRUE) }
    
}
