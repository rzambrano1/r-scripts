######################################################
## REMAINING UNOBLIGATED & AVAILABLE BALANCES TABLE ##
## Author:                      Ricardo Zambrano    ##
## Version:                     0.2                 ##
## Date Created:                Dec/16/2021         ##
## Most Recent Review Date:     Dec/27/2021         ##
## Rationale:                   Current Version     ##
######################################################

###########################################################################################
### This module uploads an SF-133 Report a MS Excel file (*.xlsx extension)             ###
### (cont.) - from the current quarter reporting folder                                 ###
### The output of the module is the "Remaining Unobligated and Available Balances of    ###
### Resources" table in tibble and csv file format                                      ###
###########################################################################################

###########################################################################################
### NOTES: This version includes a sub-class of TAS. The new class is meant to  substi- ###
### tute TASs that need further breakdown into Equity and Admin                         ###
###########################################################################################

###############
## LIBRARIES ##
###############

library(tidyverse) # Data science standard library
library(lubridate)
library(readxl) # To read excel files
library(R6) # Reference Class for OOP similar to OOP languages
library(Dict) # Dictionary data type
library(stringr) # Regular expressions
library(htmlwidgets)
library(lobstr) # For testing bindings of environments. In particular, for checking bindings of class TAS and subclass derivedTAS


#############################
## ENVIRONMENT PREPARATION ##
#############################

## UPDATE IN  FINAL VERSION ## ->  # The file is located on "S:\TD\DataWarehouse\EBR - DataFrames"
# The following statement is to verify that the working directory is the same as in the path defined above
getwd()
# If the working directory is different than the path above execute the statement below to specify the correct working directory
#path <- "S:/TD/DataWarehouse/EBR - DataFrames"
#setwd(path)

# The following statements collect the current date and pinpoint the current fiscal year and current reporting quarter

reportingDate <- Sys.Date() # This is the date the report is being generated

currYear <- year(reportingDate)
currMonth <- month(reportingDate)
currDay <- day(reportingDate)

#typeof(reportingDate) # Commented out test

fiscalYear <- NA
quarter <- NA

endQuarter <- function(yr,mnth,dy,NormalOps=TRUE) {
  # Takes two values yr (a Year), mnth (a Month), and dy (a Day) all double types
  # The default parameter NormalOps is set to TRUE in case the function needs to be modified to 
  # (cont.) return a fiscal year other than the current
  # Returns the current reporting end date
  
  if (NormalOps == FALSE) {
    paramQuestion1 <- toupper(readline(prompt = "Are the parameters yr,mnth,dy corresponting to the quarter end date? (Answer Y/N): "))
    if (paramQuestion1 == "Y") {
      quarterEndDate <<- as.Date(paste0(yr,"-",mnth,"-",dy))
      return(quarterEndDate)
    } else if (paramQuestion1 == "N") {
      paramQuestion2 <- readline(prompt = "Type the quarter date end (Use the YYYY-MM-DD format: ")
      quarterEndDate <<- as.Date(paramQuestion2)
      return(quarterEndDate)
    } else {
      stop("Please provide a valid answer Y or N")
    }
  }
  
  if (mnth == 1 | mnth == 2 | mnth ==3) {
    endDay <- 31
    endMonth <- 12
    endYear <- yr - 1
  } else if (mnth == 4 | mnth == 5 | mnth ==6) {
    endDay <- 31
    endMonth <- 3
    endYear <- yr
  } else if (mnth == 7 | mnth == 8 | mnth ==9) {
    endDay <- 30
    endMonth <- 6
    endYear <- yr
  } else if (mnth == 10 | mnth == 11 | mnth ==12) {
    endDay <- 30
    endMonth <- 9
    endYear <- yr 
  } else {
    stop("Month is Out of Range: ",currMonth)
  } 
  
  quarterEndDate <<- as.Date(paste0(endYear,"-",endMonth,"-",endDay),origin="2020-01-01")  # '<<-' operator to create a global variable
  
  return(quarterEndDate)
}

endQuarter(currYear,currMonth,currDay,NormalOps=TRUE)
#endQuarter(currYear,currMonth,currDay,NormalOps=FALSE) # Only enable to test other quarters

