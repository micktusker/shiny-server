fluidPage(
  titlePanel("Mimicking a Google Form with a Shiny app"),
  div(
    id = "form",
    textInput("name", "Name", ""),
    textInput("favourite_pkg", "Favourite R package"),
    checkboxInput("used_shiny", "I've built a Shiny app in R before", FALSE),
    sliderInput("r_num_years", "Number of years using R", 0, 25, 2, ticks = FALSE),
    selectInput("os_type", "Operating system used most frequently",
                c("",  "Windows", "Mac", "Linux")),
    actionButton("submit", "Submit", class = "btn-primary")
  )
)
