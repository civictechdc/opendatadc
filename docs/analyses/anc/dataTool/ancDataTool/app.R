#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(tibble)
library(readr)
library(magrittr)
library(dplyr)
library(ggplot2)

# Define UI for application that draws a histogram
ui <- fluidPage(
   
   # Application title
   titlePanel("Historical ANC Data Dashboard"),
   
   # Sidebar with a slider input for number of bins 
   sidebarLayout(
      sidebarPanel(
        
        # selectInput("dataSource",
        #             label="Select Variable",
        #             choices = c("Total Votes","Winner Votes","Winner Pct")),
        
        selectInput("ward",
                    label="Select a Ward",
                    choices = c("Ward 1",
                                "Ward 2",
                                "Ward 3",
                                "Ward 4",
                                "Ward 5",
                                "Ward 6",
                                "Ward 7",
                                "Ward 8")),
        
        selectInput("anc",
                    label="Select an ANC",
                    choices = c("A","B","C","D","E","F","G")),
        
        
        checkboxGroupInput("smd",h3("SMD"),
                            choices = list("1" = 1,
                                           "2" = 2,
                                           "3" = 3,
                                           "4" = 4,
                                           "5" = 5,
                                           "6" = 6,
                                           "7" = 7,
                                           "8" = 8,
                                           "9" = 9),
                           selected = 1)
        
        
         
      ),
      
      # Show a plot of the generated distribution
      mainPanel(
        plotOutput("totalPlot"),
        plotOutput("winnerPlot"),
        plotOutput("pctPlot")
      )
   )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
  
  electionHistoryTable = read_csv('election_history_R.csv')
  electionHistoryTable %<>% 
    mutate(ward = as.factor(ward),smd = as.factor(smd),anc=as.factor(anc)) %>% 
    select(year,ward,anc,smd,smd_anc_votes,winner_votes) %>%
    mutate(winnerPct = winner_votes / smd_anc_votes)
   
  wardInput <- reactive({
    switch(input$ward,
           "Ward 1" = 1,
           "Ward 2" = 2,
           "Ward 3" = 3,
           "Ward 4" = 4,
           "Ward 5" = 5,
           "Ward 6" = 6,
           "Ward 7" = 7,
           "Ward 8" = 8)
  })
    
  reducedTable <- reactive({
    
    electionHistoryTable %>% 
      filter(ward==wardInput(),anc==input$anc,smd %in% input$smd)
  })
  
  
   output$totalPlot <- renderPlot({
  
     reducedTable() %>% ggplot(aes(x=year,y=smd_anc_votes,color=smd)) + geom_line() + 
       geom_point() + xlab("Year") + ylab("Total Votes in SMD") + 
       ggtitle("Total Votes in SMD(s) vs. Time")
   })
   
   output$winnerPlot <- renderPlot({
     
     reducedTable() %>% ggplot(aes(x=year,y=winner_votes,color=smd)) + geom_line() + 
       geom_point() + xlab("Year") + ylab("Winning Votes in SMD") + 
       ggtitle("Winner Votes in SMD(s) vs. Time")  
   })
   
   output$pctPlot <- renderPlot({
     
     reducedTable() %>% ggplot(aes(x=year,y=winnerPct,color=smd)) + geom_line() + 
       geom_point() + xlab("Year") + ylab("Total Votes in SMD") + 
       ggtitle("Winner Percentage in SMD(s) vs. Time")  
   })
   
   
   
}

# Run the application 
shinyApp(ui = ui, server = server)

