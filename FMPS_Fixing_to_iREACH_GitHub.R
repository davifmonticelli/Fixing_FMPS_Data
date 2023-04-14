# Script created by: Davi de Ferreyro Monticelli (PhD student in Atmospheric Sciences at University of British Columbia
# Supervisor: Dr. Naomi Zimmermnan
# Version: 1.0.0
# Date: 2023-04-06
# Objective: Read TSI WCPC and FMPS data, modify files to account for lag time and time series alignement, and change FMPS signal
#            according to Zimmerman et al. (2015) paper (https://wwww.sciencedirect.com/science/article/pii/S1352231014008516)

# WCPC: Water Condensation Particle Counter
# FMPS: Fast Mobility Particle Spectrometer

##############################################################################
# step 1: Load raw FMPS and WCPC data
##############################################################################

library(readxl) # input files are .xlsx (but code can be easily modified if they are .csv)

############# WCPC Data #####################################################

# Note: WCPC files should be formatted in the following way:
# 2 Columns, 
#    1st column named "date" containing the measurement time (YYYY-MM-DD HH:MM:SS)
#    2nd column named "WCPC" containing the concentration values for the respective measurement time

# Example:
# date                     WCPC
# 2022-08-02  8:18:06 AM   2233.23
# 2022-08-02  8:18:07 AM   2233.23
# 2022-08-02  8:18:08 AM   2233.23
# 2022-08-02  8:18:09 AM   2233.23
# 2022-08-02  8:18:10 AM   2233.23

# Files should also follow a naming convention "WCPC_XX_XX_XX" where "XX_XX_XX" represents the sampling date
# Example: "WCPC_02_08_22" corresponding to a sampling made on August 2nd of 2022

# Set directory containing the files (WCPC and FMPS files must be in the same location)
setwd("path/to/directory") # this is user specified, example: C:/Users/davi_/Downloads/PhD/Dissertation/PLUME_Data_Dashboard/WCPC and FMPS Exports/to R

# get a list of all "WCPC_XX_XX_XX" files in the specified directory
file_list <- list.files(pattern = "^WCPC_")

# loop through the list of files and load each as a dataframe file with the same name
for(file in file_list) {
  # read in the file name
  file_name = gsub("\\.xlsx$", "", file) # change ".xlsx" to ".csv" if appropriate
  
  # Create an auxiliary data frame
  aux_dataframe = read_excel(file, col_types = c("date", "numeric")) # change to read.csv accordingly
  
  # Create a data frame with the same name as of the file
  assign(file_name, aux_dataframe)
  # Remove auxiliary data frame
  rm(aux_dataframe)
}

############# FMPS Data #####################################################

# Note: FMPS files should be formatted in the following way:
# 33 Columns, 
#    1st column named "date" containing the measurement time (YYYY-MM-DD HH:MM:SS)
#    Columns 2 to 33 correspond to the raw concentration values for the respective measurement time and mid-point size bin
#    Columns 2 to 33 can be named the mid-point size bin value (it will be changed multiple times throughoutthe script)

# WARNING : FMPS data should be raw data (directly from the instrument), DO NOT apply the N/16 correction, this will be done later

# Example:
# date                     6.04       6.98     (...)   523.3  
# 2022-08-02  8:18:06 AM   2233.23    2233.23          2233.23
# 2022-08-02  8:18:07 AM   2233.23    2233.23          2233.23
# 2022-08-02  8:18:08 AM   2233.23    2233.23          2233.23
# 2022-08-02  8:18:09 AM   2233.23    2233.23          2233.23
# 2022-08-02  8:18:10 AM   2233.23    2233.23          2233.23

# Files should also follow a naming convention "FMPS_XX_XX_XX" where "XX_XX_XX" represents the sampling date
# Example: "FMPS_02_08_22" Corresponding to a sampling made on August 2nd of 2022

# Since R does not allow directory to be changed mid-way through a script, we will get the files from the same directory as WCPC data

# get a list of all "FMPS_XX_XX_XX" files from directory
file_list <- list.files(pattern = "^FMPS_")

# loop through the list of files and load each as a dataframe file with the same name
for(file in file_list) {
  # read in the file name
  file_name = gsub("\\.xlsx$", "", file) # change ".xlsx" to ".csv" if appropriate
  
  # Create an auxiliary data frame (change to read.csv accordingly)
  aux_dataframe = read_excel(file, col_types = c("date", "numeric", "numeric", "numeric", "numeric", "numeric", 
                                                                               "numeric", "numeric", "numeric", 
                                                                               "numeric", "numeric", "numeric", 
                                                                               "numeric", "numeric", "numeric", 
                                                                               "numeric", "numeric", "numeric", 
                                                                               "numeric", "numeric", "numeric", 
                                                                               "numeric", "numeric", "numeric", 
                                                                               "numeric", "numeric", "numeric", 
                                                                               "numeric", "numeric", "numeric", 
                                                                               "numeric", "numeric", "numeric"))
  
  # Change the column names to avoid confusion with the actual measurements (do not change this, even if annoying)
  colnames(aux_dataframe) = c("date", "D6.04", "D6.98", "D8.06", "D9.31", "D10.8", "D12.4", "D14.3", "D16.5", "D19.1", "D22.1", "D25.5", "D29.4", "D34", "D39.2", "D45.3", "D52.3", "D60.4", "D69.8", "D80.6", "D93.1", "D107.5", "D124.1", "D143.3", "D165.5", "D191.1", "D220.7", "D254.8", "D294.3", "D339.8", "D392.4", "D453.2", "D523.3")
   
  # Create a data frame with the same name as of the file
  assign(file_name, aux_dataframe)
  # Remove auxiliary data frame
  rm(aux_dataframe)
}


