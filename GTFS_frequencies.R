# loading of libraries -----------------------------------------------------------
library(data.table)


# proba 1 -----------------------------------------------------------
# define location of original directory of GTFS files, headway
DirLoc <- "../DATA/Data_GTFS/Data_GTFS_oryg/google_transit_M10"
DirFinal <- "../DATA/Data_GTFS/Data_GTFS_FullFreq2/google_transit_M10"
headway = 60 # przy przerabianiu na funkcje - ustawic 60 jako domyslna wartosc
StartDate = "20170101" # przy przerabianiu na funkcje - ustawic jako domyslna wartosc
EndDate =  "20181231" # przy przerabianiu na funkcje - ustawic jako domyslna wartosc

# create list of existing files
#list_GTFS <- list.files(DirLoc, pattern = ".txt")

# open required files: trips, stop_times
trips <- fread(paste(DirLoc, "trips.txt", sep = "/"))
stop_times <- fread(paste(DirLoc, "stop_times.txt", sep = "/"))

# for each route select one (first) trip (if they are two different headings: 2)
# replace trips table
trips <- trips[,.SD[1],by=.(route_id,trip_headsign) ]

# based on ListRoutes select rows from stop_times and replace table stop_times
stop_times <- stop_times[trips[,.(trip_id)], on="trip_id"]

# create frequencies with predfined headway
frequencies <- data.table(trip_id = trips$trip_id,
                          start_time = "06:00:00",
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