# endQuarter(2012,03,31,NormalOps = FALSE) - This is a test - currently commented out

eYear <- year(quarterEndDate)
eMonth <- month(quarterEndDate)

repQuarter <- function(eyr,emnth) {
  # Takes two values eyr (a Year) and emnth (a Month) all double types
  # Returns the current fiscal year and current reporting quarter
  
  if (emnth > 9) {
    fiscalYear <<- eyr + 1
  } else {
    fiscalYear <<- eyr
  }
  
  if (emnth > 0 & emnth < 4) {
    quarter <<- 2
  } else if (emnth > 3 & emnth < 7) {
    quarter <<- 3
  } else if (emnth > 6 & emnth < 10) {
    quarter <<- 4
  } else if (emnth > 9 & emnth < 13) {
    quarter <<- 1
  } else {
    stop("Month is Out of Range: ",emnth)
  }
  return(c(fiscalYear,quarter))
}

repQuarter(eYear,eMonth)

# The Following code test the endQuarter Function and the repQuarter Function - Currently commented out
## TESTS START ##
#for (indx in 1:13){
#  Sys.sleep(0.1)
#  currMonth <- indx
#  endQuarter(currYear,currMonth,currDay)
#  print(paste0(quarterEndDate))
#  flush.console()
#}

#for (indx in 1:12){
#  Sys.sleep(0.1)
#  eMonth <- indx
#  repQuarter(eYear,eMonth)
#  print(paste0("FY",fiscalYear,"Q",quarter))
#  flush.console()
#}
## TESTS END ##

# The following statements set up the folder path to locate the sf-133 report from the corresponding reporting quarter

basePath1 <- "/Users/SUINCA/Desktop/DFC - Telework/reportsAutomation"
basePath2 <- paste0("/EnterpriseDataAnalyst/1 - External Data Requests/","FY",fiscalYear,"/2 - Quarterly - Appropriators Report/","Q",quarter,"/")
filename <- "sf133.xlsx"
path133 <- paste0(basePath1,basePath2,filename)
#path133


# The following statements set up the path to locate the framesFinReporting file.
filename2 <- "framesFinReporting.xlsx"
pathDerTAS <- paste0(basePath1,basePath2,filename2)
#pathDerTAS

##################
## Data Request ##
##################

# The following statements upload the current reporting quarter SF-133 Report, an untidy MS Excel file

sf133sheets <- excel_sheets(path133) # Creates a list of the worksheets in the SF-133
dataSheetName <- "SF133 Detail" # Sets the worksheet that contains the data used in the Appropriators Report [[Check if this worksheet name is consistent]]
indxDataSheet <- match(dataSheetName,sf133sheets)
sf133Raw <- read_excel(path133,sheet=indxDataSheet,col_names=FALSE,col_types="text")

#View(sf133Raw)

# The following statements read the framesFinReporting file. The file consists of a collection of TASs that require further breakdown

framesFinReporting <- read_excel(pathDerTAS,sheet=indxDataSheet,col_names=FALSE,col_types="text")

#############################################
## Data Exploration, Testing, and Cleaning ##
#############################################