##############################################################################
# step 2: Run OpenAir timeAverage function to fix glitches (not accounted seconds)
##############################################################################

# Super rare but sometimes I've faced the following situation, especially with WCPC data:

# Example:
# date                     WCPC
# 2022-08-02  8:18:06 AM   2233.23
# 2022-08-02  8:18:07 AM   2233.23
# 2022-08-02  8:18:09 AM   2233.23  <<< jumped one second
# 2022-08-02  8:18:10 AM   2233.23
# 2022-08-02  8:18:11 AM   2233.23

# To deal with this we can run the timeAverage function from OpenAir for a "sec":
# This step will "eat" a second of your data because of how the timeAverage function works

library(openair)
library(tidyverse)

# Get a list of all WCPC and FMPS objects in the R Global Environment
object_list <- ls(pattern = "^FMPS_")
object_list <- append(object_list, ls(pattern = "^WCPC_"))

# Loop over each object in the list and execute a function
for (object_name in object_list) {

    # Create auxiliary dataframe
    aux_dataframe = get(object_name)
    
    # Execute desired timeAverage function on the file, compare previous and modified files
    
    #1 Get the length of the file and store in a aux object
    length_before = nrow(aux_dataframe)
    
    #2 Apply OpenAir function 
    aux_dataframe <- timeAverage(get(object_name), avg.time = "sec")
    
    #3 Get the new length of the file and store in second aux object
    length_after = nrow(aux_dataframe)
    
    #4 Check:
    if (length_after > length_before){
      missing_seconds = length_after - length_before
      print(paste("Object named", object_name, "had a glintch. Missing seconds:", missing_seconds, "-> better verify."))
    }
    
    # Get the unique dates from the WCPC and FMPS dataframe names
    if (grepl("^WCPC", object_name)){
      unique_dates <- unique(sub("WCPC_", "", object_name))}
    else if (grepl("^FMPS", object_name)){
      unique_dates <- unique(sub("FMPS_", "", object_name)) 
    }
    
    # For each unique date, re-write the corresponding WCPC and FMPS merged dataframes based on date
    for (date in unique_dates) {
      if (grepl("^WCPC", object_name)){
        assign(paste0("WCPC_", date), aux_dataframe)}
      else if (grepl("^FMPS", object_name)){
          assign(paste0("FMPS_", date), aux_dataframe)} 
    }
    rm(aux_dataframe) # remove auxiliary dataframe   
}


##############################################################################
# step 3: Run data cleaning (get rid of equal time data points)
##############################################################################

# Also rare but sometimes I've faced the following situation, especially with WCPC data:

# Example:
# date                     WCPC
# 2022-08-02  8:18:06 AM   2233.23
# 2022-08-02  8:18:07 AM   2233.23
# 2022-08-02  8:18:07 AM   2233.23  <<< repeated one second
# 2022-08-02  8:18:08 AM   2233.23
# 2022-08-02  8:18:09 AM   2233.23
# 2022-08-02  8:18:10 AM   2233.23

# We use the same object_list from Step 2

# Loop over each object in the list and execute a function that checks for duplicates:
for (object_name in object_list) {
    # Create auxiliary dataframe
    aux_dataframe = get(object_name)
    
    # Check for duplicates in the "date" column
    duplicates <- aux_dataframe$date[duplicated(aux_dataframe$date)]
    
    # If there are duplicates, remove the latest one (also print warning)
    if (length(duplicates) > 0) {
      print(paste("Object named:", object_name, " had a date duplicate. Better verify."))
      for (i in duplicates) {
        aux_dataframe <- aux_dataframe[-which.max(aux_dataframe$date == i),]
      }
    }
    
    # Get the unique dates from the WCPC and FMPS dataframe names
    if (grepl("^WCPC", object_name)){
      unique_dates <- unique(sub("WCPC_", "", object_name))}
    else if (grepl("^FMPS", object_name)){
      unique_dates <- unique(sub("FMPS_", "", object_name)) 
    }
    
    # For each unique date, re-write the corresponding WCPC and FMPS merged dataframes based on date
    for (date in unique_dates) {
      if (grepl("^WCPC", object_name)){
        assign(paste0("WCPC_", date), aux_dataframe)}
      else if (grepl("^FMPS", object_name)){
        assign(paste0("FMPS_", date), aux_dataframe)} 
    }
    rm(aux_dataframe) # remove auxiliary dataframe
}


##############################################################################
# step 4: Merge FMPS and WCPC data by time (using file names)
##############################################################################

# Find WCPC and FMPS dataframes in the R Global Environment based on their name
WCPC_names <- ls(pattern = "WCPC_[0-9]{2}_[0-9]{2}_[0-9]{2}$") # this is another to do it
FMPS_names <- ls(pattern = "FMPS_[0-9]{2}_[0-9]{2}_[0-9]{2}$") # this is another way to do it

