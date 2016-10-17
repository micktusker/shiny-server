
library(shiny)
library(RPostgreSQL)

shinyServer(function(input, output){
  # Read in the dataset
  connectDB <- eventReactive(input$connectDB, {
    
    if(input$drv != "postgresql"){
      stop("Only 'postgresql' implemented currently")
    }else{
      drv <- dbDriver("PostgreSQL")
    }
    
    con <- dbConnect(drv, user = input$user, password = input$passwd, 
                     port = input$port, host = input$server, dbname=input$db_name)
    return(con)
  })
  
  output$test <- renderText({
    con <- connectDB()
    "connection success"
  })
})