TAS <- R6Class("TAS", list(
  # Creates a TAS. TAS stands for Treasury Account Symbol
  numberTAS = NULL,
  nameTAS = NULL,
  quarterTAS = NA,
  fyTAS = NA,
  linesTAS = dict("1061"=0, "1200"=0, "1910"=0,"2002"=0,"2201"=0,"2403"=0,"3010"=0), # Initializes the required lines for the TAS' methods. More lines can be added
  resource = NA,
  obligated = NA,
  unobligated = NA,
  fyAppropriation = NA,
  fyEndAvail = NA,
  initialize = function(numberTAS,nameTAS, quarterTAS,fyTAS, linesTAS = dict("1061"=0, "1200"=0, "1910"=0,"2002"=0,"2201"=0,"2403"=0,"3010"=0), 
                        fyAppropriation = NA,fyEndAvail = NA,resource=NA,obligated=NA,unobligated=NA) {
    stopifnot(is.character(nameTAS),length(nameTAS) > 0)
    stopifnot(is.character(numberTAS),length(numberTAS) > 0)
    
    self$numberTAS <- numberTAS
    self$nameTAS <- nameTAS
    self$quarterTAS <- quarterTAS
    self$fyTAS <- fyTAS
    self$linesTAS <- linesTAS
    self$fyAppropriation <- fyAppropriation
    self$fyEndAvail <- fyEndAvail
    self$resource <- resource
    self$obligated <- obligated
    self$unobligated <- unobligated
  },
  print = function(...) {
    cat("========================================================================================================","\n")
    cat("TAS: \n")
    cat("========================================================================================================","\n")
    cat("  TAS Number:          ", self$numberTAS, "\n", sep = "")
    cat("  Account Name:        ", self$nameTAS, "\n", sep = "")
    cat("  Reporting Period:    ", "FY",self$fyTAS,"-Q",self$quarterTAS, "\n", sep = "")
    cat("  FY Appropriation:    ",self$fyAppropriation,"\n",sep="")
    cat("  FY End Availability: ",self$fyEndAvail,"\n",sep="")
    cat("========================================================================================================","\n")
    for (indx in 1:self$linesTAS$length) {
      print(paste0("Line ",self$linesTAS$keys[indx]," = ",format(self$linesTAS$values[indx],scientific=FALSE,big.mark = ",")))
    }
    cat("========================================================================================================","\n")
    cat("     Resource    = $ ",format(self$resource,scientific=FALSE,big.mark=","),"\n",sep="")
    cat("     Obligated   = $ ",format(self$obligated,scientific=FALSE,big.mark=","),"\n",sep="")
    cat("     Unobligated = $ ",format(self$unobligated,scientific=FALSE,big.mark=","),"\n",sep="")
    cat("========================================================================================================","\n")
    invisible(self)
  },
  getResource = function(line1910=self$linesTAS["1910"],line1200=self$linesTAS["1200"],line1061=self$linesTAS["1061"]) {
    # Calculates the Resource for a given TAS
    self$resource <- as.double(line1910) - as.double(line1200) - as.double(line1061)
    self$resource <- ifelse(is.na(self$resource),0,self$resource)
    invisible(self)
  },
  getObligated = function(line3010=self$linesTAS["3010"],line2002=self$linesTAS["2002"]) {
    # Calculates the Obligated Amount for a given TAS
    self$obligated <- as.double(line3010) - as.double(line2002)
    self$obligated <- ifelse(is.na(self$obligated),0,self$obligated)
    invisible(self)
  },
  getUnobligated = function(line2201=self$linesTAS["2201"],line2403=self$linesTAS["2403"]) {
    # Calculates the Unobligated Amount for a given TAS
    self$unobligated <- as.double(line2201) + as.double(line2403)
    self$unobligated <- ifelse(is.na(self$unobligated),0,self$unobligated)
    invisible(self)      
  },
  getfyAppropriation = function(numberTAS=self$numberTAS) {
    # Extracts the Fiscal Year of Appropriation from the TAS number
    self$fyAppropriation <- ifelse(grepl("X",numberTAS,fixed=TRUE),"",as.double(str_sub(str_sub(numberTAS,1,8),-4,-1)))
  },
  getfyEndAvail = function(numberTAS=self$numberTAS) {
    # Extracts the Fiscal Year End of Availability from the TAS number
    self$fyEndAvail <- ifelse(grepl("X",numberTAS,fixed=TRUE),"No Year",as.double(str_sub(str_sub(numberTAS,1,13),-4,-1)))
  }
)
)

# The following is a derived class (sub-class) that inherits from the TAS class. Its purpose is to create a class to
# accommodate TAS that need further breakdown into Equity and Admin

