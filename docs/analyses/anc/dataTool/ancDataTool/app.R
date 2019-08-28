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
  mutate(ward = as.factor(ward),smd = as.factor(smd),anc=as.factor(anc)) %>% 
  select(year,ward,anc,smd,smd_anc_votes,winner_votes) %>%
  mutate(winnerPct = winner_votes / smd_anc_votes)

# Define UI for application that draws a histogram
ui <- navbarPage("Historical ANC Data Dashboard",
                 
   tabPanel("SMD Plots",
      sidebarLayout(
        sidebarPanel(
          
          uiOutput("select_ward"),
          uiOutput("select_anc"),
          uiOutput("select_smd")
        ),
        
        # Show a plot of the generated distribution
        mainPanel(
          
          tabsetPanel(type = "tabs",
                      tabPanel("Total Votes", plotOutput("totalPlot")),
                      tabPanel("Winner Votes", plotOutput("winnerPlot")),
                      tabPanel("Percent Votes", plotOutput("pctPlot")),
                      tabPanel("Data Table", tableOutput("table")))
        )
      )
   ),
   tabPanel("More To Come")
)

# Define server logic required to draw a histogram
server <- function(input, output,session) {
  
  reducedTable <- reactive({
    
    electionHistoryTable %>% 
      filter(ward==input$wardSelection) %>%
      filter(anc == input$ancSelection) %>%
      filter(smd %in% input$smdSelection)
    
  })
  
  output$select_ward <- renderUI({
    
    selectizeInput('wardSelection','Select Ward',choices=c("select" = "",levels(electionHistoryTable$ward)))
  })
  
  
  output$select_anc <- renderUI({
    
    choice_anc <- reactive({
      electionHistoryTable %>% filter(ward==input$wardSelection) %>% pull(anc) %>% unique() %>% as.character()
    })
    selectizeInput('ancSelection','Select ANC',choices=c("select" = "",choice_anc()))
  })
  
  output$select_smd <- renderUI({
    
    choice_smd <- reactive({
      
      electionHistoryTable %>% filter(ward==input$wardSelection) %>% filter(anc == input$ancSelection) %>% pull(smd) %>% unique() %>% as.character()
    })
    checkboxGroupInput("smdSelection",'Select SMD',choices = choice_smd(),selected = 1)
  })


  output$table <- renderTable({ 
    
    reducedTable()
    
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

