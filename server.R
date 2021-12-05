#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(DT)

# Define server logic required to draw a histogram
shinyServer(function(input, output) {
  
    # open df from drive
    df_data <- read.csv('data/skater_contracts_stats_eda.csv')
    filters <- c(df_data$heigh > 0)

    # output$distPlot <- renderPlot({
    # 
    #     # generate bins based on input$bins from ui.R
    #     x    <- faithful[, 2]
    #     bins <- seq(min(x), max(x), length.out = input$bins + 1)
    # 
    #     # draw the histogram with the specified number of bins
    #     hist(x, breaks = bins, col = 'darkgray', border = 'white')
    # 
    # })
    
    # data table on 'data' page
    output$table <- renderDT({
        # create filters
        filters <- createFilters()
        
        # apply filters
        df_data %>% filter(filters)
      },
      options = list(
        pageLength = 10, 
        scrollX = TRUE
      )
    )
    
    # Downloadable csv of selected dataset ----
    output$downloadData <- downloadHandler(
      filename = function() {
        paste("nhlcontracts.csv", sep = "")
      },
      content = function(file) {
        # create filters
        filters <- createFilters()
        
        # download filtered data
        write.csv(filter(df_data, filters), file, row.names = FALSE)
      }
    )
    
    createFilters <- function() {
      # create filters
      filters <- c(df_data$heigh > 0)
      if(input$select_type != 'All') {
        filters <- filters & df_data$type == input$select_type
      }
      if(input$select_position != 'All') {
        filters <- filters & df_data$position == input$select_position
      }
      if(input$select_nation != 'All') {
        filters <- filters & df_data$nationality == input$select_nation
      }
      if(input$select_handness != 'All') {
        filters <- filters & df_data$handness == input$select_handness
      }
      filters <- filters & df_data$totalValue >= input$slider_totalValue[1] & df_data$totalValue <= input$slider_totalValue[2]
      filters <- filters & df_data$length >= input$slider_length[1] & df_data$length <= input$slider_length[2]
      filters <- filters & df_data$height >= input$slider_height[1] & df_data$height <= input$slider_height[2]
      filters <- filters & df_data$weight >= input$slider_weight[1] & df_data$weight <= input$slider_weight[2]
      filters <- filters & df_data$ageAtSigningInDays >= input$slider_age[1] & df_data$ageAtSigningInDays <= input$slider_age[2]
      filters <- filters & df_data$signingDate >= input$daterange_signingDate[1] & df_data$signingDate <= input$daterange_signingDate[2]
      
      return(filters)
    }

})
