library(shiny)
library(plyr)
library(ggplot2)
library(reshape2)
library(scales)
library(grid)

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
    radioButtons("cities", 
                       label = h3("Select your city:"),
                       choices = as.list(cities),
                       selected = "Boston")
  })
  
  ### RENDER ### (stored in output variable)
    
  output$main <- renderPlot({ # also renderText (w/ paste()), renderTable, etc.
    x_output <- x_plot[x_plot$city == input$cities, ]
    x_output$time <- strftime(x_output$timestamp, format="%H:%M")
    brks <- c("09:02", "10:00", "11:00", "12:00", "13:00", "14:00", "15:00", "16:00", "17:00", "17:58")
    brks_labels <- c("9:00 am", "10:00 am", "11:00 am", "12:00 pm", "1:00 pm", "2:00 pm", "3:00 pm", "4:00 pm", "5:00 pm", "6:00pm")
    
    p <- ggplot(x_output, aes(x=factor(time), y=avg_wait_time, group=city)) + geom_line(size=.8, color="blue") + theme(axis.text.x = element_text(angle = 90, hjust=1, vjust=.3), legend.position = "bottom", panel.margin = unit(1, "line")) + labs(x=NULL, y="Waiting time (minutes)") + facet_wrap( ~ weekday, ncol=5) + scale_x_discrete(breaks = brks, labels=brks_labels) + scale_y_continuous(breaks = c(seq(0, 400, by=25)), labels = c(seq(0,400,by=25)))
    print(p)
  
    })
  
})

# runApp(<folder_name>, display.mode = "showcase")