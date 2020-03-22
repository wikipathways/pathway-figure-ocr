library(shiny)
library(shinyjs)
library(filesstrings)  
library(tidyr)
library(dplyr)
library(magrittr)

library(ggplot2)

## READ DF
df.figures <- readRDS("pfocr_figures.rds")
df.genes <- readRDS("pfocr_genes.rds")
# df.journals <- readRDS("pfocr_journals.rds")
df.jensen <- readRDS("pfocr_jensen.rds")
df.jensen[] <- lapply(df.jensen, as.character)

# df.active <<- df.figures
# df.active.genes <<- df.genes %>% filter(figid %in% df.active$figid)

ui <- fixedPage(
  titlePanel("PFOCR Display"),
  
  sidebarLayout(
    sidebarPanel(
        useShinyjs(), 
        h3("Summary"),
        textOutput("sum.figs"),
        textOutput("sum.papers"),
        textOutput("sum.genes"),
        textOutput("sum.genes.unique"),
        hr(),
        h3("Filters"),
        selectizeInput('annots', 'Disease Annotations', 
                       choices = sort(unique(df.jensen$jensenknow7)), 
                       multiple = TRUE #, options = list(maxItems = 1)
        ),
        selectizeInput('genes', 'Gene content', 
                       choices = unique(df.genes$hgnc_symbol), 
                       multiple = TRUE
        ),
        selectizeInput('years', 'Publication Years', 
                       choices = sort(unique(df.figures$year), decreasing = T), 
                       multiple = TRUE
        ),
        # hr(),
        # h5("DEBUG"),
        # textOutput("debug.annots"),
        # textOutput("debug.genes"),
        # textOutput("debug.years"),
        # Buttons
        # sliderInput("pscore", "pathway score", 0, 1, 0.5, 0.01)
        #actionButton("reload", label = "Reload")
        
      width = 3
    ),
    mainPanel(
      # plotOutput("plot1", click = "plot1_click"),
      plotOutput("top.annots", height = "400px"),
      plotOutput("top.genes", height = "200px"),
      plotOutput("years", height = "200px"),
      width = 9
    )
  )
)



