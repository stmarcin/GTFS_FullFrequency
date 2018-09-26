# list all folders with GTFS files
ListGTFS <- list.dirs("../DATA/Data_GTFS/Data_GTFS_oryg3/", recursive=FALSE)

# load script GTFS_EdgeWithTime.R
source('RScripts/Frequencies/GTFS_EdgeWithTime_SelHH.R')

HHstart <- 06
HHend <- 14
output = "all"

# loop through all folders
for(dirs in ListGTFS){
  # prepare input and output directory
  dirs <- gsub("//", "/", dirs)  
  DirFinal <- gsub("Data_GTFS_oryg2", "Data_GTFS_NoWaitingTime_SelHH", dirs)
  
  GTFS_EdgeWithTime(dir_GTFS = dirs , dir_final = DirFinal, output = "all")
  
}

rm(list = ls())
