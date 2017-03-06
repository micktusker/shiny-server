shinyServer(function(input, output, session) {
  name <- reactive({
    input$name
  })
  favourite_pkg <- reactive(
    input$favourite_pkg
  )
  used_shiny <- reactive({
    input$used_shiny
  })
  r_num_years <- reactive({
    input$r_num_years
  })
  os_type <- reactive({
    input$os_type
  })
  observeEvent(input$submit, {
    insert.row(name(), favourite_pkg(), used_shiny(), r_num_years(), os_type())
    updateTextInput(session, "name", value = "")
    updateTextInput(session, "favourite_pkg", value = "")
    updateTextInput(session, "used_shiny", value = FALSE)
    updateNumericInput(session, "r_num_years", value = 2)
    updateSelectInput(session, "os_type", selected = "")
  })
})