# Get the unique dates from the WCPC and FMPS dataframe names
WCPC_dates <- unique(sub("WCPC_", "", WCPC_names))
FMPS_dates <- unique(sub("FMPS_", "", FMPS_names))

# Find the dates that are common to both WCPC and FMPS dataframes
common_dates <- intersect(WCPC_dates, FMPS_dates)

# For each common date, merge the corresponding WCPC and FMPS dataframes based on "date" column
for (date in common_dates) {
  WCPC_df <- get(paste0("WCPC_", date))
  FMPS_df <- get(paste0("FMPS_", date))
  #WCPC_df$date <- as.POSIXct(WCPC_df$date, format = "%Y-%m-%d %H:%M:%S") # if you had a POSIXct error is probably because the format was not the same as the one indicated at Step 1, in this case, uncomment this line and good luck.
  #FMPS_df$date <- as.POSIXct(FMPS_df$date, format = "%Y-%m-%d %H:%M:%S") # if you had a POSIXct error is probably because the format was not the same as the one indicated at Step 1, in this case, uncomment this line and good luck.
  merged_df <- merge(WCPC_df, FMPS_df, by = "date", all = TRUE)
  #delete rows with NA values
  merged_df <- na.omit(merged_df)
  assign(paste0("WCPC_and_FMPS_", date), merged_df) # Output will be "WCPC_and_FMPS_XX_XX_XX" where "XX_XX_XX" correspond to the sampling date
  rm(WCPC_df) # remove aux WCPC file
  rm(FMPS_df) # remove aux FMPS file
  rm(merged_df) # remove aux merged file
}

##############################################################################
# step 5: Make data lag X sec for each merged dataframe
##############################################################################

# This is case of a mobile monitoring application where the concentration measured
# does not represent the concentration at the current position given the lag
# between sampling and detecting (particles being transported in the pipe+tubing+instrument)

# If there is no lag time to account for (no mobile application, short tubing), one can skip this step

# Otherwise, start by informing the lag time (must be known) 
# The script will move the concentrations up if negative 
# This is desired for mobile applications if you are later merging concentration to the position in time 

lag_time = -5 # seconds for WCPC and FMPS (if frequency is 1Hz - as recommended in Zimmerman et al. 2015)

# Find WCPC and FMPS dataframes in the Global Environment based on their name
Merged_df_names <- ls(pattern = "WCPC_and_FMPS_[0-9]{2}_[0-9]{2}_[0-9]{2}$")

library(xts)

# Loop over each object in the list and execute a function
for (object_name in Merged_df_names) {
    # Create auxiliary dataframe
    WCPC_and_FMPS_XX_XX_XX = get(object_name)
    WCPC_and_FMPS_XX_XX_XX$date <- as.POSIXct(WCPC_and_FMPS_XX_XX_XX$date)
    WCPC_and_FMPS_XX_XX_XX <- xts(cbind(WCPC_and_FMPS_XX_XX_XX[, -1]), order.by = WCPC_and_FMPS_XX_XX_XX$date)
    
    # Shift the concentration values by a lag time of 5 seconds
    
    # If you want to shift only one instrument (say FMPS rows), use something like:
    #WCPC_and_FMPS_XX_XX_XX = cbind(WCPC_and_FMPS_XX_XX_XX[, 1], lag.xts(WCPC_and_FMPS_XX_XX_XX[, -1], k = lag_time)) 
    
    # Otherwise, shift everything:      
    WCPC_and_FMPS_XX_XX_XX = lag.xts(WCPC_and_FMPS_XX_XX_XX, k = lag_time) 
    
    # Work again with dataframes
    #1 Get dataframe
    WCPC_and_FMPS_XX_XX_XX = cbind(date = index(WCPC_and_FMPS_XX_XX_XX), data.frame(WCPC_and_FMPS_XX_XX_XX))
    #2 Reset the index
    WCPC_and_FMPS_XX_XX_XX <- data.frame(WCPC_and_FMPS_XX_XX_XX, row.names = NULL)
    #3 Change the columns names back
    colnames(WCPC_and_FMPS_XX_XX_XX) = c("date", "WCPC", "D6.04", "D6.98", "D8.06", "D9.31", "D10.8", "D12.4", "D14.3", "D16.5", "D19.1", "D22.1", "D25.5", "D29.4", "D34", "D39.2", "D45.3", "D52.3", "D60.4", "D69.8", "D80.6", "D93.1", "D107.5", "D124.1", "D143.3", "D165.5", "D191.1", "D220.7", "D254.8", "D294.3", "D339.8", "D392.4", "D453.2", "D523.3")
    #4 Remove NA rows created
    WCPC_and_FMPS_XX_XX_XX = na.omit(WCPC_and_FMPS_XX_XX_XX)
    
    # Get the unique dates from the WCPC and FMPS dataframe names
    unique_dates <- unique(sub("WCPC_and_FMPS_", "", object_name))
    
    # For each unique date, re-write the corresponding WCPC and FMPS merged dataframes based on date
    for (date in unique_dates) {
      assign(paste0("WCPC_and_FMPS_", date), WCPC_and_FMPS_XX_XX_XX)
    }
    rm(WCPC_and_FMPS_XX_XX_XX) # remove auxiliary dataframe
}