derivedTAS <- R6Class("derivedClass",
                      #Creates a derived class
                      inherit = TAS,
                      
                      public = list(
                        fundName = NA,
                        initialize = function(classTAS,fundName) {
                          super$initialize(numberTAS=paste0(classTAS$numberTAS,"_",fundName),nameTAS=classTAS$nameTAS, quarterTAS=classTAS$quarterTAS,
                                           fyTAS=classTAS$fyTAS, linesTAS = classTAS$linesTAS$clone(deep=TRUE),
                                           fyAppropriation = classTAS$fyAppropriation,fyEndAvail = classTAS$fyEndAvail,resource=classTAS$resource,
                                           obligated=classTAS$obligated,unobligated=classTAS$unobligated)
                          stopifnot(class(classTAS)[[1]] == "TAS")
                          stopifnot(fundName == "Equity" | fundName == "Admin")
                          
                          self$fundName <- fundName
                          
                        },
                        print = function(...) {
                          cat("========================================================================================================","\n")
                          cat("Broken Down TAS: \n")
                          cat("Fund: ", self$fundName,"\n",sep="")
                          cat("========================================================================================================","\n")
                          cat("  TAS Number:          ", self$numberTAS, "\n", sep = "")
                          cat("  Account Name:        ", self$nameTAS, "\n", sep = "")
                          cat("  Reporting Period:    ", "FY",self$fyTAS,"-Q",self$quarterTAS, "\n", sep = "")
                          cat("  FY Appropriation:    ",self$fyAppropriation,"\n",sep="")
                          cat("  FY End Availability: ",self$fyEndAvail,"\n",sep="")
                          cat("========================================================================================================","\n")
                          for (indx in 1:self$linesTAS$length) {
                            print(paste0("Line ",self$linesTAS$keys[indx]," = ",format(self$linesTAS$values[indx],scientific=FALSE,big.mark = ",")))
                          }
                          cat("========================================================================================================","\n")
                          cat("     Resource    = $ ",format(self$resource,scientific=FALSE,big.mark=","),"\n",sep="")
                          cat("     Obligated   = $ ",format(self$obligated,scientific=FALSE,big.mark=","),"\n",sep="")
                          cat("     Unobligated = $ ",format(self$unobligated,scientific=FALSE,big.mark=","),"\n",sep="")
                          cat("========================================================================================================","\n")
                          invisible(self)
                        }
                      )              
)

updateTAS <- function(taSymbol) {
  # Takes a TAS object
  # Updates the TAS object's attributes by using the class' methods
  taSymbol$getfyAppropriation()
  taSymbol$getfyEndAvail()
  taSymbol$getResource()
  taSymbol$getObligated()
  taSymbol$getUnobligated()
}

#####################################
## Data Preparation and Processing ##
#####################################

# The following statement is a regular expression to capture different formats of writing valid quarters in DFC
reQuarters <- "(^[qQ][1234]$)|(^[qQ](.*)[ r][1234]$)"

# The following function detects the column position of each reported quarter recorded in the uploaded sf133 file

rwQr <- NA
rwTx <- NA
indxQ1 <- NA
indxQ2 <- NA
indxQ3 <- NA
indxQ4 <- NA
repQrCol <- NA

findQrColPos <- function(sf133File) {
  # Assumes a tibble or data frame of unstructured data from an SF-133 report
  # Locates the column position of the reporting quarter
  findFlag <- FALSE
  dfCols <- ncol(sf133File)
  dfRows <- nrow(sf133File)
  currRow <- 1
  while (findFlag==FALSE & currRow < dfRows) {
    lineCols <- rep(NA,dfCols)
    if (currRow == dfRows-1) {
      stop("No reporting quarter labels found in SF-133 file. Label columns manually, save the modified SF-133 file, and load the file again")
    }
    for (indx in 1:dfCols) {
      lineCols[indx] <- sf133File[currRow,indx]
    }
    regDetect <- str_detect(lineCols,reQuarters)
    for (indx in 1:dfCols) {
      if (isTRUE(regDetect[[indx]])) {
        rwTx <<- lineCols
        findFlag <- TRUE
      }
    }
    currRow <- currRow + 1
  }
  rwQr <<- currRow - 1
  for (indx in seq_along(rwTx)) {
    if (is.na(str_sub(rwTx[[indx]],-1))) {
      # Do Nothing
    } else if (as.double(str_sub(rwTx[[indx]],-1))==1) {
      indxQ1 <<- indx
    } else if (as.double(str_sub(rwTx[[indx]],-1))==2) {
      indxQ2 <<- indx
    } else if (as.double(str_sub(rwTx[[indx]],-1))==3) {
      indxQ3 <<- indx
    } else if (as.double(str_sub(rwTx[[indx]],-1))==4) {
      indxQ4 <<- indx
    } 
  }
  reCurrQr <- paste0("^indxQ",quarter,"$")
  qrAvail <- c(indxQ1,indxQ2,indxQ3,indxQ4)
  qrAvailTx <- c("indxQ1","indxQ2","indxQ3","indxQ4")
  qrAvailVec <- str_detect(qrAvailTx,reCurrQr)
  qrLoc <- which(qrAvailVec==TRUE)
  repQrCol <<- qrAvail[[qrLoc]] 
  return(repQrCol)
}

