library(shiny)
library(shinyjs)
library(filesstrings)  
library(tidyr)
library(dplyr)
library(magrittr)

library(ggplot2)

## READ DF
df.shiny <- readRDS("pfocr_sample.rds")

df.sample <<- df.shiny %>%
  filter(!is.na(year)) %>%
  filter(pathway_score > 0.5) %>%
  group_by(year) %>%
  summarize(fig_cnt = n())


ui <- fluidPage(
  titlePanel("PFOCR Display"),
  
  sidebarLayout(
    sidebarPanel(
      fluidPage(
        useShinyjs(), 
        # Figure information
        h5("Selected bar"),
        # textOutput("fig.name"),
        # uiOutput("url"),
        textOutput("year"),
        textOutput("count"),
        # textOutput("fig.num"),
        # textOutput("fig.title"),
        # textOutput("fig.caption"),

        hr(),
        
        # Buttons
        sliderInput("pscore", "pathway score", 0, 1, 0.5, 0.01)
        #actionButton("reload", label = "Reload")
      ),
      width = 3
    ),
    mainPanel(
      plotOutput("plot1", click = "plot1_click"),
      width = 9
    )
  )
)



server <- function(input, output) {
  rv <- reactiveValues(toHighlight = rep(FALSE, nrow(df.sample)), 
                       selYear = NULL, selCount = NULL)
  
  observeEvent(eventExpr = input$plot1_click, {
    rv$selYear <- df.sample$year[round(input$plot1_click$x)]
    rv$selCount <- df.sample$fig_cnt[which(df.sample$year == rv$selYear)]
   # rv$toHighlight <- df.sample$year %in% rv$selYear
  })
  
  observeEvent(input$pscore, {
    df.sample <<- df.shiny %>%
      filter(!is.na(year)) %>%
      filter(pathway_score > input$pscore) %>%
      group_by(year) %>%
      summarize(fig_cnt = n())
    
    rv$selCount <- df.sample$fig_cnt[which(df.sample$year == rv$selYear)]
    
    output$plot1 <- renderPlot({
      ggplot(df.sample, aes(x=year, y=fig_cnt, 
                            fill = ifelse(df.sample$year %in% rv$selYear, 
                                          yes = "yes", 
                                          no = "no")))+
        geom_bar(stat="identity") +
        scale_fill_manual(values = c("yes" = "blue", "no" = "grey" ), guide = FALSE )
    })
  })
  
  output$year <- renderText({paste("Year:", as.character(rv$selYear), sep=" ")})
  output$count <- renderText({paste("Count:", as.character(rv$selCount), sep=" ")})
  
}
shinyApp(ui, server)