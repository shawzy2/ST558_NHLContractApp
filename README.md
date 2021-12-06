# ST558_NHLContractApp

This is a final project for ST558 (Data Science for Statisticians). This application is a data suite that allowers users to explore NHL salary data. It contains 3 pages: data exploration, model fitting, and data viewing. Users can create plots and graphs, fit models to the response (total value of contract), and filter and download data as a csv file. 

### Setup

The following packages are required inside an RStudio environment to access the application:
```
library(shiny)
library(shinydashboard)
library(DT)
library(tidyverse)
library(corrplot)
library(caret)
```

These packages can be installed via the following block of code:
```
install.packages('shiny')
install.packages('shinydashboard')
install.packages('DT')
install.packages('tidyverse')
install.packages('corrplot')
install.packages('caret')
```

Once packages are installed, run the following on the RStudio console:

```
shiny::runGitHub(repo = 'ST558_NHLContractApp', username = 'shawzy2', ref = 'main')
```