findQrColPos(sf133Raw)

readsf133File <- function(sf133F) {
  # Assumes an SF-133 Report converted to tibble
  # Converts TASs in the tibble in TAS objects
  tasNameLoc <- which(sf133F[,1]=="TAS:")
  sfTASnamesMtrx <- sf133F[tasNameLoc,]
  sfTAStbl <- sfTASnamesMtrx[,2]
  sfTAStbl <- sfTAStbl %>%
    rename(rawName = ...2) %>%
    mutate(tasNum = NA, tasName = NA)
  sfTAStblLen <- nrow(sfTAStbl)
  for (indx in 1:nrow(sfTAStbl)){
    spliVals <- str_split(sfTAStbl[indx,1]," {2,}")
    sfTAStbl[indx,2] <- spliVals[[1]][[1]]
    sfTAStbl[indx,3] <- spliVals[[1]][[2]]
  }
  sfTAStbl <- sfTAStbl %>%
    mutate(tasNumLoc = tasNameLoc)
  sfTAStbl <- sfTAStbl %>%
    mutate(tasObjtName = NA)
  sfTAStbl <- sfTAStbl %>%
    add_row(tasNumLoc = nrow(sf133F))
  for (indx in 1:nrow(sfTAStbl)) {
    sfTAStbl[indx,5] <- paste0("tas",str_replace_all(sfTAStbl[[indx,2]],"-","_"))
  }
  for (indx in 1:sfTAStblLen) {
    assign(sfTAStbl[[indx,5]],TAS$new(sfTAStbl[[indx,2]],sfTAStbl[[indx,3]],quarter,fiscalYear),envir = .GlobalEnv)
    for (jndx in seq(as.integer(sfTAStbl[[indx,4]]),as.integer(sfTAStbl[[indx+1,4]]))) {
      if (isTRUE(str_detect(sf133F[[jndx,1]],"[1234567890]{4}")) & isTRUE(!str_detect(sf133Raw[[jndx,1]],"[ampAMP]")) & sf133F[[jndx,1]] != ifelse(is.na(sf133F[[jndx-1,1]]),0,sf133F[[jndx-1,1]])) {
        #print(paste0("went if route. Val= ",sf133F[[jndx,1]]))
        eval(parse(text=paste0(sfTAStbl[[indx,5]],"$linesTAS['",sf133F[[jndx,1]],"']<<-as.double(",ifelse(is.na(sf133F[[jndx,repQrCol]]),0,sf133F[[jndx,repQrCol]]),")")))
      } else if (isTRUE(str_detect(sf133F[[jndx,1]],"[1234567890]{4}")) & isTRUE(!str_detect(sf133Raw[[jndx,1]],"[ampAMP]")) & sf133F[[jndx,1]] == ifelse(is.na(sf133F[[jndx-1,1]]),0,sf133F[[jndx-1,1]])) {
        #print(paste0("went if else route. Val= ",sf133F[[jndx,1]]," NOT UNIQUE"))
        eval(parse(text=paste0(sfTAStbl[[indx,5]],"$linesTAS['",sf133F[[jndx,1]],"']<<-(as.double(",sfTAStbl[[indx,5]],"$linesTAS['",sf133F[[jndx,1]],"']",")+as.double(",ifelse(is.na(sf133F[[jndx,repQrCol]]),0,sf133F[[jndx,repQrCol]]),"))")))
      } #else { # Test to check not matching values. Currently deactivated
      #print(paste0("went else route. Val= ",sf133F[[jndx,1]]))
      #}
    }
  }
  for (indx in 1:sfTAStblLen){
    eval(parse(text=paste0("updateTAS(",sfTAStbl[[indx,5]],")")))
  }
  return(sfTAStbl)
}

