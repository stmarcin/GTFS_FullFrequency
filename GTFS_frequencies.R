# loading of libraries -----------------------------------------------------------
library(data.table)
library(chron)
library(lubridate)


# define location of original directory of GTFS files, headway ----
DirLoc <- "../DATA/Data_GTFS/Data_GTFS_oryg/google_transit_M10"
DirFinal <- "../DATA/Data_GTFS/Data_GTFS_FullFreq/google_transit_M10"
headway = 60 # przy przerabianiu na funkcje - ustawic 60 jako domyslna wartosc
# GenericDate = 

StartDate = "20170101" # przy przerabianiu na funkcje - ustawic jako domyslna wartosc
EndDate =  "20181231" # przy przerabianiu na funkcje - ustawic jako domyslna wartosc
StartTime = "00:00:00"

# open and simplify required files: trips, stop_times ----
trips <- fread(paste(DirLoc, "trips.txt", sep = "/"))
stop_times <- fread(paste(DirLoc, "stop_times.txt", sep = "/"))

# for each route select one (first) trip (if they are two different headings: 2)
# replace trips table
trips <- trips[,.SD[1],by=.(route_id,trip_headsign) ]

# based on ListRoutes select rows from stop_times and replace table stop_times
stop_times <- stop_times[trips[,.(trip_id)], on="trip_id"]

# recalculate arrival and departure times (starting from 00:00:00) ----

# Create empty data table for the stop_times output
Tstop_times <- setNames(data.table(matrix(nrow = 0, ncol = ncol(stop_times))), names(stop_times))

for(trip in unlist(trips[,.(trip_id)])){
  # select stop.times of selected trip:
  TempST <- stop_times[trip_id == trip]
  
  # calculate stop time (difference between arrival and departure time):
  TempST[,stop_time := chron(times = format(ymd("2017-01-01", tz = "UTC")+
                                              as.duration(as.POSIXct(departure_time, format='%H:%M:%S') - 
                                                            as.POSIXct(arrival_time, format='%H:%M:%S')), "%H:%M:%S"))]
  
  # calculate travel time from previous to the given stop
  TempST[, travel_time := chron(times = format(ymd("2017-01-01", tz = "UTC")+
                                                 as.duration(as.POSIXct(departure_time, format='%H:%M:%S') - 
                                                               as.POSIXct(shift(departure_time), format='%H:%M:%S')), "%H:%M:%S"))]
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

# create calendar and frequencies files ----
# create frequencies with predfined headway
frequencies <- data.table(trip_id = trips$trip_id,
                          start_time = StartTime,
                          end_time = "10:00:00",
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
                       start_date = StartDate,
                       end_date = EndDate)
# remove Start and End Date as they are no necessary any more
rm(StartDate, EndDate)

# save output ----
# create the directory for the output
dir.create(DirFinal)

# save output in the destination folder
fwrite(calendar, paste(DirFinal, paste("calendar", "txt", sep="."), sep = "/"))
fwrite(frequencies, paste(DirFinal, paste("frequencies", "txt", sep="."), sep = "/"))
fwrite(stop_times, paste(DirFinal, paste("stop_times", "txt", sep="."), sep = "/"))
fwrite(trips, paste(DirFinal, paste("trips", "txt", sep="."), sep = "/"))

# copy the rest of requiered GTFS files into the destination folder; remove from workspace
list_GTFS <- c("agency", "routes", "stops")

for(file_GTFS in list_GTFS){
  Temp <- fread(paste(DirLoc, paste(file_GTFS, "txt", sep="."), sep = "/"))
  fwrite(Temp, paste(DirFinal, paste(file_GTFS, "txt", sep="."), sep = "/"))
}
rm(list_GTFS, file_GTFS, Temp)

# remove the rest of files
rm(list=ls(all=TRUE))




