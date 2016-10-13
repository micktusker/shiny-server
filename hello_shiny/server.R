library(shiny)
function(input, output) {
  output$result <- renderText({ 
    number1 <- input$number1
    number2 <- input$number2
    paste0("The product of the two numbers is: ", number1 * number2)
  })
}
