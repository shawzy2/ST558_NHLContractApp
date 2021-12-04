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
              h2("Data Exploration tab content")
      ),
      
      # Modeling Tab
      tabItem(tabName = "modeling",
              h2("Modeling tab content")
      ),
      
      # Data Tab
      tabItem(tabName = "data",
              h2("Data tab content")
      )
    )
  )
)

# # Define UI for application that draws a histogram
# shinyUI(fluidPage(
# 
#     # Application title
#     titlePanel("Old Faithful Geyser Data"),
# 
#     # Sidebar with a slider input for number of bins
#     sidebarLayout(
#         sidebarPanel(
#             sliderInput("bins",
#                         "Number of bins:",
#                         min = 1,
#                         max = 50,
#                         value = 30)
#         ),
# 
#         # Show a plot of the generated distribution
#         mainPanel(
#             plotOutput("distPlot")
#         )
#     )
# ))
