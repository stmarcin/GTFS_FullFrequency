# list all folders with GTFS files
ListGTFS <- list.dirs("../DATA/Data_GTFS/Data_GTFS_oryg2/", recursive=FALSE)

# load script GTFS_EdgeWithTime.R
source('RScripts/Frequencies/GTFS_EdgeWithTime_AllDay.R')

# loop through all folders
for(dirs in ListGTFS){
  # prepare input and output directory
  dirs <- gsub("//", "/", dirs)  
  DirLoc <- dirs
  DirFinal <- gsub("Data_GTFS_oryg2", "Data_GTFS_NoWaitingTime_AllDay", DirLoc)
  
  GTFS_EdgeWithTime(dir_GTFS = DirLoc , dir_final = DirFinal, output = "all")
  
}

