This package constitutes an interactive R problem set based on the RTutor package (https://github.com/skranz/RTutor). 

--- A RTutor problem set to interactively calculate and analyze environmental damages from driving electric cars, following the article "Are There Environmental Benefits from Driving Electric Vehicles? The Importance of Local Factors" By Stephen P. Holland, Erin T. Mansur, Nicholas Z. Muller, and Andrew J. Yates (2016) ---

## 1. Installation

RTutor and this package is hosted on Github. To install everything, run the following code in your R console.
```s
if (!require(devtools))
  install.packages("devtools")
source_gist("gist.github.com/skranz/fad6062e5462c9d0efe4")
install.rtutor(update.github=TRUE)

devtools::install_github("felsti/RTutorECars", upgrade_dependencies=FALSE)
```

## 2. Show and work on the problem set
To start the problem set first create a working directory in which files like the data sets and your solution will be stored. Then adapt and run the following code.
```s
library(RTutorECars)

# Adapt your working directory to an existing folder
setwd("C:/problemsets/RTutorECars")
# Adapt your user name
run.ps(user.name="Jon Doe", package="RTutorECars",
       load.sav=TRUE, sample.solution=FALSE)
```
If everything works fine, a browser window should open, in which you can start exploring the problem set.