##############################################################################
# step 6: Fix FMPS data dividing everything by 16
##############################################################################

# Loop over each object in the "Merged_df_list" and execute a function
for (object_name in Merged_df_names) {
    # Create auxiliary dataframe
    WCPC_and_FMPS_XX_XX_XX = get(object_name)
    
    # Loop over columns containing FMPS data to make the division (to get real concentration value)
    for (i in 3:34){
      WCPC_and_FMPS_XX_XX_XX[,i] = WCPC_and_FMPS_XX_XX_XX[,i]/16
    }
    
    # Get the unique dates from the WCPC and FMPS dataframe names
    unique_dates <- unique(sub("WCPC_and_FMPS_", "", object_name))
    
    # For each unique date, re-write the corresponding WCPC and FMPS merged dataframes based on date
    for (date in unique_dates) {
      assign(paste0("WCPC_and_FMPS_", date), WCPC_and_FMPS_XX_XX_XX)
    }
    rm(WCPC_and_FMPS_XX_XX_XX) # remove auxiliary dataframe
}


####################################################################################
# step 7: Adjust FMPS data using the Tables 2 and 3 from Zimmerman et al. 2015 paper
####################################################################################

mid_point = c("D6.04", "D6.98", "D8.06", "D9.31", "D10.8", "D12.4", "D14.3", "D16.5", "D19.1", "D22.1", "D25.5", "D29.4", "D34", "D39.2", "D45.3", "D52.3", "D60.4", "D69.8", "D80.6", "D93.1", "D107.5", "D124.1", "D143.3", "D165.5", "D191.1", "D220.7", "D254.8", "D294.3", "D339.8", "D392.4", "D453.2", "D523.3")
slope = c(1,1,1.362,0.820,0.835,1.139,1.294,1.227,1.193,1.215, 1.134, 0.951, 0.885, 0.935, 0.924, 0.928, 0.904, 0.913, 0.930, 0.936,1,1,1,1,1,1,1,1,1,1,1,1)
intercept = c(0,0,144,19,44,103,205,443,816,1324,1070,624,463,258,266,240,278,126,86,108,0,0,0,0,0,0,0,0,0,0,0,0)

Zimmerman_Table_3 = data.frame(mid_point,slope,intercept)

# Get the slope values from Zimmerman_Table_3 and store them in a named vector
slopes <- with(Zimmerman_Table_3, setNames(slope, mid_point))

# Get the intercepts values from Zimmerman_Table_3 and store them in a named vector
intercepts <- with(Zimmerman_Table_3, setNames(intercept, mid_point))

# Loop over columns 3 to 34 of WCPC_and_FMPS_XX_XX_XX and multiply each value by the corresponding slope value then add intercept
for (object_name in Merged_df_names){
  for (col in 3:34) {
    WCPC_and_FMPS_XX_XX_XX = get(object_name)
    WCPC_and_FMPS_XX_XX_XX[[col]] <- ((WCPC_and_FMPS_XX_XX_XX[[col]] * slopes[[col-2]]) + intercepts[[col-2]]) # -2 necessary because slopes has 32 columns and WCPC_and_FMPS_XX_XX_XX has 34
    
    # Get the unique dates from the WCPC and FMPS dataframe names
    unique_dates <- unique(sub("WCPC_and_FMPS_", "", object_name))
    
    # Change the mid-point size bin for diameters >80 nm (Table 2 from Zimmerman et al. 2015)
    colnames(WCPC_and_FMPS_XX_XX_XX) = c("date", "WCPC", "D6.04", "D6.98", "D8.06", "D9.31", "D10.8", "D12.4", "D14.3", "D16.5", "D19.1", "D22.1", "D25.5", "D29.4", "D34", "D39.2", "D45.3", "D52.3", "D60.4", "D69.8", "D95.2", "D114.1", "D138.9", "D167.6", "D200.8", "D239.1", "D283.3", "D334.4", "D393.3", "D461.5", "D540.0", "D630.8", "D735.8", "D856.8")

    # For each unique date, re-write the corresponding WCPC and FMPS merged dataframes based on date
    for (date in unique_dates) {
      assign(paste0("WCPC_and_FMPS_", date), WCPC_and_FMPS_XX_XX_XX)
    }
    
  }
  rm(WCPC_and_FMPS_XX_XX_XX) # remove auxiliary dataframe
}


####################################################################################
# step 8: Get total particle count from FMPS (adds new column to dataframe)
####################################################################################

#Get the total particle count per row (second)
for (object_name in Merged_df_names){
  N = rowSums(get(object_name)[3:34])
  WCPC_and_FMPS_XX_XX_XX = get(object_name)
  WCPC_and_FMPS_XX_XX_XX$FMPS = N # adds the new column with total particles concentration measured by the FMPS
  
  # Get the unique dates from the WCPC and FMPS dataframe names
  unique_dates <- unique(sub("WCPC_and_FMPS_", "", object_name))
  
  # For each unique date, re-write the corresponding WCPC and FMPS merged dataframes based on date
  for (date in unique_dates) {
    assign(paste0("WCPC_and_FMPS_", date), WCPC_and_FMPS_XX_XX_XX)
  }
  rm(WCPC_and_FMPS_XX_XX_XX) # remove auxiliary dataframe
}


