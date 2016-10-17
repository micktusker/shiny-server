shinyUI(
  fluidPage(
    titlePanel("Test Connection"),
    
    sidebarLayout(
      sidebarPanel(
        textInput("drv", "Database Driver", value="postgresql"),
        textInput("user", "User ID"),
        textInput("server", "Server", value="localhost"),
        textInput("db_name", "Database Name", value="cd38"),
        textInput("port", "Port"),
        passwordInput("passwd", "Password"),
        actionButton("connectDB", "Connect to DB")
      ),
      
      mainPanel(
        textOutput("test")
      )
    )
  )
)