readsf133File(sf133Raw)

checkTASBalance <- function(aTAS) {
  # Assumes a TAS object
  # Returns the balance [resource - obligated - unobligated] and a Boolean that is equal to TRUE is the TAS is balanced or FALSE if the TAS is not balanced
  # To be balanced the balance value should be equal to zero
  balance <- aTAS$resource - aTAS$obligated - aTAS$unobligated
  if (balance == 0 ) {
    balTAS <- TRUE
  } else {
    balTAS <- FALSE
  }
  #print(format(aTAS$resource,scientific=FALSE,big.mark=","))
  #print(format(aTAS$obligated,scientific=FALSE,big.mark=","))
  #print(format(aTAS$unobligated,scientific=FALSE,big.mark=","))
  return(c(format(balance,scientific=FALSE,big.mark=","),balTAS))
}

breakDownTAS <- function(framesFinRep) {
  ## Assumes a tibble with TASs that have been break down into Equity and Admin funds
  ## Returns derived TAS objects for each of the aforementioned funds
  
  # The following statements read  through the framesFinReporting file and locate TASs in the file as well as positions of Equity and Admin features
  rwTot <- nrow(framesFinRep)
  colTot <- ncol(framesFinRep)
  tasNamePos <- c()
  inFileTASs <- c()
  equityPos <- NA
  adminPos <- NA
  
  for (indx in 1:rwTot) {
    if (str_sub(framesFinRep[[indx,1]],1,3) == "TAS") {
      rw <- indx #as.numeric(indx)
      tasNamePos <- c(tasNamePos,rw)
    }
  }
  
  for (indx in seq(tasNamePos)) {
    inFileTASs <- c(inFileTASs,str_sub(framesFinRep[[tasNamePos[[indx]],1]],5,str_length(framesFinRep[[tasNamePos[[indx]],1]])))
  }
  
  eqtFlag <- TRUE
  currRw <- 1
  while (isTRUE(eqtFlag) & currRw < rwTot) {
    if (currRw == rwTot -1) {
      stop("No columns with label 'Equity' found")
    }
    for (indx in seq(colTot)) {
      if (ifelse(is.na(framesFinRep[[currRw,indx]]),0,framesFinRep[[currRw,indx]])=="Equity") {
        equityPos <- indx
        eqtFlag <- FALSE
      }
    }
    currRw <- currRw + 1
  }
  
  adminFlag <- TRUE
  currRw <- 1
  while (isTRUE(adminFlag) & currRw < rwTot) {
    if (currRw == rwTot -1) {
      stop("No columns with label 'Admin' found")
    }
    for (indx in seq(colTot)) {
      if (ifelse(is.na(framesFinRep[[currRw,indx]]),0,framesFinRep[[currRw,indx]])=="Admin") {
        adminPos <- indx
        adminFlag <- FALSE
      }
    }
    currRw <- currRw + 1
  }  
  
  inFileTasObjct <- vector('character',length=length(inFileTASs))
  for (indx in seq_along(inFileTasObjct)) {
    nameTAS <- paste0("tas",str_replace_all(inFileTASs[[indx]],c("-"="_")),"_000")
    inFileTasObjct[[indx]] <- nameTAS
  }
  
  # The following statements create derived TAS class objects with the information in framesFinReporting
  
  # This loop initializes the Equity TAS sub class
  for (indx in seq_along(inFileTasObjct)) {
    eval(parse(text=paste0(inFileTasObjct[[indx]],"_Equity <<- derivedTAS$new(",inFileTasObjct[[indx]],",fundName = 'Equity')")))
  }
  
  # This loop reset the Equity TAS sub class
  for (indx in seq_along(inFileTasObjct)) {
    for (jndx in eval(parse(text=paste0("1:length(",inFileTasObjct[[indx]],"_Equity$linesTAS$keys)")))) {
      eval(parse(text=paste0(inFileTasObjct[[indx]],"_Equity$linesTAS[",inFileTasObjct[[indx]],"_Equity$linesTAS$keys","[[",jndx,"]]","] <<- 0")))
    }
    eval(parse(text=paste0("updateTAS(",inFileTasObjct[[indx]],"_Equity)")))
  }
  
  # This loop update the lines with the broken down amounts for the Equity sub class
  for (indx in seq_along(inFileTasObjct)) {
    tryCatch(
      {
        for (jndx in eval(parse(text=paste0("(tasNamePos[[indx]]+1):(tasNamePos[[indx+1]]-1)")))) {
          if (isTRUE(str_detect(framesFinRep[[jndx,1]],"^[1234567890]{4}"))) {
            eval(parse(text=paste0(inFileTasObjct[[indx]],"_Equity$linesTAS['",framesFinRep[[jndx,1]],"'] <<- ",framesFinRep[[jndx,equityPos]])))
          }
          #print(paste0(inFileTasObjct[[indx]],"_Equity$linesTAS[",inFileTasObjct[[indx]],"_Equity$linesTAS$keys","[[",jndx,"]]","] <- 0"))
        }
        #print(paste0("from ",tasNamePos[[indx]]+1," to ",tasNamePos[[indx+1]]-1))
        #print("went without error handling")
      },
      error = function(e) {
        for (jndx in eval(parse(text=paste0("(tasNamePos[[indx]]+1):(rwTot)")))) {
          if (isTRUE(str_detect(framesFinRep[[jndx,1]],"^[1234567890]{4}"))) {
            eval(parse(text=paste0(inFileTasObjct[[indx]],"_Equity$linesTAS['",framesFinRep[[jndx,1]],"'] <<- ",framesFinRep[[jndx,equityPos]])))
          }
          #print(paste0(inFileTasObjct[[indx]],"_Equity$linesTAS[",inFileTasObjct[[indx]],"_Equity$linesTAS$keys","[[",jndx,"]]","] <- 0"))
        }
        #print(paste0("from ",tasNamePos[[indx]]+1," to ",rwTot))
        #print("went through the error handling statement") 
      }
    )
    eval(parse(text=paste0("updateTAS(",inFileTasObjct[[indx]],"_Equity)")))
  }
  
  # This loop initializes the Admin TAS sub class
  for (indx in seq_along(inFileTasObjct)) {
    eval(parse(text=paste0(inFileTasObjct[[indx]],"_Admin <<- derivedTAS$new(",inFileTasObjct[[indx]],",fundName = 'Admin')")))
  }
  
  # This loop reset the Admin TAS sub class
  for (indx in seq_along(inFileTasObjct)) {
    for (jndx in eval(parse(text=paste0("1:length(",inFileTasObjct[[indx]],"_Admin$linesTAS$keys)")))) {
      eval(parse(text=paste0(inFileTasObjct[[indx]],"_Admin$linesTAS[",inFileTasObjct[[indx]],"_Admin$linesTAS$keys","[[",jndx,"]]","] <<- 0")))
    }
    eval(parse(text=paste0("updateTAS(",inFileTasObjct[[indx]],"_Admin)")))
  }
  
  # This loop update the lines with the broken down amounts for the Admin sub class
  for (indx in seq_along(inFileTasObjct)) {
    tryCatch(
      {
        for (jndx in eval(parse(text=paste0("(tasNamePos[[indx]]+1):(tasNamePos[[indx+1]]-1)")))) {
          if (isTRUE(str_detect(framesFinRep[[jndx,1]],"^[1234567890]{4}"))) {
            eval(parse(text=paste0(inFileTasObjct[[indx]],"_Admin$linesTAS['",framesFinRep[[jndx,1]],"'] <<- ",framesFinRep[[jndx,adminPos]])))
          }
        }
      },
      error = function(e) {
        for (jndx in eval(parse(text=paste0("(tasNamePos[[indx]]+1):(rwTot)")))) {
          if (isTRUE(str_detect(framesFinRep[[jndx,1]],"^[1234567890]{4}"))) {
            eval(parse(text=paste0(inFileTasObjct[[indx]],"_Admin$linesTAS['",framesFinRep[[jndx,1]],"'] <<- ",framesFinRep[[jndx,adminPos]])))
          }
        }
      }
    )
    eval(parse(text=paste0("updateTAS(",inFileTasObjct[[indx]],"_Admin)")))
  }
  return(inFileTasObjct)
}