####################################################################################
# step 9: Align the datasets based on the Cross Correlation Factor
####################################################################################

# This step is necessary if in your sampling setup the lines that transport particles to the WCPC and FMPS have different lengths
# If this is the case, their signal (for the same or similar concentration) will be lagged by a certain time
# Even if this is not the case, the time series might still need to be re-aligned considering the 
# residency time of particles in the instruments, the time between air intake and detection and other factors
# The script below finds the lag between WCPC and FMPS that will provide the highest correlation between timeseries
# It then shifts either FMPS or WCPC (user must select based on the length of the particle line or other reason)

# The script also plots the CCF analysis so you can verify this lag time between days for consistency
library(forecast)

# For all merged WCPC and FMPS dateframes the script does the following:

for (object_name in Merged_df_names){
  
  # Transform the data to the required format
  WCPC_and_FMPS_XX_XX_XX = get(object_name)
  ts1 <- xts(WCPC_and_FMPS_XX_XX_XX$WCPC, WCPC_and_FMPS_XX_XX_XX$date)
  ts2 <- xts(WCPC_and_FMPS_XX_XX_XX$FMPS, WCPC_and_FMPS_XX_XX_XX$date)
  
  # Get the correlation values for up to 60 seconds (1 min) of lag time (forwards and backwards)
  max_lag = 60
  
  # Compute the Cross Correlation Factors (also plot)
  ccfvalues = ccf(as.numeric(ts1), as.numeric(ts2), max_lag, main = paste0("Cross-Correlation Function of ", object_name))
  
  # Find the index (lag time) with the highest correlation (script below)
  
  # Explanation from (https://online.stat.psu.edu/stat510/lesson/8/8.2) slightly edited:
  # A negative value for "h" is a correlation between the x-variable (WCPC) at a time t-h 
  # and the y-variable (FMPS) at time t. For instance, consider h = -2. The CCF value would give the
  # correlation between x (t-2) and y, i.e., the FMPS data should be lagged back by 2 seconds or the WCPC
  # moved 2 sec ahead in time for time series alignment.
  
  new_lag = (which.max(ccfvalues$acf)-max_lag-1) # Function expects negative values of h so which.max returns value <60 (make sure if so and change accordingly if not)
  
  # Shift the FMPS (if that's the instrument with delayed signal) concentration values by a lag time of X seconds (remember for dplyr use function lead()!!!)
  #1 Confirm the correct format of date column
  WCPC_and_FMPS_XX_XX_XX$date <- as.POSIXct(WCPC_and_FMPS_XX_XX_XX$date)
  #2 Transform dataframe to proper format (Ordering by date)
  WCPC_and_FMPS_XX_XX_XX <- xts(cbind(WCPC_and_FMPS_XX_XX_XX[, -1]), order.by = WCPC_and_FMPS_XX_XX_XX$date)
  # Performs the lag only for FMPS data (if desired for WCPC, put the "lag.xts" function in the first object of "cbind()" and remove from second )
  WCPC_and_FMPS_XX_XX_XX = cbind(WCPC_and_FMPS_XX_XX_XX[, 1], lag.xts(WCPC_and_FMPS_XX_XX_XX[, -1], k = new_lag)) 
  
  # Work again with dataframes
  #1 Get dataframe
  WCPC_and_FMPS_XX_XX_XX = cbind(date = index(WCPC_and_FMPS_XX_XX_XX), data.frame(WCPC_and_FMPS_XX_XX_XX))
  #2 Reset the index
  WCPC_and_FMPS_XX_XX_XX <- data.frame(WCPC_and_FMPS_XX_XX_XX, row.names = NULL)
  #3 Remove NA rows created
  WCPC_and_FMPS_XX_XX_XX = na.omit(WCPC_and_FMPS_XX_XX_XX)
  
  # Get the unique dates from the WCPC and FMPS dataframe names
  unique_dates <- unique(sub("WCPC_and_FMPS_", "", object_name))
  
  # Change the columns names back to original
  colnames(WCPC_and_FMPS_XX_XX_XX) = c("date", "WCPC", "D6.04", "D6.98", "D8.06", "D9.31", "D10.8", "D12.4", "D14.3", "D16.5", "D19.1", "D22.1", "D25.5", "D29.4", "D34", "D39.2", "D45.3", "D52.3", "D60.4", "D69.8", "D95.2", "D114.1", "D138.9", "D167.6", "D200.8", "D239.1", "D283.3", "D334.4", "D393.3", "D461.5", "D540.0", "D630.8", "D735.8", "D856.8", "FMPS")
  
  # For each unique date, re-write the corresponding WCPC and FMPS merged dataframes based on date
  for (date in unique_dates) {
    assign(paste0("WCPC_and_FMPS_", date), WCPC_and_FMPS_XX_XX_XX)
  }
  rm(WCPC_and_FMPS_XX_XX_XX) # remove auxiliary dataframe
  rm(ts1) # remove WCPC xst file
  rm(ts2) # remove FMPS xst file
  #rm(ccfvalues) # remove ccfvalues file if desired (but it is good to check)
}

