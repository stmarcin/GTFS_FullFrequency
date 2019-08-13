# GTFS Full Frequency

R code to replace original frequency of public transport service in GTFS feed by a generic one, which assumes ´full frequency´ (no waiting times at public transort stops)

This repo consists of two scipts: 

- [GTFS_FullFrequency](#FullFrequency) which replaces original frequency of service by a user-defined generic one;
- [GTFS_EdgeWithTime](#EdgeWithTime) which creates new txt/shp file with edges (lines between the stops) with travel time.

[Updates](#Updates) of this repo can be found at the end of this documents. The repo is prepared within MSCA CAlCULUS project (see [Funding Statement](#Funding)).


### Table of Contents
[**script GTFS_FullFrequency**](#gtfs_fullfrequency)<br>
[**script GTFS_EdgeWithTime**](#gtfs_edgewithtime)<br>
[**Updates**](#updates)<br>
[Funding statement](#funding-statement)<br>

## GTFS_FullFrequency

### Introduction

The script is intent to replace original frequency of public transport service by a generic one (user-defined maximum waiting times at public transort stops), keeping the original travel times between stops. It is prepared in order to investige impact of public transport´s routing scheme on accessibility level (regardless applied resources, i.e. real frequency). 


### Required GTFS files  

  a) files to be simplified:
    - trips.txt
    - stop_times.txt
  b) files to be just copied to the final directory:
    - agency.txt
    - routes.txt
    - stops.txt
  c) generic files to be created for ´full frequency scenario´:
    - calendar.txt
    - frequencies.txt
  
  Source https://developers.google.com/transit/gtfs/reference/

### Workflow

1) load libraries

2) simplify trips and stop_times: only one trip per route is selected, The rest are removed.

3) recalculate arrival and departure times to start each trip at 00:00:00

4) create calendar and frequencies files

5) create a destination sub-directory for the output

6) clean the RStudio environment

### Detailed description

#### Required libraries:

```{}
library(data.table)
library(chron)
library(lubridate)
```

#### Input to be specified:

- `dir_GTFS`: directory where original GTFS files are stored. 
- `dir_final`: directory where modified GTFS files will be saved.
- `headway`: generic frequency of service; default: `60` seconds
- `GenericDate`: generic date of the service (only one day); default: `"20180515"`.
- `Threshold`: the time converage of a generic GTFS full frequency scenario. Depends on the size of the area or applied threshold for OD matrix (maximum considered travel time); default: `120`.

#### Output
- set of generic GTFS files.

#### Function syntax:

```{}
FullFrequency_GTFS(dir_GTFS, dir_final, headway = 60, GenericDate =  "20180515", Threshold = 120)
```

#### Applicaiton
The script was tested on GTFS Madrid´s data (source: `http://data-crtm.opendata.arcgis.com`).

`GTFS_frequencies_apply.R` was used to move through all folders (each folder contains GTFS data for one transport mode)

<a href="#top">**Back to top**</a>

## GTFS_EdgeWithTime

### Introduction
This script presents a function which uses orginal GFTS datasets to extracts edges between stops adding to them variable that contains travel time (minimum taken from origin stop_times.txt file). The output may be saved as `edges.txt`, `edges.shp` or both. `edges.shp` may be then used in ArcGIS network data set in order to built simplified public transport model which ingnores waiting times (frequency or exact arrival / departure times) using a simplified travel speeds (no congestion as the minimum travel time is used), i.e. the intermediate model between *intermediate PT* and *advanced PT* models defined by [Salonen & Toivonen, 2013](http://www.sciencedirect.com/science/article/pii/S096669231300121X).

There are two versions of the script:

* `GTFS_EdgeWithTime_AllDay.R` - the one which automatically generate trips for the whole day (24 hours). Due to further limitations it is **not recommended** (eg. in ArcGIS Network dataset it built too large database).
* `GTFS_EdgeWithTime_SelHH.R` - the one which enable for user-defined time range (start and end hours)

### Required GTFS files

  - stop_times.txt
  - stops.txt

### Workflow

1) load libraries

2) creare edges:
  
    + data.table with ids of arrival and departure stops;
    
    + calculate travel time between stops (minimum).

3) add stop coordinates: each row contains XY of orgin and destinatino node and travel time between them;
    
    +  (optional) save output as `edges.txt`;
    
4) (optional) create spatial representation and save output as `edges.shp`.


### Detailed description

#### Required libraries:

```{}
library(data.table)
library(chron)
library(lubridate)
library(sp)
library(sf)
```

#### Parameters to be specified:

- `dir_GTFS`: directory where original GTFS files are stored. 
- `dir_final`: directory where modified GTFS files will be saved.
- `ouput`: user defined outut:
      - `txt` - `edges.txt` file
      - `shp` - `edges.shp` set of files
      - `all` - both, `edges.txt` and `edges.shp` set of files.

Additionally version with limited time-range has two more parameters:

- `HHstart`: numeric; user defined starting hour (**default**: HHstart = 06)
- `HHend`: numeric; user defined end hour (**default**: HHend = 14)


#### Output
- `edges.txt`, `edges.shp` or both (defined by user) 

#### Function syntax - version for the whole day:

```{}
GTFS_EdgeWithTime <- function(dir_GTFS, dir_final, ouput = "shp")
```

#### Function syntach - version with limited time-range:
```{}
GTFS_EdgeWithTime_SelHH <- function(dir_GTFS, dir_final, HHstart = 06, HHend=14, output = "shp")
```



#### Applicaiton
The script was tested on GTFS Madrid´s data (source: `http://data-crtm.opendata.arcgis.com`).

`GTFS_EdgeWithTime_SelHH_apply.R` and `GTFS_EdgeWithTime_AllDay_apply.R` were used to move through all folders (each folder contains GTFS data for one transport mode).

<a href="#top">**Back to top**</a>

## Updates
2018-08-09: solved problem with arrival / departure times coded as "24:MM:SS" (HH >= 24).

2018-09-16: new script added (GTFS_EdgeWithTime.R) & update of README file.

2018-09-26: new scripts were added (GTFS_EdgeWithTime_SelHH and GTFS_EdgeWithTime_AllDay.R - the latter is to replace GTFS_EdgeWithTime.R).

<a href="#top">**Back to top**</a>

## Funding statement

This document is created within the **MSCA CAlCULUS** project.  

*This project has received funding from the European Union's Horizon 2020 research and innovation Programme under the Marie Sklodowska-Curie Grant Agreement no. 749761.*  
*The views and opinions expressed herein do not necessarily reflect those of the European Commission.*

<a href="#top">**Back to top**</a>