server <- function(input, output) {
  
  ## DEBUG
  output$debug.annots <- renderPrint({
    str(input$annots)
  })
  output$debug.genes <- renderPrint({
    str(input$genes)
  })
  output$debug.years <- renderPrint({
    str(input$years)
  })
  
  ## REACTIVE
  df.reactive.years <- reactive({
    df.figures %>%
      filter(!is.na(year))  %>%
      {if (!is.null(input$annots)) filter(., figid %in% as.list(df.jensen %>% 
                                                                  filter(jensenknow7 %in% input$annots) %>% 
                                                                  distinct(figid))[[1]]) else filter(., TRUE) } %>%
      {if (!is.null(input$genes)) filter(., figid %in% as.list(df.genes %>% 
                                                                 filter(hgnc_symbol %in% input$genes) %>% 
                                                                 distinct(figid))[[1]]) else filter(., TRUE) }
  })
  
  df.reactive.genes <- reactive({
    df.genes %>%
      {if (!is.null(input$genes)) filter(., figid %in% as.list(df.genes %>% 
                                                                 filter(hgnc_symbol %in% input$genes) %>% 
                                                                 distinct(figid))[[1]]) else filter(., TRUE) } %>%
      {if (!is.null(input$annots)) filter(., figid %in% as.list(df.jensen %>% 
                                                                  filter(jensenknow7 %in% input$annots) %>% 
                                                                  distinct(figid))[[1]]) else filter(., TRUE) } %>%
      {if (!is.null(input$years)) filter(., figid %in% as.list(df.figures %>% 
                                                                 filter(year %in% input$years) %>% 
                                                                 distinct(figid))[[1]]) else filter(., TRUE) } 
    
  })
  
  df.reactive.annots <- reactive({
    df.jensen %>%
      {if (!is.null(input$annots)) filter(., figid %in% as.list(df.jensen %>% 
                                                                  filter(jensenknow7 %in% input$annots) %>% 
                                                                  distinct(figid))[[1]]) else filter(., !is.na(jensenknow7)) } %>%
      {if (!is.null(input$genes)) filter(., figid %in% as.list(df.genes %>% 
                                                                 filter(hgnc_symbol %in% input$genes) %>% 
                                                                 distinct(figid))[[1]]) else filter(., TRUE) } %>%
      {if (!is.null(input$years)) filter(., figid %in% as.list(df.figures %>% 
                                                                 filter(year %in% input$years) %>% 
                                                                 distinct(figid))[[1]]) else filter(., TRUE) } 
    
  })
  
  df.reactive.table <- reactive({
    df.figures %>%
      {if (!is.null(input$years)) filter(., year %in% input$years) else filter(., TRUE) } %>%
      {if (!is.null(input$annots)) filter(., figid %in% as.list(df.jensen %>% 
                                                                  filter(jensenknow7 %in% input$annots) %>% 
                                                                  distinct(figid))[[1]]) else filter(., TRUE) } %>%
      {if (!is.null(input$genes)) filter(., figid %in% as.list(df.genes %>% 
                                                                 filter(hgnc_symbol %in% input$genes) %>% 
                                                                 distinct(figid))[[1]]) else filter(., TRUE) }
  })
  
  # df.reactive <- reactive({
  #   df.jensen %>%
  #     filter(if(!is.null(input$annots)) jensenknow7 %in% input$annots else TRUE) %>%
  #     inner_join(df.genes, by=c("figid" = "figid"))
  #   df.figures %>%
  #     filter(if(!is.null(input$years)) year %in% input$years else TRUE) 
  # })
  # df.reactive.genes <- reactive({
  #   df.genes %>% 
  #     filter(figid %in% df.reactive()$figid)
  # })

  # observeEvent(input$years, {
  #   rv$selYear <- input$year
  # })
  
  # observeEvent(eventExpr = input$plot1_click, {
  #   rv$selYear <- df.sample$year[round(input$plot1_click$x)]
  #   rv$selCount <- df.sample$fig_cnt[which(df.sample$year == rv$selYear)]
  #  # rv$toHighlight <- df.sample$year %in% rv$selYear
  # })
  
  # observeEvent(input$pscore, {
    # df.sample <<- df.shiny %>%
    #   filter(!is.na(year)) %>%
    #   filter(pathway_score > input$pscore) %>%
    #   group_by(year) %>%
    #   summarize(fig_cnt = n())
    # 
    # rv$selCount <- df.sample$fig_cnt[which(df.sample$year == rv$selYear)]
    
  #   output$plot1 <- renderPlot({
  #     ggplot(df.sample, aes(x=year, y=fig_cnt, 
  #                           fill = ifelse(df.sample$year %in% rv$selYear, 
  #                                         yes = "yes", 
  #                                         no = "no")))+
  #       geom_bar(stat="identity") +
  #       scale_fill_manual(values = c("yes" = "blue", "no" = "grey" ), guide = FALSE )
  #   })
  # })
  
  ## SUMMARY
  output$sum.figs <- renderText({paste("Figures:", as.character(length(unique(df.reactive.table()$figid))), sep=" ")})
  output$sum.papers <- renderText({paste("Papers:", as.character(length(unique(df.reactive.table()$pmcid))), sep=" ")})
  output$sum.genes <- renderText({paste("Total genes:", as.character(length(df.reactive.genes()$entrez)), sep=" ")})
  output$sum.genes.unique <- renderText({paste("Unique genes:", as.character(length(unique(df.reactive.genes()$entrez))), sep=" ")})
  
  ## PLOT: DISEASE ANNOT
  output$top.annots <- renderPlot({
    df.reactive.annot.plot <- df.reactive.annots() %>%
      group_by(jensenknow7) %>%
      summarize(annot_cnt = n()) %>%
      arrange(desc(annot_cnt), jensenknow7) 
    
    df.reactive.annot.plot$jensenknow7 <- factor(df.reactive.annot.plot$jensenknow7, 
                                           levels = df.reactive.annot.plot$jensenknow7)
    
    df.reactive.annot.plot %>%
      top_n(40) %>%
      ggplot(aes(x=jensenknow7, y=annot_cnt)) +
      geom_bar(fill = "#CC6699",stat="identity") +
      theme(axis.text.x = element_text(angle = 45, hjust = 1)) 
  })
  
  ## PLOT: GENE
  output$top.genes <- renderPlot({
    df.reactive.gene.plot <- df.reactive.genes() %>%
      group_by(figid,symbol) %>%
      summarize(fig_sym_cnt = n()) %>%
      group_by(symbol) %>%
      summarize(gene_cnt = n()) %>%
      arrange(desc(gene_cnt), symbol) 
    
    df.reactive.gene.plot$symbol <- factor(df.reactive.gene.plot$symbol, 
                                           levels = df.reactive.gene.plot$symbol)
    
    df.reactive.gene.plot %>%
      top_n(40) %>%
      ggplot(aes(x=symbol, y=gene_cnt)) +
      geom_bar(fill = "#66CC99",stat="identity") +
      theme(axis.text.x = element_text(angle = 45, hjust = 1)) 
  })
  
  ## PLOT: TIMELINE
  output$years <- renderPlot({
    df.reactive.year.plot <- df.reactive.years() %>%
      group_by(year) %>%
      summarize(fig_cnt = n())
    
    df.reactive.year.plot %>%
      ggplot(aes(x=year, y=fig_cnt, 
                 fill = case_when(
                   year %in% input$years ~ "yes",
                   is.null(input$years) ~ "yes",
                   TRUE ~ "no"
                 ))) +
      geom_bar(stat="identity") +
      scale_fill_manual(values = c("yes" = "blue", "no" = "grey" ), guide = FALSE ) + 
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
  })
  
  
}
shinyApp(ui, server)