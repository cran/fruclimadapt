#' Calculation of chill portions from hourly temperature data (Dynamic model)
#'
#' The function calculates chill portions according to the Dynamic model
#' proposed by Fishman et al. (1987a,b), using the formulas extracted by
#' Luedeling et al (2009) from functions produced by Erez and Fishman (1990), 
#' available at the University of California, Agriculture and Natural Resources
#' (UC ANR) website http://ucanr.edu/sites/fruittree/files/49319.xls. To date, 
#' chill portions is the best existing model for most growing regions, so chill
#' fulfilment should  be calculated preferably using this method, especially
#' when transferring varieties from one region to another, or in studies on 
#' climate change.
#'
#' @param climdata a dataframe with hourly temperature data. It
#' must contain the columns Year, Month, Day, DOY, Temp.
#' @param Start parameter indicating the day of the year when chill
#' accumulation is supposed to start.
#' @return dataframe with the chill accumulated for all the seasons in the
#' dataset. Seasons begin at the start date and end the day before the start
#' date of the following year.
#' It contains the columns Year, Month, Day, DOY, Chill
#' @author Carlos Miranda, \email{carlos.miranda@@unavarra.es}
#' @references
#'
#' Erez A, Fishman S, Linsley-Noakes GC and Allan P, 1990. The dynamic model for
#' rest completion in peach buds. Acta Horticulturae 276, 165-174.
#'
#' Fishman S, Erez A and Couvillon GA, 1987a. The temperature dependence of
#' dormancy breaking in plants - computer simulation of processes studied under
#' controlled temperatures. Journal of Theoretical Biology 126, 309-321.
#'
#' Fishman S, Erez A and Couvillon GA, 1987b. The temperature dependence of
#' dormancy breaking in plants - mathematical analysis of a two-step model
#' involving a cooperative transition. Journal of Theoretical Biology 124,
#' 473-483.
#'
#' Luedeling E, Zhang M, Luedeling V and Girvetz EH, 2009. Sensitivity of
#' winter chill models for fruit and nut trees to climatic changes expected in
#' California's Central Valley. Agriculture, Ecosystems and Environment 133,
#' 23-31.
#' @examples
#'
#' # Generate hourly temperatures
#' library(magrittr)
#' library(dplyr)
#' library(lubridate)
#' Weather <- Tudela_DW %>%
#'    filter (Tudela_DW$Year<=2002)
#' Tudela_HT <- hourly_temps(Weather,42.13132)
#' # Calculate chill as chill portions, starting on DOY 305
#' Chill_p <- chill_portions(Tudela_HT,305)
#' 
#' @export chill_portions
#' @import magrittr dplyr 
#' @importFrom lubridate make_date
#' @importFrom data.table setDT rleid

chill_portions <- function(climdata, Start){

  e0<-4153.5
  e1<-12888.8
  a0<-139500
  a1<-2567000000000000000
  slp<-1.6
  tetmlt<-277
  aa<-a0/a1
  ee<-e1-e0

  climdata <- climdata %>% mutate(Temp_K=Temp+273,
                                  ftmprt=slp*tetmlt*(Temp_K-tetmlt)/Temp_K,
                                  sr=exp(ftmprt),
                                  xi=sr/(1+sr),
                                  xs=aa*exp(ee/Temp_K),
                                  akl=a1*exp(-e1/Temp_K),
                                  delt=0)

  xs<-climdata[,"xs"]
  xi<-climdata[,"xi"]
  akl<-climdata[,"akl"]
  S<-vector(length=nrow(climdata))
  S[1]<-0
  E<-S

  for (r in 2:nrow(climdata)){
    if(E[r-1]<1){
      S[r]<-E[r-1]
      E[r]<-xs[r]-(xs[r]-S[r])*exp(-akl[r])
    } else{
      S[r]<-E[r-1]-E[r-1]*xi[r-1]
      E[r]<-xs[r]-(xs[r]-S[r])*exp(-akl[r])
      }
  }

 climdata <- climdata %>% mutate(Inter_E=E,
                                 delt=ifelse(Inter_E<1,0,Inter_E*xi))

 setDT(climdata)[, Chill := cumsum(delt), by = rleid(DOY == Start & Hour==0)]
 climdata <- climdata %>%
   select(Year, Month, Day, DOY, Hour, Chill) %>%
   filter(Hour==23) %>%
   select(-Hour)
 }

