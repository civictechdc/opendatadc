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

electionHistoryTable = read_csv('election_history_R.csv')
electionHistoryTable %<>% 
  mutate(ward = as.factor(ward),smd = as.factor(smd),anc=as.factor(anc),year=as.integer(year)) %>% 
  select(year,ward,anc,smd,smd_anc_votes,winner_votes) %>%
  mutate(winnerPct = winner_votes / smd_anc_votes)

# Define UI for application that draws a histogram
ui <- navbarPage("Historical ANC Data Dashboard",
                 
   tabPanel("SMD Plots",
      sidebarLayout(
        sidebarPanel(
          
          uiOutput("smdPlot_select_ward"),
          uiOutput("smdPlot_select_anc"),
          uiOutput("smdPlot_select_smd")
        ),
        
        # Show a plot of the generated distribution
        mainPanel(
          
          tabsetPanel(type = "tabs",
                      tabPanel("Total Votes", plotOutput("smdPlot_totalPlot")),
                      tabPanel("Winner Votes", plotOutput("smdPlot_winnerPlot")),
                      tabPanel("Percent Votes", plotOutput("smdPlot_pctPlot")),
                      tabPanel("Data Table", tableOutput("smdPlot_table")))
        )
      )
   ),
   tabPanel("District Histograms",
            sidebarLayout(
              sidebarPanel(
                checkboxGroupInput("dist_hist_years", "Select Years",
                                   c("2012" = "2012",
                                     "2014" = "2014",
                                     "2016" = "2016",
                                     "2018" = "2018"),selected=1)
              ),
              mainPanel(
                
                tabsetPanel(type = "tabs",
                            tabPanel("Total Votes",plotOutput("districtHistogramTotalVotes")),
                            tabPanel("Winner Votes",plotOutput("districtHistogramWinnerVotes")),
                            tabPanel("Winner Percent",plotOutput("districtHistogramWinnerPct")))
              )
            )),
   tabPanel("More To Come")
)

# Define server logic required to draw a histogram
server <- function(input, output,session) {
  
  smdPlotTable <- reactive({
    
    electionHistoryTable %>% 
      filter(ward==input$wardSelection) %>%
      filter(anc == input$ancSelection) %>%
      filter(smd %in% input$smdSelection)
    
  })
  
  distHistTable <- reactive({
    
    electionHistoryTable %>% filter(year %in% input$dist_hist_years) %>% mutate(year = as.factor(year))
  })
  
  output$smdPlot_select_ward <- renderUI({
    
    selectizeInput('wardSelection','Select Ward',choices=c("select" = "",levels(electionHistoryTable$ward)))
  })
  
  
  output$smdPlot_select_anc <- renderUI({
    
    choice_anc <- reactive({
      electionHistoryTable %>% filter(ward==input$wardSelection) %>% pull(anc) %>% unique() %>% as.character()
    })
    selectizeInput('ancSelection','Select ANC',choices=c("select" = "",choice_anc()))
  })
  
  output$smdPlot_select_smd <- renderUI({
    
    choice_smd <- reactive({
      
      electionHistoryTable %>% filter(ward==input$wardSelection) %>% filter(anc == input$ancSelection) %>% pull(smd) %>% unique() %>% as.character()
    })
    checkboxGroupInput("smdSelection",'Select SMD',choices = choice_smd(),selected = 1)
  })


  output$smdPlot_table <- renderTable({ 
    
    smdPlotTable()
    
  })  
  
   output$smdPlot_totalPlot <- renderPlot({

     smdPlotTable() %>% ggplot(aes(x=year,y=smd_anc_votes,color=smd)) + geom_line() +
       geom_point() + xlab("Year") + ylab("Total Votes in SMD") +
       ggtitle("Total Votes in SMD(s) vs. Time")
   })

   output$smdPlot_winnerPlot <- renderPlot({

     smdPlotTable() %>% ggplot(aes(x=year,y=winner_votes,color=smd)) + geom_line() +
       geom_point() + xlab("Year") + ylab("Winning Votes in SMD") +
       ggtitle("Winner Votes in SMD(s) vs. Time")
   })

   output$smdPlot_pctPlot <- renderPlot({

     smdPlotTable() %>% ggplot(aes(x=year,y=winnerPct,color=smd)) + geom_line() +
       geom_point() + xlab("Year") + ylab("Total Votes in SMD") +
       ggtitle("Winner Percentage in SMD(s) vs. Time")
   })
   
   output$districtHistogramTotalVotes <- renderPlot({
     
     distHistTable() %>% ggplot(aes(x=smd_anc_votes, color=year,fill=year)) +
       geom_histogram(binwidth=100,alpha=0.5, position="identity") + xlim(c(0,2500)) + ylim(c(0,65))
   })
   
   output$districtHistogramWinnerVotes <- renderPlot({
     
     distHistTable() %>% ggplot(aes(x=winner_votes, color=year,fill=year)) +
       geom_histogram(binwidth=100,alpha=0.5, position="identity") + xlim(c(0,2500)) + ylim(c(0,65))
   })
   
   output$districtHistogramWinnerPct <- renderPlot({
     
     distHistTable() %>% ggplot(aes(x=winnerPct, color=year,fill=year)) +
        geom_histogram(binwidth=0.05,alpha=0.5, position="identity") + xlim(c(0,1)) + ylim(c(0,150))
   })
   
   
   
   
}

# Run the application 
shinyApp(ui = ui, server = server)

