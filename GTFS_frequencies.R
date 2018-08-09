

FullFrequency_GTFS <- function(dir_GTFS, dir_final, headway = 60, GenericDate =  "20180515", Threshold = 120){

  # 1) load libraries -----------------------------------------------------------
  library(data.table)
  library(chron)
  library(lubridate)
  
  # 2) open and simplify required files: trips, stop_times ----
  trips <- fread(paste(dir_GTFS, "trips.txt", sep = "/"))
  stop_times <- fread(paste(dir_GTFS, "stop_times.txt", sep = "/"))
  
  # for each route select one (first) trip (if they are two different headings: 2)
  # replace trips table
  trips <- trips[,.SD[1],by=.(route_id,trip_headsign) ]
  
  # based on ListRoutes select rows from stop_times and replace table stop_times
  stop_times <- stop_times[trips[,.(trip_id)], on="trip_id"]
  
  # 3) recalculate arrival and departure times (starting from 00:00:00) ----
  
  # Create empty data table for the stop_times output
  Tstop_times <- setNames(data.table(matrix(nrow = 0, ncol = ncol(stop_times))), names(stop_times))
  
  for(trip in unlist(trips[,.(trip_id)])){
    # select stop.times of selected trip:
    TempST <- stop_times[trip_id == trip]
    
    # in case of arrival / departure time formatted as: "24:MM:SS" (H >= 24) - add +1 day and substract 24 hours
    TempST[, c("aday", "dday") := list(ifelse(substr(arrival_time,1,2) < 24, 0, 1), ifelse(substr(departure_time,1,2) < 24, 0, 1))]
    
    TempST[, c("arrival_time", "departure_time") := 
             list(ifelse(substr(arrival_time,1,2) < 24, arrival_time, 
                         paste(paste("0", as.numeric(substr(arrival_time,1,2))-24, sep=""), substr(arrival_time,3,8), sep="")), 
                  ifelse(substr(departure_time,1,2) < 24, departure_time,
                         paste(paste("0", as.numeric(substr(departure_time,1,2))-24, sep=""), substr(departure_time,3,8), sep="")))]
    
    
    # calculate stop time (difference between arrival and departure time):
    TempST[, stop_time := chron(times = chron(times = arrival_time) + aday - (chron(times = departure_time) + dday))]
    
    # calculate travel time from previous to the given stop
    TempST[, travel_time := 
             chron(times = chron(times = arrival_time) + aday - (chron(times = shift(departure_time)) + shift(dday))) ]

    # calculate arrival and departure times for the first stop (00:00:00)
    TempST[stop_sequence == 0, atime := chron(times = "00:00:00")]
    TempST[stop_sequence == 0, dtime := chron(times = atime + stop_time)]
    
    
    # calculate arrival and departure time for the rest of stops
    i = 1
    while(i <= nrow(TempST)-1){
      
      TempST[stop_sequence==i, atime := chron(times = TempST[stop_sequence == i-1, dtime] + travel_time)]
      TempST[stop_sequence==i, dtime := chron(times = atime + stop_time)]
      i = i + 1
    }
    
    # convert calculated columns and combine results
    TempST[, c("arrival_time", "departure_time") := list(as.character(atime), as.character(dtime))]
    Tstop_times <- rbind(Tstop_times, TempST[,-c("atime","dtime", "stop_time", "travel_time"), with=F])
    
  }  
  
  # replace oryginal stop_times 
  stop_times <- Tstop_times
  rm(i, TempST, trip, Tstop_times)  
  
  # 4) create calendar and frequencies files ----
  # create frequencies with predfined headway
  frequencies <- data.table(trip_id = trips$trip_id,
                            start_time = "00:00:00",
                            end_time = as.character(times("00:00:00") + Threshold/24/60),
                            headway_secs = headway)
  # headway is no necessary any more so it's to be removed
  rm(headway)
  
  # create calendar table: 
  calendar <- data.table(service_id = trips$service_id,
                         monday = "1",   
                         tuesday = "1",
                         wednesday = "1",
                         thursday = "1",
                         friday = "1",
                         saturday = "1",
                         sunday = "1",
                         start_date = GenericDate,
                         end_date = format(ymd(GenericDate)+ddays(1), "%Y%m%d"))
  
  # 5) save output ----
  # create the directory for the output
  dir.create(dir_final)
  
  # save output in the destination folder
  fwrite(calendar, paste(dir_final, paste("calendar", "txt", sep="."), sep = "/"))
  fwrite(frequencies, paste(dir_final, paste("frequencies", "txt", sep="."), sep = "/"))
  fwrite(stop_times, paste(dir_final, paste("stop_times", "txt", sep="."), sep = "/"))
  fwrite(trips, paste(dir_final, paste("trips", "txt", sep="."), sep = "/"))
  
  # copy the rest of requiered GTFS files into the destination folder; remove from workspace
  list_GTFS <- c("agency", "routes", "stops")
  
  for(file_GTFS in list_GTFS){
    Temp <- fread(paste(dir_GTFS, paste(file_GTFS, "txt", sep="."), sep = "/"))
    fwrite(Temp, paste(dir_final, paste(file_GTFS, "txt", sep="."), sep = "/"))
  }
  
  # 6) clean environment
  rm(list=ls(all=TRUE))

}


