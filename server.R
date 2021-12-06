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
library(tidyverse)
library(corrplot)
library(caret)





# Define server logic required to draw a histogram
shinyServer(function(input, output) {
    # open df from drive
    df_data <- read.csv('data/skater_contracts_stats_eda.csv')
    df <- read.csv('data/skater_contracts_stats.csv')
    
    # create filters func
    createFilters <- function() {
      filters <- c(df_data$height > 0)
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
    }
    
    # plots on data exploration page
    output$plot <- renderPlot({
      # create filters
      filters <- createFilters()
      
      # apply filters
      g <- df_data %>% filter(filters) %>% ggplot()
      if(input$select_plotType == 'Scatter') {
        g <- g + geom_point(mapping = aes_string(x = input$select_plotX, y = input$select_plotY, colour = input$select_plotColour))
      }
      if(input$select_plotType == 'Line') {
        g <- df_data %>% filter(filters) %>%
              select_if(is.numeric) %>% 
              group_by(seasonId) %>%
              summarize_all(sum) %>%
              ggplot(mapping = aes_string(x = 'seasonId', y = 'totalValue')) + geom_line()
      } 
      if(input$select_plotType == 'Box') {
        g <- g + geom_boxplot(mapping = aes_string(group = input$select_boxX, x = input$select_boxX, y = input$select_boxY)) +
                  theme(axis.text.x = element_text(angle = 45))
      }
      if(input$select_plotType == 'Correlation') {
        g <-corrplot.mixed(cor(select(filter(df_data, filters), input$select_corrVars)))
      }
      g
    })
    
    # summaries on data exploration page
    output$summary <- renderDT({
      # create filters
      filters <- createFilters()
      
      # build summary table
      ret <- data.frame()
      if(input$select_summaryType == 'Contingency Table') {
        ret <- as.data.frame.matrix(table(filter(df_data, filters)[,input$select_sum1], filter(df_data, filters)[,input$select_sum2]))
      } else if(input$select_summaryType == '5 Number Summary') {
        ret <- as.matrix(summary(filter(df_data, filters)[,input$select_sumVar]))
      }
      ret
    },
    options = list(
      scrollX = TRUE
    ))
    
    # data table on 'data' page
    output$table <- renderDT({
        # create filters
        filters <- c(df_data$height > 0)
        if(input$select_typed != 'All') {
          filters <- filters & df_data$type == input$select_typed
        }
        if(input$select_positiond != 'All') {
          filters <- filters & df_data$position == input$select_positiond
        }
        if(input$select_nationd != 'All') {
          filters <- filters & df_data$nationality == input$select_nationd
        }
        if(input$select_handnessd != 'All') {
          filters <- filters & df_data$handness == input$select_handnessd
        }
        filters <- filters & df_data$totalValue >= input$slider_totalValued[1] & df_data$totalValue <= input$slider_totalValued[2]
        filters <- filters & df_data$length >= input$slider_lengthd[1] & df_data$length <= input$slider_lengthd[2]
        filters <- filters & df_data$height >= input$slider_heightd[1] & df_data$height <= input$slider_heightd[2]
        filters <- filters & df_data$weight >= input$slider_weightd[1] & df_data$weight <= input$slider_weightd[2]
        filters <- filters & df_data$ageAtSigningInDays >= input$slider_aged[1] & df_data$ageAtSigningInDays <= input$slider_aged[2]
        filters <- filters & df_data$signingDate >= input$daterange_signingDated[1] & df_data$signingDate <= input$daterange_signingDated[2]
        
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
    
    # reactive variables
    rmse_dt = reactiveVal(0)
    rmse_knn = reactiveVal(0)
    rmse_lm = reactiveVal(0)
    model_best_text = reactiveVal('')
    
    # train models when button is clicked
    observeEvent(input$action_train, {
      # test train split
      set.seed(123)
      train_rows <- sample(nrow(df), nrow(df)*input$slider_trainProp)
      trainData <- df[train_rows,]
      testData <- df[-train_rows,] 
      
      # get formula 
      form <- as.formula(paste('totalValue ~', paste(input$select_modelVars, collapse='+')))
      
      # train lm
      lm <- train(form,
                  data = trainData,
                  method = 'lm'
      )

      # train knn
      kgrid <- expand.grid(k = seq(input$slider_knnRange[1], input$slider_knnRange[2], by = 2))
      knn_fit <- train(form,
                       data = trainData,
                       method = "knn",
                       tuneGrid = kgrid,
                       trControl = trainControl(method = 'cv', n = 5)
      )

      # train regression classification tree
      rtree <- train(form,
                     data = trainData,
                     method = 'rpart',
                     tuneLength = input$slider_dtRange[2],
                     trControl = trainControl(method = 'cv', n = 5)
      )

      # evaluate test rmse
      predLm <- predict(lm, newdata = testData)
      rmse_lm(sqrt(mean((predLm - testData$totalValue)^2)))
      predknn <- predict(knn_fit, newdata = testData)
      rmse_knn(sqrt(mean((predknn - testData$totalValue)^2)))
      predrtree <- predict(rtree, newdata = testData)
      rmse_dt(sqrt(mean((predrtree - testData$totalValue)^2)))
      
      if ((rmse_dt() < rmse_knn()) & (rmse_dt() < rmse_lm())){
        model_best_text('Regression Decision Tree')
      } else if (rmse_knn() < rmse_lm()) {
        model_best_text('K-Nearest Neighbors')
      } else {
        model_best_text('Linear Regression')
      }
    })
    
    # render rmse to frontend on model fitting tab
    output$rmse_dt <- renderText({
      rmse_dt()
    })
    output$rmse_knn <- renderText({
      rmse_knn()
    })
    output$rmse_lm <- renderText({
      rmse_lm()
    })
    output$model_best_text <- renderText({
      model_best_text()
    })
    
    # predict a new obs
    predNewobs = reactiveVal(0)
    observeEvent(input$action_predict, {
      # get formula 
      form <- as.formula(paste('totalValue ~', paste(input$select_modelVars, collapse='+')))
      
      # get model
      lm <- train(form,
                  data = df,
                  method = 'lm'
      )
      
      # get new obs
      newobs <- data.frame(lapply(df[,2:117], mean))
      newobs$g <- input$numeric_g
      newobs$a <- input$numeric_a
      newobs$p <- input$numeric_g + input$numeric_a
      newobs$gp <- input$numeric_gp
      newobs$plusMinus <- input$numeric_plusminus
      newobs$pim <- input$numeric_pim
      
      # predict
      predNewobs(unname(predict(lm, newdata = newobs)))
    })
    
    # render predicton to frontend
    output$predNewobs <- renderText({
      predNewobs()
    })

})
