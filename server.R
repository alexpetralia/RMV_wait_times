library(shiny)
library(plyr)
library(ggplot2)
library(reshape2)
library(scales)
library(plyr)

shinyServer(function(input, output, session) {
  
  autoInvalidate <- reactiveTimer(100000, session) # 86400000ms is 1 day
  
  data <- reactive({
    x <- read.csv("wait_times.csv", header=T, stringsAsFactors=FALSE, colClasses = c("character", rep("numeric", 30)))
    x <- rename(x, c("Fall.River" = "Fall River", "Martha.s.Vineyard" = "Martha's Vineyard", "New.Bedford" = "New Bedford", "North.Adams" = "North Adams", "South.Yarmouth" = "South Yarmouth"))
  
    x[x == 999] <- NA
    x <- x[x$timestamp != "URL request failed", ]
    
    autoInvalidate()
    print("REFRESHING CSV!")
  
    return(x)
  })
  
  cities <- reactive({
    cities <- colnames(data())[-1]
    return(cities)
  })
  
  data_long <- reactive({
    x_long <- melt(data(), id.var="timestamp")
    x_long <- rename(x_long, c("variable" = "city", "value" = "wait_time"))
    x_long$timestamp <- strptime(x_long$timestamp, "%d/%m/%Y %H:%M %p")
    
    x_long$weekday <- weekdays(x_long$timestamp)
    x_long$time <- as.character(x_long$timestamp, '%H:%M')
    
    #
#     t <- ddply(x_long, .(city, weekday, time), summarize, avg=mean(wait_time))
#     t <- x_output[, list(avg=mean(wait_time)), .(city, weekday, time)]
    #
    
    return(x_long)
  })
    
  weeks <- reactive({
    weeks <- as.double(difftime(data_long()$timestamp[1], data_long()$timestamp[length(data_long()$timestamp)], units = "weeks")) + 1    
    return(weeks)
  })
  
  data_long_subset <- reactive({
    data_long_subset <- data_long()[as.Date(data_long()$timestamp) <= Sys.Date() & as.Date(data_long()$timestamp) > ( Sys.Date()-input$weeks*7 ), ]
    return(data_long_subset)
  })
  
  # pass server-side code into initial UI page
  output$cities <- renderUI({
    checkboxGroupInput("cities", 
                       label = h3("Which cities to view?"),
                       as.list(cities()),
                       selected = "Boston")
  })
  
  output$weeks <- renderUI({
    sliderInput("weeks", 
                label = h3("How many prior weeks to average?"),
                min = 1,
                max = weeks(),
                step = 1,
                value = 1)
  })
    
  # render is stored in "output" variable
  output$main <- renderPlot({ # there is also renderText (w/ paste()), renderTable, etc.
        
    x_output <- data_long_subset()[data_long_subset()$city == input$cities, ]
    brks <- seq(1, length(x_output$timestamp), by = 30)
    brks_labels <- x_output[brks, ]
    
    p <- ggplot(x_output, aes(x=timestamp, y=wait_time, group=city)) + geom_line(aes(color=city), size=1.5) + theme(axis.text.x = element_text(angle = 90, hjust=1), legend.position = "bottom") + labs(x=NULL, y="Waiting time (minutes)") #+ scale_x_continuous(breaks = pretty_breaks(n=30))
    print(p)    
    
    # facet by day of week?
    # TO FIX: X-AXIS TICKS
  })
  
})

# runApp(<folder_name>, display.mode = "showcase")