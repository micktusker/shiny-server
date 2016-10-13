library(shiny)
ui <- fluidPage(
  titlePanel("A Crappy App"),
  sidebarLayout(
    sidebarPanel(
      numericInput("number1", "First number:", value = 0),
      numericInput("number2", "Second number:", value = 0)
    ),
    mainPanel(
      textOutput("result")
    )
  )
)
# https://bookdown.org/weicheng/shinyTutorial/server.html
#print(ui)