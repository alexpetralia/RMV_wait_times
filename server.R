library(shiny)
library(plyr)
library(ggplot2)
library(reshape2)
library(scales)

x <- read.csv("wait_times.csv", header=T, stringsAsFactors=FALSE, colClasses = c("character", rep("numeric", 30)))
x <- rename(x, c("Fall.River" = "Fall River", "Martha.s.Vineyard" = "Martha's Vineyard", "New.Bedford" = "New Bedford", "North.Adams" = "North Adams", "South.Yarmouth" = "South Yarmouth"))
cities <- colnames(x)[-1]

x[x == 999] <- NA
x <- x[x$timestamp != "URL request failed", ]

x <- melt(x, id.var="timestamp")
x <- rename(x, c("variable" = "city", "value" = "wait_time"))
x$timestamp <- as.POSIXct(strptime(x$timestamp, "%d/%m/%Y %I:%M %p"))
x <- na.omit(x)

x$weekday <- weekdays(x$timestamp)
x$weekday <- factor(x$weekday, levels=c("Monday", "Tuesday", "Wednesday", "Thursday", "Friday"))

x$time <- as.character(x$timestamp, '%I:%M %p')

# 3-way groupby: find average wait time for each weekday during the week
x_plot <- ddply(x, .(city, weekday, time), summarize, avg_wait_time=mean(wait_time))
# t <- x_output[, list(avg=mean(wait_time)), .(city, weekday, time)]

# convert into an "average" week in POSIXct form - could have used dict. here
x_plot$day_number <- x_plot$weekday
x_plot$day_number <- as.numeric(x_plot$day_number)
x_plot$day_number[x_plot$day_number == "Monday"] <- 1
x_plot$day_number[x_plot$day_number == "Tuesday"] <- 2
x_plot$day_number[x_plot$day_number == "Wednesday"] <- 3
x_plot$day_number[x_plot$day_number == "Thursday"] <- 4
x_plot$day_number[x_plot$day_number == "Friday"] <- 5
x_plot$day_number <- x_plot$day_number + as.Date('2001/01/02')
x_plot$timestamp <- as.POSIXct(paste(x_plot$day_number, x_plot$time), format="%Y-%m-%d %I:%M %p")
x_plot$day_number <- NULL
x_plot <- x_plot[order(x_plot$timestamp), ]


shinyServer(function(input, output, session) {  
  # pass server-side code into initial UI page
  output$cities <- renderUI({
    checkboxGroupInput("cities", 
                       label = h3("Select your cities:"),
                       as.list(cities),
                       selected = "Boston")
  })
  
  ### RENDER ### (stored in output variable)
    
  output$main <- renderPlot({ # also renderText (w/ paste()), renderTable, etc.
        
    x_output <- x_plot[x_plot$city == input$cities, ]
    
    p <- ggplot(x_output, aes(x=timestamp, y=avg_wait_time, group=city)) + geom_line(aes(color=city), size=1.5) + theme(axis.text.x = element_text(angle = 90, hjust=1), legend.position = "bottom") + labs(x=NULL, y="Waiting time (minutes)") + facet_wrap( ~ weekday, ncol=5) + scale_x_datetime(breaks = date_breaks("1 hour")) #limits = c(as.POSIXct("9:00"), as.POSIXct("18:00"))
    print(p)
    
    ##### TO FIX: X-AXIS RANGE BIZ. HOURS ONLY (9am-6pm), FORMAT SHOW ONLY HOURS #####
  })
  
})

# runApp(<folder_name>, display.mode = "showcase")