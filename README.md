# Fixing FMPS Data

**Coding Language:** R (tested in R 4.2.3 and RStudio 2023.03.0)

**Objective:** Read TSI WCPC<sup>a</sup> and FMPS<sup>b</sup> data, modify files to account for lag time and time series alignement, and change FMPS signal. 

**References:** Zimmerman N, Jeong CH, Wang JM, Ramos M, Wallace JS, Evans GJ. _A source-independent empirical correction procedure for the fast mobility and engine exhaust particle sizers_. Atmospheric Environment. 2015 Jan 1;100:178-84. (https://wwww.sciencedirect.com/science/article/pii/S1352231014008516)

<sup>a</sup>WCPC: Water Condensation Particle Counter

<sup>b</sup>FMPS: Fast Mobility Particle Spectrometer

**Required R packages:**

```
install.packages(readxl)
install.packages(openair)
install.packages(tidyverse)
install.packages(xts)
install.packages(forecast)

library(readxl)
library(openair)
library(tidyverse)
library(xts)
library(forecast)
```