####################################################################################
# step 10: Adjust FMPS data using WCPC ratio (see Zimmerman et al. 2015)
####################################################################################

# Note: if the user does not want the FMPS and WCPC concentration values to be the same (for comparison), skip this step.
# Alternatively, one can jump to Step 11 and save the "WCPC_and_FMPS_XX_XX_XX" files as it is and then run Step 10

for (object_name in Merged_df_names){
  # Get the ratio between FMPS and WCPC and apply this ratio throughout FMPS data
  WCPC_and_FMPS_XX_XX_XX = get(object_name)
  Ratio = WCPC_and_FMPS_XX_XX_XX$FMPS/WCPC_and_FMPS_XX_XX_XX$WCPC
  WCPC_and_FMPS_XX_XX_XX$Ratio = Ratio # Creates a new column named "Ratio", this column stays for reference and to convert back FMPS data if desired
  for (i in 3:35){
    WCPC_and_FMPS_XX_XX_XX[,i] = WCPC_and_FMPS_XX_XX_XX[,i]/WCPC_and_FMPS_XX_XX_XX$Ratio
  }
  
  # Get the unique dates from the WCPC and FMPS dataframe names
  unique_dates <- unique(sub("WCPC_and_FMPS_", "", object_name))
  
  # For each unique date, re-write the corresponding WCPC and FMPS merged dataframes based on date
  for (date in unique_dates) {
    assign(paste0("WCPC_and_FMPS_", date), WCPC_and_FMPS_XX_XX_XX)
  }
  rm(WCPC_and_FMPS_XX_XX_XX)
}  

####################################################################################
# step 11: Save everything 
# (also make sure format is compatible with "Getting_CMD_and_GSD" script)
####################################################################################

#### Format for "Getting_CMD_and_GSD" script
# In this format the first row repeats the first date and subsequent columns values are the diameters of the mid-point bins

for (object_name in Merged_df_names){
  # Assign object to temporary dataframe
  WCPC_and_FMPS_XX_XX_XX = get(object_name)
  
  # Extract columns only related to FMPS
  FMPS_Corrected_XX_XX_XX = subset(WCPC_and_FMPS_XX_XX_XX, select = c(date, D6.04, D6.98, D8.06, D9.31, D10.8, D12.4, D14.3, D16.5, D19.1, D22.1, D25.5, D29.4, D34, D39.2, D45.3, D52.3, D60.4, D69.8, D95.2, D114.1, D138.9, D167.6, D200.8, D239.1, D283.3, D334.4, D393.3, D461.5, D540.0, D630.8, D735.8, D856.8))
  
  # Optional: Extract just FMPS and WCPC data + date column
  FMPS_and_WCPC_XX_XX_XX = subset(WCPC_and_FMPS_XX_XX_XX, select = c(date, WCPC, FMPS))
  
  # Create a new row to insert the mid-point diameters
  new_row <- data.frame(date = FMPS_Corrected_XX_XX_XX[1,1], D6.04 = 6.04, D6.98 = 6.98, D8.06 = 8.06, D9.31 = 9.31, D10.8 = 10.8, D12.4 = 12.4, D14.3 = 14.3, D16.5 = 16.5, D19.1 = 19.1, D22.1 = 22.1, D25.5 = 25.5, D29.4 = 29.4, D34 = 34, D39.2 = 39.2, D45.3 = 45.3, D52.3 = 52.3, D60.4 = 60.4, D69.8 = 69.8, D95.2 = 95.2, D114.1 = 114.1, D138.9 = 138.9, D167.6 = 167.6, D200.8 = 200.8, D239.1 = 239.1, D283.3 = 283.3, D334.4 = 334.4, D393.3 = 393.3, D461.5 = 461.5, D540.0 = 540.0, D630.8 = 630.8, D735.8 = 735.8, D856.8 = 856.8)
  
  # Combine the two parts with the new row inserted in between the heading and data values
  FMPS_Corrected_XX_XX_XX <- rbind(new_row, FMPS_Corrected_XX_XX_XX)
  
  # Get the unique dates from the WCPC and FMPS dataframe names
  unique_dates <- unique(sub("WCPC_and_FMPS_", "", object_name))
  
  # For each unique date, re-write  and save the corresponding WCPC and FMPS merged dataframes based date
  for (date in unique_dates) {
    assign(paste0("FMPS_Corrected_", date), FMPS_Corrected_XX_XX_XX)
    #assign(paste0("WCPC_vs._FMPS_", date), FMPS_and_WCPC_XX_XX_XX)   # Remove comment if you are trying to save these files before dividing the FMPS data by the FMPS/WCPC ratio    
    write.csv(assign(paste0("FMPS_Corrected_", date), FMPS_Corrected_XX_XX_XX), paste0("FMPS_Corrected_", date, ".csv"), row.names = FALSE)
    #write.csv(assign(paste0("WCPC_vs._FMPS_", date), FMPS_and_WCPC_XX_XX_XX), paste0("WCPC_vs._FMPS_", date, ".csv"), row.names = FALSE) # Remove comment if you are trying to save these files before dividing the FMPS data by the FMPS/WCPC ratio
  }
  # Cleaning
  rm(WCPC_and_FMPS_XX_XX_XX)
  rm(new_row)
  rm(FMPS_Corrected_XX_XX_XX)
  rm(FMPS_and_WCPC_XX_XX_XX)
}

