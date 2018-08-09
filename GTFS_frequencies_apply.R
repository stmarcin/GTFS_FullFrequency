# list all folders with GTFS files
ListGTFS <- list.dirs("../DATA/Data_GTFS/Data_GTFS_oryg/", recursive=FALSE)

# load script GTFS_frequencies.R
source('RScripts/GTFS_frequencies.R')

# loop through all folders
for(dirs in ListGTFS){
  # prepare input and output directory
  dirs <- gsub("//", "/", dirs)  
  DirLoc <- dirs
  DirFinal <- gsub("Data_GTFS_oryg", "Data_GTFS_FullFreq", DirLoc)
  
  #execute function FullFrequency_GTFS
  FullFrequency_GTFS(dir_GTFS = DirLoc , dir_final = DirFinal, Threshold = 180)
  
}







