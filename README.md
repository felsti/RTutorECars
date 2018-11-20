This package constitutes an interactive R problem set based on the RTutor package (https://github.com/skranz/RTutor). 

--- A RTutor problem set to interactively calculate and analyze environmental damages from driving electric cars, following the article "Are There Environmental Benefits from Driving Electric Vehicles? The Importance of Local Factors" By Stephen P. Holland, Erin T. Mansur, Nicholas Z. Muller, and Andrew J. Yates (2016) ---

## 1. Installation

To install all required packages run the following code in your R console.
```s
install.packages("RTutor",repos = c("https://skranz-repo.github.io/drat/",getOption("repos")))

if (!require(devtools)) install.packages("devtools")
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
  auto.save.code = TRUE,clear.user = FALSE)
```
If everything works fine, a browser window should open, in which you can start exploring the problem set.