####################################################################################
# step 12: Plot results 
# (check the outcomes)
####################################################################################

# Find FMPS and FMPS_Corrected dataframes in the R Global Environment based on their name
FMPS_raw_names <- ls(pattern = "FMPS_[0-9]{2}_[0-9]{2}_[0-9]{2}$")
FMPS_corrected_names <- ls(pattern = "FMPS_Corrected_[0-9]{2}_[0-9]{2}_[0-9]{2}$")

# Get the unique dates from the WCPC and FMPS dataframe names
FMPS_raw_dates <- unique(sub("FMPS_", "", FMPS_raw_names))
FMPS_corrected_dates <- unique(sub("FMPS_Corrected_", "", FMPS_corrected_names))

# Find the dates that are common to both WCPC and FMPS dataframes
common_dates <- intersect(FMPS_raw_dates, FMPS_corrected_dates)

# Iterate over the 15 pairs of dataframes
for (date in common_dates) {
  fmps_raw_df <- get(paste0("FMPS_", date))
  fmps_raw_df[,2:33] <- fmps_raw_df[,2:33]/16
  fmps_raw_df$date <- as.POSIXct(fmps_raw_df$date)
  fmps_corr_df <- get(paste0("FMPS_Corrected_", date))
  fmps_corr_df$date <- as.POSIXct(fmps_corr_df$date)
  # Find the common timestamps
  common_timestamps <- intersect(fmps_raw_df$date, fmps_corr_df$date)
  # Randomly select a timestamp from the common timestamps
  selected_timestamp <- sample(common_timestamps, 1)
  # Extract the measurements for each size bin at the selected timestamp
  fmps_measurements <- fmps_raw_df[fmps_raw_df$date == selected_timestamp, 2:33]
  corrected_measurements <- fmps_corr_df[fmps_corr_df$date == selected_timestamp, 2:33]
  size_bins <- c(6.04,6.98,8.06,9.31,10.8,12.4,14.3,16.5,19.1,22.1,25.5,29.4,34,39.2,45.3,52.3,60.4,69.8,95.2,114.1,138.9,167.6,200.8,239.1,283.3,334.4,393.3,461.5,540.0,630.8,735.8,856.8)
  selected_timestamp <- as.POSIXct(selected_timestamp, origin = "1970-01-01 00:00:00")
  # Create a new plot
  #timestamp <- format(selected_timestamp, "%H:%M:%S")
  plot(x = size_bins, y = fmps_measurements[1,], ylim = c(0, 1.2*max(fmps_measurements, corrected_measurements)), log = "x", xlab = "Diameter (nm)", ylab = "Concentration (#/cm^3)", main = paste0("Time: ", selected_timestamp))
  # Add a solid black border to the plot
  box()
  # Add a dashed light gray grid to the plot
  grid(lty = "dotted", col = "lightgray")
  # Add the FMPS_raw line and data points
  lines(x = size_bins, y = fmps_measurements[1,], type = "b", col = "blue")
  points(x = size_bins, y = fmps_measurements[1,], pch = 17, col = "blue")
  # Add the FMPS_fixed line and data points
  lines(x = size_bins, y = corrected_measurements[1,], type = "b", col = "red")
  points(x = size_bins, y = corrected_measurements[1,], pch = 15, col = "red")
  # Add a legend
  legend("topright", legend = c("FMPS_raw", "FMPS_fixed"), col = c("blue", "red"), pch = c(17, 15), lty = c(1, 1))
  
  # Clean aux dataframes
  rm(fmps_corr_df)
  rm(fmps_raw_df)
}


#################################################################################################################
# EXTRA STEP: Get the Count Median Diameter (CMD) and Geometric Standard Deviation (GSD) from corrected FMPS data 
# For more information see: TSI Application Note APR-001: Aerosol Statistics, Lognormal Distributions and dN/dlogDp
#################################################################################################################

# This script also estimates the 95% cut-points (diameters for which there are 95% of measured particles in between)

# CAUTION: This script takes considerably more time to run given all the calculations necessary (also "for loops")
#          For files up to 20000 rows, it takes about 5-10 min depending on the machine
#          If you are running multiple files (as the script was made for), take a walk, have a coffee break

# Find corrected FMPS dataframes in the Global Environment based on their name
FMPS_df_names <- ls(pattern = "FMPS_Corrected_[0-9]{2}_[0-9]{2}_[0-9]{2}$")