breakDownTAS(framesFinReporting)

# This statement loads the TASs currently used in the Appropriators Report
currUsedTASs <- c(tas077_2019_2021_0110_000,
                  tas077_X_0110_000,
                  tas077_2020_2022_0110_000,
                  tas077_2020_2023_0110_000,
                  tas077_2020_2022_4483_000_Equity,
                  tas077_2021_2023_0110_000,
                  tas077_2021_2023_4483_000_Equity,
                  tas077_X_4483_000,
                  tas077_2020_2022_4483_000_Admin,
                  tas077_2020_2024_4483_000,
                  tas077_2021_2023_4483_000_Admin,
                  tas077_2021_2025_4483_000)

currUsedTASs

remBalsTbl <- function(...) {
  # Assumes a vector with TAS objects' names
  # Prints a summary vector indicating whether TASs are balanced or not
  # Creates the 'Remaining Unobligated and Available Balances of Resources' tibble using the provided TASs
  tasNms <- c(...)
  numTas <- length(tasNms)
  remBalResources <<- data.frame(
    Subsidy_or_Program_Budget=character(length = numTas),
    Fiscal_Year_Appropriation=character(length = numTas),
    Fiscal_Year_End_of_Availability=character(length = numTas),
    Resource=character(length = numTas),
    Obligated_or_Unexpended=character(length = numTas),
    Unobligated=character(length = numTas),
    stringsAsFactors=FALSE)
  remBalResources <<- as_tibble(remBalResources)
  for (indx in 1:numTas) {
    remBalResources[[indx,1]] <<- tasNms[[indx]]$numberTAS
    remBalResources[[indx,2]] <<- as.character(tasNms[[indx]]$fyAppropriation)
    remBalResources[[indx,3]] <<- as.character(tasNms[[indx]]$fyEndAvail)
    remBalResources[[indx,4]] <<- format(tasNms[[indx]]$resource,scientific=FALSE,big.mark=",")
    remBalResources[[indx,5]] <<- format(tasNms[[indx]]$obligated,scientific=FALSE,big.mark=",")
    remBalResources[[indx,6]] <<- format(tasNms[[indx]]$unobligated,scientific=FALSE,big.mark=",")
  }
  balTasSummary <<- character(length=numTas)
  for (indx in 1:numTas) {
    tempVal <- checkTASBalance(tasNms[[indx]])
    balTasSummary[[indx]] <<- tempVal[[2]]
  }
  for (indx in 1:numTas) {
    if (balTasSummary[[indx]]=="TRUE") {
      txt <- paste0(tasNms[[indx]]$numberTAS," is balanced.")
      print(cat(paste0("\033[0;", 32, "m",txt,"\033[0m","\n")))
    } else if (balTasSummary[[indx]]=="FALSE") {
      txt <- paste0(tasNms[[indx]]$numberTAS," is NOT balanced. Review TAS values.")
      print(cat(paste0("\033[0;", 31, "m",txt,"\033[0m","\n")))
    }
  }
  print(table(balTasSummary))
  return(remBalResources)
}

remBalsTbl(currUsedTASs)

################################
## Data Analysis and Modeling ##
################################

# This module does not carry any mathematical analysis or modeling 

######################
## Output: csv File ##
######################

# The following statements write a csv file with the output of the module: the 'Remaining Unobligated and Available Balances of Resources' table

basePath1 <- "/Users/SUINCA/Desktop/DFC - Telework/reportsAutomation"
basePath2 <- paste0("/EnterpriseDataAnalyst/1 - External Data Requests/","FY",fiscalYear,"/2 - Quarterly - Appropriators Report/","Q",quarter,"/")
outputFileName <- "remUnAvailVals.csv"
pathOutput <- paste0(basePath1,basePath2,outputFileName)
#pathOutput
write_csv(remBalResources,pathOutput)

######################
##    MODULE ENDS   ##
######################
