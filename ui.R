shinyUI(fluidPage(
  
  titlePanel("Massachusetts: Average wait times at various RMV locations"),
  
  sidebarLayout(
    
    sidebarPanel(
      # LEARNING #
#       h1("Sidebar header", align="center"), # header function
#       p("Here's a short", span("description", style = "color: blue"), "of the app."),
#       helpText("Test in style difference."),
#       br(),
#       image(src = 'logo.png', height=72, width=72), # image must be in www folder in app folder
#       code("this is a note"),

#       uiOutput("weeks"),
      
      uiOutput("cities"),
      width = 2
      ), # do NOT include a comma in the last element of an array/panel
      # list of widgets: http://shiny.rstudio.com/gallery/widget-gallery.html

    mainPanel(
      plotOutput(outputId = "main", height = 700)
      )
    # output types: htmlOutput, imageOutput, plotOutput, tableOutput, textOutput)
  )
))

# different layout types can be viewed at: http://shiny.rstudio.com/articles/layout-guide.html

# Convert dates to M-F + times
# Factor by M-F (n weeks prior), then average values over M-F -> plot