#####################################################
## DOWNLOAD WORLD DEVELOPMENT INDICATORS FROM IBRD ##
## Author:    Ricardo Zambrano                     ##
## Date:      FEb/18/2020                          ##
#####################################################

###########################################################################################
### This module downloads development indicators from the World Bank DataBank           ###
### Indicator Codes are found in this file: 'IBRD DataBank - Metadata Glossary.xlsx'    ###
### It uses the WDI library to search, extract and format data from the World Bank      ###
### The output of the module is a csv file with develpment indicators                   ###
### (cont.) to be joined with DFC data in another module                                ###
########################################################################################### 

###############
## LIBRARIES ##
###############

library(WDI)
library(tidyverse)

#############################
## ENVIRONMENT PREPARATION ##
#############################

# The file is located on "S:\TD\DataWarehouse\IBRD - DataFrames"
# The following statement is to verify that the working directory is the same as in the path defined above
getwd()
# If the working directory is different than the path above excecute the statement below to specify the correct working directory
path <- "S:/TD/DataWarehouse/IBRD - DataFrames"
setwd(path)

##################
## Data Request ##
##################

# Statement to download development indicators from the IBRD (World Bank)
ibrdReq <- WDI(country="all", indicator = c("NY.GNP.PCAP.CD","SI.POV.GINI"), start = 1989,end = NULL, extra = TRUE, cache = NULL)
ibrdRaw <- ibrdReq

######################
## Data Exploration ##
######################

typeof(ibrdRaw)
summary(ibrdRaw)

# Recast the dataframe as a tidyverse "tibble"
ibrd <- as_tibble(ibrdRaw)
names(ibrd)

# Select columns of interest
drop_var <- c("capital","longitude","latitude")
ibrd <- select(ibrd, -drop_var)
ibrd
names(ibrd)

# Renaming the indicators
ibrd <- ibrd %>% 
  rename(gni_pc_atlas = NY.GNP.PCAP.CD, gini_indx = SI.POV.GINI)

ibrd
names(ibrd)

ibrd <- ibrd %>%
  mutate(
    `country` = tolower(`country`),
    `iso3c` = as.character(`iso3c`),
    `region` = as.character(`region`),
    `income` = as.character(`income`),
    `lending` = as.character(`lending`)
  )

summary(ibrd)
ibrd

######################
## Output: csv File ##
######################

ibrd_data <- ibrd

# Statement to write a csv file with the development indicators extracted
write.csv(ibrd_data, file="ibrd_data.csv", append = FALSE, sep = ".", na = ".",
          col.names = TRUE, qmethod = "double")







