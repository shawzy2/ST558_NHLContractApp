#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(shinydashboard)
library(DT)
library(dplyr)

df_data_eda <- read.csv('data/skater_contracts_stats_eda.csv')
df_data_model <- read.csv('data/skater_contracts_stats.csv')
colourBy <- c('expiraryStatus', 'type', 'position', 'nationality', 'handness')

dashboardPage(
  dashboardHeader(title = "NHL Contract Predictor"),
  
  ## Sidebar content
  dashboardSidebar(
    sidebarMenu(
      menuItem("About", tabName = "about", icon = icon("address-card")),
      menuItem("Data Exploration", tabName = "dataExploration", icon = icon("glyphicon glyphicon-stats", lib = "glyphicon")),
      menuItem("Modeling", tabName = "modeling", icon = icon("glyphicon glyphicon-scale", lib = "glyphicon")),
      menuItem("Data", tabName = "data", icon = icon("glyphicon glyphicon-folder-open", lib = "glyphicon"))
      
    )
  ),
  ## Body content
  dashboardBody(
    tabItems(
      # About tab content
      tabItem(tabName = "about",
              h2('Predicting NHL Contracts'),
              p('This application is an exploration into predicting contracts of NHL players. 
                Analysis such as this are useful to NHL front offices in determining market value of players.
                The original inspiration for this idea is the book, Moneyball by Michael Lewis, where the Oakland A\'s,
                who held the MLB\'s lowest payroll, utilized statistics to identify undervalued players.'),
              p('In the NHL, where there is a salary cap, this analysis is even more critical to the building of succesful teams.'),
              
              h2('Data Source'),
              p('Our source for data will be CapFriendly.com -- a collection of NHL contracts since before 2000.
                Since this data is not downloadable, we will build a web scraper using python, and collect the contract history
                of players on NHL rosters since 2016. In total, we were able to collect 7796 contracts from 2656 players. Additionally,
                we collected 69763 seasons of junior and professional statistics for these players'),
              
              h2('Purpose of Tabs'),
              p('This application has 3 tabs: Data Exploration, Modeling, and Data. The pupose of the data exploration tab 
                is to allow users to create their own visuzalizations on the data. The Modeling tab allows users to select a model 
                to train to predict total contract value. Finally, the data tab allows users to scroll through the raw data.'),
              
              img(src = "nhlLogo.jpeg", height = 360, width = 640)
      ),
      
      # Data Exploration Tab
      tabItem(tabName = "dataExploration",
              h2("Data Exploration"),
              h4('Filters'),
              fluidRow(
                box(
                  title = 'Player Filters',
                  selectInput('select_position', label = 'Position', choices = append(c('All'), unique(df_data_eda$position)), selected = 'All'),
                  selectInput('select_handness', label = 'Handness', c('Left', 'Right', 'All'), selected = 'All'),
                  selectInput('select_nation', label = 'Nation', choices = append(c('All'), unique(df_data_eda$nationality)), selected = 'All'),
                  sliderInput("slider_height", "Player Height (inches)", min = min(df_data_eda$height), max = max(df_data_eda$height), value = c(min(df_data_eda$height), max = max(df_data_eda$height))),
                  sliderInput("slider_weight", "Player Weight (lbs)", min = min(df_data_eda$weight), max = max(df_data_eda$weight), value = c(min(df_data_eda$weight), max = max(df_data_eda$weight))),
                  sliderInput("slider_age", "Player Age at Signing (days)", min = min(df_data_eda$ageAtSigningInDays), max = max(df_data_eda$ageAtSigningInDays), value = c(min(df_data_eda$ageAtSigningInDays), max = max(df_data_eda$ageAtSigningInDays)))
                ),
                box(
                  title = 'Contract Filters',
                  selectInput('select_type', label = 'Contract Type', choices = append(c('All'), unique(df_data_eda$type)), selected = 'All'),
                  sliderInput("slider_totalValue", "Total Value of Contract ($USD)", min = min(df_data_eda$totalValue), max = max(df_data_eda$totalValue), value = c(min(df_data_eda$totalValue), max = max(df_data_eda$totalValue))),
                  sliderInput("slider_length", "Total Length of Contract (years)", min = min(df_data_eda$length), max = max(df_data_eda$length), value = c(min(df_data_eda$length), max = max(df_data_eda$length))),
                  dateRangeInput("daterange_signingDate", "Signing Date", start = min(df_data_eda$signingDate), end = max(df_data_eda$signingDate))
                )
              ),
              fluidRow(
                div(style = "height:10px;"),
                div(style = "height:15px; border-radius: 1px; background: #D8D8D8;"),
                div(style = "height:10px;"),
              ),
              h4('Plots'),
              fluidRow(
                sidebarPanel(
                  title = 'Plot Builder',
                  selectInput('select_plotType', label = 'Plot Type', choices = c('Scatter', 'Line', 'Box', 'Correlation'), selected = 'Scatter'),
                  conditionalPanel(
                    condition = "input.select_plotType == 'Scatter'",
                    tags$div(selectInput('select_plotX', label = 'X Variable', choices = colnames(select_if(df_data_eda, is.numeric)), selected = 'g', width = '100px'), style="display:inline-block"),
                    tags$div(selectInput('select_plotY', label = 'Y Variable', choices = colnames(select_if(df_data_eda, is.numeric)), selected = 'totalValue', width = '100px'), style="display:inline-block"),
                    tags$div(selectInput('select_plotColour', label = 'Colour By', choices = colourBy, selected = 'position', width = '100px'), style="display:inline-block")
                  ),
                  conditionalPanel(
                    condition = "input.select_plotType == 'Line'",
                    tags$div(selectInput('select_plotX', label = 'X Variable', choices = c('seasonId'), selected = 'seasonId', width = '100px'), style="display:inline-block"),
                    tags$div(selectInput('select_plotY', label = 'Y Variable', choices = c('totalValue'), selected = 'totalValue', width = '100px'), style="display:inline-block")
                  ),
                  conditionalPanel(
                    condition = "input.select_plotType == 'Box'",
                    tags$div(selectInput('select_boxX', label = 'X Variable', choices = c('seasonId', 'type', 'position', 'handness', 'draftRound'), selected = 'position', width = '100px'), style="display:inline-block"),
                    tags$div(selectInput('select_boxY', label = 'Y Variable', choices = c('totalValue', 'length', 'capHitPercentage'), selected = 'totalValue', width = '100px'), style="display:inline-block")
                  ),
                  conditionalPanel(
                    condition = "input.select_plotType == 'Correlation'",
                    selectInput('select_corrVars', label = 'Variables', choices = colnames(select_if(df_data_eda, is.numeric)), selected = c('totalValue', 'g', 'playoff_g'), multiple = TRUE)
                  )
                ),
                mainPanel(
                  plotOutput("plot")
                )
              ),
              fluidRow(
                div(style = "height:10px;"),
                div(style = "height:15px; border-radius: 1px; background: #D8D8D8;"),
                div(style = "height:10px;"),
              ),
              h4('Summaries'),
              fluidRow(
                sidebarPanel(
                  title = 'Summary Builder',
                  selectInput('select_summaryType', label = 'Summary Type', choices = c('Contingency Table', '5 Number Summary'), selected = 'Scatter'),
                  conditionalPanel(
                    condition = "input.select_summaryType == 'Contingency Table'",
                    tags$div(selectInput('select_sum1', label = 'Variable 1', choices = colnames(select_if(df_data_eda, is.character)), selected = 'position', width = '100px'), style="display:inline-block"),
                    tags$div(selectInput('select_sum2', label = 'Variable 2', choices = colnames(select_if(df_data_eda, is.character)), selected = 'handness', width = '100px'), style="display:inline-block")
                  ),
                  conditionalPanel(
                    condition = "input.select_summaryType == '5 Number Summary'",
                    tags$div(selectInput('select_sumVar', label = 'Variable 1', choices = colnames(select_if(df_data_eda, is.numeric)), selected = 'totalValue', width = '100px'), style="display:inline-block"),
                  )
                ),
                mainPanel(
                  DTOutput('summary')
                )
              )
      ),
      
      # Modeling Tab
      tabItem(tabName = "modeling",
              h2("Modeling tab content"),
              tabsetPanel(
                tabPanel(
                  "Info",
                  h4('Linear Regression'),
                  p('Linear regression is one of the commonly used supervised methods for modeling and useful tool for predicting a quantitative response on the basis of a single or multiple predictor variables. 
                    The idea of linear regression is that the model finds the best fit line between predictor variables and response variable, minimizing sum of squared errors.
                    Here we will fit a linear regression model to predict the totalValue of a contract.'),
                  h4('Decision Tree'),
                  p('Tree-based method splits up response variable into subsets based on their relationship to one or more predictor variables. 
                    Because it is easy to understand and interpret output and no statistical assumptions is necessary, regression tree (continuous variable) and classification tree (group membership) are commonly used.
                    Here we will fit a regression tree to predict the totalValue of a contract.'),
                  h4('K Nearest Neighbors'),
                  p('KNN is one of the simplist regression methods. The idea is to use a distance metric to find the n nearest observations. We estimate the response variable by
                    finding the average of these n nearest observations. Here we will fit KNN regression using the 2norm as a distance metric to predict totalValue of a contract.')
                ),
                tabPanel(
                  "Fitting",
                  h3('Model Training'),
                  fluidRow(
                    box(
                      title = 'All Models Settings', width=12,
                      sliderInput("slider_trainProp", "Proportion of Data for Training", min = 0.5, max = 0.9, value = 0.7),
                      selectInput('select_modelVars', label = 'Variables to Include', choices = c('seasonId', 'heigh', 'weight', 'gp', 'g', 'a', 'pim'), selected = colnames(select(df_data_model, -link, -totalValue)), multiple = TRUE)
                      
                    )
                  ),
                  fluidRow(
                     box(
                       title = 'Decision Tree',
                       sliderInput("slider_dtRange", "Range of Tree-Depth Tuning Parameter", min = 1, max = 15, value = c(1, 15))
                     ),
                     box(
                       title = 'K-Nearest Neighbors',
                       sliderInput("slider_knnRange", "Range of K Tuning Parameter", min = 1, max = 9, value = c(1, 9), step = 2)
                     ),
                     box(
                       title = 'Linear Regression',
                       p('No hyperparameters to include')
                     ),
                     box(
                       title = 'Train Models',
                       actionButton("action_train", "Click here to train Models")
                     )
                  ),
                  fluidRow(
                    div(style = "height:10px;"),
                    div(style = "height:15px; border-radius: 1px; background: #D8D8D8;"),
                    div(style = "height:10px;"),
                  ),
                  h3('Model Results'),
                  fluidRow(
                    box(
                      title = 'Decision Tree',
                      p('RMSE: '),
                      textOutput('rmse_dt')
                    ),
                    box(
                      title = 'K-Nearest Neighbors',
                      p('RMSE: '),
                      textOutput('rmse_knn')
                    ),
                    box(
                      title = 'Linear Regression',
                      p('RMSE: '),
                      textOutput('rmse_lm')
                    ),
                    box(
                      title = 'Model Selection',
                      p('The best performing model is: '),
                      textOutput('model_best_text')
                    )
                  ),
                ),
                tabPanel(
                  "Prediction",
                  h3('Pediction using Best Scoring Model'),
                  p('**Note: all other predictors will be the average across the dataset'),
                  box(
                    title = 'Predictors', width=12,
                    numericInput("numeric_gp", "Games Played", value = 82),
                    numericInput("numeric_g", "Goals", value = 20),
                    numericInput("numeric_a", "Assists", value = 20),
                    numericInput("numeric_plusminus", "Plus/Minus", value = 0),
                    numericInput("numeric_pim", "Penalties in Minutes", value = 34),
                  ),
                  actionButton("action_predict", "Predict!"),
                  box(
                    textOutput('predNewobs')
                  )
                )
              )
      ),
      
      # Data Tab
      tabItem(tabName = "data",
              h2("View/Download Data"),
              fluidRow(
                box(
                  title = 'Player Filters',
                  selectInput('select_positiond', label = 'Position', choices = append(c('All'), unique(df_data_eda$position)), selected = 'All'),
                  selectInput('select_handnessd', label = 'Handness', c('Left', 'Right', 'All'), selected = 'All'),
                  selectInput('select_nationd', label = 'Nation', choices = append(c('All'), unique(df_data_eda$nationality)), selected = 'All'),
                  sliderInput("slider_heightd", "Player Height (inches)", min = min(df_data_eda$height), max = max(df_data_eda$height), value = c(min(df_data_eda$height), max = max(df_data_eda$height))),
                  sliderInput("slider_weightd", "Player Weight (lbs)", min = min(df_data_eda$weight), max = max(df_data_eda$weight), value = c(min(df_data_eda$weight), max = max(df_data_eda$weight))),
                  sliderInput("slider_aged", "Player Age at Signing (days)", min = min(df_data_eda$ageAtSigningInDays), max = max(df_data_eda$ageAtSigningInDays), value = c(min(df_data_eda$ageAtSigningInDays), max = max(df_data_eda$ageAtSigningInDays)))
                ),
                box(
                  title = 'Contract Filters',
                  selectInput('select_typed', label = 'Contract Type', choices = append(c('All'), unique(df_data_eda$type)), selected = 'All'),
                  sliderInput("slider_totalValued", "Total Value of Contract ($USD)", min = min(df_data_eda$totalValue), max = max(df_data_eda$totalValue), value = c(min(df_data_eda$totalValue), max = max(df_data_eda$totalValue))),
                  sliderInput("slider_lengthd", "Total Length of Contract (years)", min = min(df_data_eda$length), max = max(df_data_eda$length), value = c(min(df_data_eda$length), max = max(df_data_eda$length))),
                  dateRangeInput("daterange_signingDated", "Signing Date", start = min(df_data_eda$signingDate), end = max(df_data_eda$signingDate))
                )
              ),
              fluidRow(
                column(12,
                       DTOutput('table')
                )
              ),
              downloadButton("downloadData", "Download")
      )
    )
  )
)