for (object_name in FMPS_df_names){
  # Assign object to temporary dataframe
  FMPS_Corrected_XX_XX_XX = get(object_name)
  
  # Creates a mirrored dataframe
  FMPS_Corrected_XX_XX_XX_2 = FMPS_Corrected_XX_XX_XX
  
  # Estimate the total particle number per row (again, seconds if 1 Hz data is used)
  N = rowSums(FMPS_Corrected_XX_XX_XX[2:33])
  Time = FMPS_Corrected_XX_XX_XX_2[,1] # saves the time column
  
  # In between step to estimate the geometric median diameter (Dg)
  for (i in 1:(nrow(FMPS_Corrected_XX_XX_XX_2) - 1)){
  for (j in 2:33){
    FMPS_Corrected_XX_XX_XX_2[i+1,j] = FMPS_Corrected_XX_XX_XX[1,j]^(FMPS_Corrected_XX_XX_XX[i+1,j]/N[i+1])
    }
  }
  
  # Estimate the Count Median Diameter (CMD)
  CMD = c(1:nrow(FMPS_Corrected_XX_XX_XX_2))
  CMD[1] = 0
  for (i in 1:(nrow(FMPS_Corrected_XX_XX_XX_2) - 1)){
    CMD[i+1] = FMPS_Corrected_XX_XX_XX_2[i+1,2]*FMPS_Corrected_XX_XX_XX_2[i+1,3]*FMPS_Corrected_XX_XX_XX_2[i+1,4]*FMPS_Corrected_XX_XX_XX_2[i+1,5]*FMPS_Corrected_XX_XX_XX_2[i+1,6]*FMPS_Corrected_XX_XX_XX_2[i+1,7]*FMPS_Corrected_XX_XX_XX_2[i+1,8]*FMPS_Corrected_XX_XX_XX_2[i+1,9]*FMPS_Corrected_XX_XX_XX_2[i+1,10]*FMPS_Corrected_XX_XX_XX_2[i+1,11]*FMPS_Corrected_XX_XX_XX_2[i+1,12]*FMPS_Corrected_XX_XX_XX_2[i+1,13]*FMPS_Corrected_XX_XX_XX_2[i+1,14]*FMPS_Corrected_XX_XX_XX_2[i+1,15]*FMPS_Corrected_XX_XX_XX_2[i+1,16]*FMPS_Corrected_XX_XX_XX_2[i+1,17]*FMPS_Corrected_XX_XX_XX_2[i+1,18]*FMPS_Corrected_XX_XX_XX_2[i+1,19]*FMPS_Corrected_XX_XX_XX_2[i+1,20]*FMPS_Corrected_XX_XX_XX_2[i+1,21]*FMPS_Corrected_XX_XX_XX_2[i+1,22]*FMPS_Corrected_XX_XX_XX_2[i+1,23]*FMPS_Corrected_XX_XX_XX_2[i+1,24]*FMPS_Corrected_XX_XX_XX_2[i+1,25]*FMPS_Corrected_XX_XX_XX_2[i+1,26]*FMPS_Corrected_XX_XX_XX_2[i+1,27]*FMPS_Corrected_XX_XX_XX_2[i+1,28]*FMPS_Corrected_XX_XX_XX_2[i+1,29]*FMPS_Corrected_XX_XX_XX_2[i+1,30]*FMPS_Corrected_XX_XX_XX_2[i+1,31]*FMPS_Corrected_XX_XX_XX_2[i+1,32]*FMPS_Corrected_XX_XX_XX_2[i+1,33]
  }
  
  # Estimate the Geometric Standard Deviation (GSD)
  log_GSD = CMD
  log_GSD[1] = 0
  for (i in 1:(nrow(FMPS_Corrected_XX_XX_XX_2) - 1)){
    for (j in 2:33){
      log_GSD[i+1] = (sum(FMPS_Corrected_XX_XX_XX[i+1,j]*((log(FMPS_Corrected_XX_XX_XX[1,j])-log(CMD[i+1]))^2))/N[i+1])^(1/2) 
    }
  }  
  GSD = 10^log_GSD
  
  # Estimate the 95% cut diameter (low and high)
  D95_low = CMD/(GSD^2)
  D95_high = CMD*(GSD^2)
  
  # Creates a dataframe with the summary of the distribution analysis
  D95 = data.frame(Time,N,CMD,D95_low,D95_high,GSD)  
  
  # Creates a new column filled with random character variable ("a") which will be replaced
  new = c(1:nrow(FMPS_Corrected_XX_XX_XX_2))
  new[1] = "a"
  for (i in 1:(nrow(FMPS_Corrected_XX_XX_XX_2) - 1)){
    new[i+1] = "a"
  }
  
  # Assign this new column to the created Dataframe
  D95['Dispersion'] = new
  
  #Properly classify the distribution status by row (timestep)
  for (i in 1:(nrow(FMPS_Corrected_XX_XX_XX_2) - 1)){
    if (D95[i+1,6] <= 1.25){
      D95[i+1,7] = "Monodisperse"
    } else {
      D95[i+1,7] = "Polidisperse"
    }
  }
  
  #Drop the first row (fixed diameter values for size bins)
  D95 = D95[-1,]
  
  # Get the unique dates from the corrected FMPS dataframe names
  unique_dates <- unique(sub("FMPS_Corrected_", "", object_name))
  
  # For each unique date, re-write and save the corresponding analysis based on date
  for (date in unique_dates) {
    assign(paste0("FMPS_Size_Analysis_", date), D95)
    write.csv(assign(paste0("FMPS_Size_Analysis_", date), D95), paste0("FMPS_Size_Analysis_", date, ".csv"), row.names = FALSE)
    
  }
  # Cleaning
  rm(D95)
  rm(FMPS_Corrected_XX_XX_XX)
  rm(FMPS_Corrected_XX_XX_XX_2)

}  