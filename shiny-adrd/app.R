## ADRD Pathway Filter/Search/View

# Deploy on rshinyapps.io
# library(rsconnect)
# deployApp() #setwd

library(DT)
library(shiny)
library(shinyjs)
library(filesstrings)  
library(tidyr)
library(dplyr)
library(magrittr)

library(ggplot2)

## READ DF
df.table <- NULL
df.years <- NULL
df.genes <- NULL
df.annots <- NULL

readPfocrData <- function(session,df.table,df.years,df.genes,df.annots ){
  withProgress(message = 'Loading data...', detail = "",
               style = getShinyOption("progress.style", default = "notification"),
               value = NULL, {
                 df.table <<- readRDS("pfocr_adrd_table.rds")
                 df.years <<- readRDS("pfocr_adrd_years.rds")
                 df.genes <<- readRDS("pfocr_adrd_genes.rds")
                 df.annots <<- readRDS("pfocr_adrd_annots.rds")
               })
}


# df.active <<- df.table
# df.active.genes <<- df.genes %>% filter(figid %in% df.active$figid)

ui <- fixedPage(
  titlePanel("AD/ADRD Pathway Figures"),
  sidebarLayout(
    sidebarPanel(
        useShinyjs(), 
        h4("Introduction"),
        HTML('The <a href="https://www.wikipathways.org/index.php/WikiPathways:Team#Team_Members" target="_blank">WikiPathways team</a>
          at <a href="https://gladstone.org/people/alex-pico" target="_blank">Gladstone Institutes</a> is searching the literature 
          for pathway figures related to Alzheimer\'s and Related Diseases. This interactive tool lets you
          filter, search and view their findings.'),
        h4("Summary stats"),
        textOutput("sum.figs"),
        textOutput("sum.papers"),
        textOutput("sum.genes"),
        textOutput("sum.genes.unique"),
        hr(),
        h3("1. Filter Figures"),
        selectizeInput('annots', 'Disease Annotations', 
                       choices = sort(unique(df.annots$jensenknow7)), 
                       multiple = TRUE #, options = list(maxItems = 1)
        ),
        selectizeInput('genes', 'Gene content', 
                       choices = sort(unique(df.genes$hgnc_symbol)), 
                       multiple = TRUE
        ),
        selectizeInput('years', 'Publication Years', 
                       choices = sort(unique(df.years$year), decreasing = T), 
                       multiple = TRUE
        ),
        # hr(),
        # h5("DEBUG"),
        # textOutput("debug.annots"),
        # textOutput("debug.genes"),
        # textOutput("debug.years"),
        # textOutput("row.sel"),
        # Buttons
        # sliderInput("pscore", "pathway score", 0, 1, 0.5, 0.01)
        #actionButton("reload", label = "Reload")
        
      width = 3
    ),
    mainPanel(
      # plotOutput("plot1", click = "plot1_click"),
      plotOutput("top.annots", height = "300px"),
      plotOutput("top.genes", height = "210px"),
      plotOutput("years", height = "180px"),
      width = 9
    )
  ),
  hr(),
  h3("2. Search Filtered Figures"),
  DT::dataTableOutput('table'),
  hr(),
  h3("3. View Selected Figure"),
  fixedRow(
    column(7,
           htmlOutput("figlink"),
           htmlOutput("figure"),
    ),
    column(5, 
           h4("Genes automatically extracted from selected figure"),
           DT::dataTableOutput('figtable'),
    )
  )
)


server <- function(input, output, session) {
  
  ## FUNCTION TO TOGGLE FILTER INPUTS
  #TODO: integrate this into reactive logic
  enableFilters<-function(enable=TRUE){
    if(enable){
      shinyjs::enable('annots')
      shinyjs::enable('genes')
      shinyjs::enable('years')
    }else {
      shinyjs::disable('annots')
      shinyjs::disable('genes')
      shinyjs::disable('years')
    }
  }
  
  # READ IN DATA FILES WITH PROGRESS NOTE
  if(is.null(df.genes)){
    readPfocrData(session,df.table,df.years,df.genes,df.annots )
  }
  
  # ## DEBUG
  # output$debug.annots <- renderPrint({
  #   str(input$annots)
  # })
  # output$debug.genes <- renderPrint({
  #   str(input$genes)
  # })
  # output$debug.years <- renderPrint({
  #   str(input$years)
  # })
  
  
  ## SUMMARY
  output$sum.figs <- renderText({paste("Figures:", as.character(formatC(length(unique(df.reactive.table()$figid)), format="d", big.mark=',')), sep=" ")})
  output$sum.papers <- renderText({paste("Papers:", as.character(formatC(length(unique(df.reactive.table()$pmcid)), format="d", big.mark=',')), sep=" ")})
  output$sum.genes <- renderText({paste("Total genes:", as.character(formatC(length(df.reactive.genes()$entrez), format="d", big.mark=',')), sep=" ")})
  output$sum.genes.unique <- renderText({paste("Unique genes:", as.character(formatC(length(unique(df.reactive.genes()$entrez)), format="d", big.mark=',')), sep=" ")})
  
  
  ## REACTIVE FILTER SELECTION
  df.reactive.years <- reactive({
    withProgress(message = 'Filtering', detail = "by year",
                 style = getShinyOption("progress.style", default = "notification"),
                 value = NULL, {
    df.years %>%
      {if (!is.null(input$annots)) filter(., figid %in% as.list(df.annots %>% 
                                                                  filter(jensenknow7 %in% input$annots) %>% 
                                                                  distinct(figid))[[1]]) else filter(., TRUE) } %>%
      {if (!is.null(input$genes)) filter(., figid %in% as.list(df.genes %>%  ## AND logic
                                                                 dplyr::filter(hgnc_symbol %in% input$genes) %>%
                                                                 dplyr::select(c(figid, hgnc_symbol))%>%
                                                                 dplyr::mutate(value=TRUE) %>%
                                                                 dplyr::distinct(figid,hgnc_symbol, value) %>%
                                                                 tidyr::spread(hgnc_symbol, value, convert=T, fill=F) %>%
                                                                 dplyr::filter_if(is.logical, all_vars(.==TRUE)) %>%
                                                                 dplyr::select(figid))[[1]]) else filter(., TRUE) }
  })
  })
  
  df.reactive.genes <- reactive({
    withProgress(message = 'Filtering', detail = "by gene",
                 style = getShinyOption("progress.style", default = "notification"),
                 value = NULL, {
    df.genes %>%
      {if (!is.null(input$genes)) filter(., figid %in% as.list(df.genes %>%  ## AND logic
                                                                 dplyr::filter(hgnc_symbol %in% input$genes) %>%
                                                                 dplyr::select(c(figid, hgnc_symbol))%>%
                                                                 dplyr::mutate(value=TRUE) %>%
                                                                 dplyr::distinct(figid,hgnc_symbol, value) %>%
                                                                 tidyr::spread(hgnc_symbol, value, convert=T, fill=F) %>%
                                                                 dplyr::filter_if(is.logical, all_vars(.==TRUE)) %>%
                                                                 dplyr::select(figid))[[1]]) else filter(., TRUE) } %>%
      {if (!is.null(input$annots)) filter(., figid %in% as.list(df.annots %>% 
                                                                  filter(jensenknow7 %in% input$annots) %>% 
                                                                  distinct(figid))[[1]]) else filter(., TRUE) } %>%
      {if (!is.null(input$years)) filter(., figid %in% as.list(df.years %>% 
                                                                 filter(year %in% input$years) %>% 
                                                                 distinct(figid))[[1]]) else filter(., TRUE) } 
    
  })
  })
  
  df.reactive.annots <- reactive({
    withProgress(message = 'Filtering', detail = "by disease",
                 style = getShinyOption("progress.style", default = "notification"),
                 value = NULL, {
    df.annots %>%
      {if (!is.null(input$annots)) filter(., figid %in% as.list(df.annots %>% 
                                                                  filter(jensenknow7 %in% input$annots) %>% 
                                                                  distinct(figid))[[1]]) else filter(., !is.na(jensenknow7)) } %>%
      {if (!is.null(input$genes)) filter(., figid %in% as.list(df.genes %>%  ## AND logic
                                                                 dplyr::filter(hgnc_symbol %in% input$genes) %>%
                                                                 dplyr::select(c(figid, hgnc_symbol))%>%
                                                                 dplyr::mutate(value=TRUE) %>%
                                                                 dplyr::distinct(figid,hgnc_symbol, value) %>%
                                                                 tidyr::spread(hgnc_symbol, value, convert=T, fill=F) %>%
                                                                 dplyr::filter_if(is.logical, all_vars(.==TRUE)) %>%
                                                                 dplyr::select(figid))[[1]]) else filter(., TRUE) } %>%
      {if (!is.null(input$years)) filter(., figid %in% as.list(df.years %>% 
                                                                 filter(year %in% input$years) %>% 
                                                                 distinct(figid))[[1]]) else filter(., TRUE) } 
    
  })
  })
  
  df.reactive.table <- reactive({
    withProgress(message = 'Filtering', detail = "table",
                 style = getShinyOption("progress.style", default = "notification"),
                 value = NULL, {
    df.table %>%
      {if (!is.null(input$years)) filter(., year %in% input$years) else filter(., TRUE) } %>%
      {if (!is.null(input$annots)) filter(., figid %in% as.list(df.annots %>% 
                                                                  filter(jensenknow7 %in% input$annots) %>% 
                                                                  distinct(figid))[[1]]) else filter(., TRUE) } %>%
      {if (!is.null(input$genes)) filter(., figid %in% as.list(df.genes %>%  ## AND logic
                                                                 dplyr::filter(hgnc_symbol %in% input$genes) %>%
                                                                 dplyr::select(c(figid, hgnc_symbol))%>%
                                                                 dplyr::mutate(value=TRUE) %>%
                                                                 dplyr::distinct(figid,hgnc_symbol, value) %>%
                                                                 tidyr::spread(hgnc_symbol, value, convert=T, fill=F) %>%
                                                                 dplyr::filter_if(is.logical, all_vars(.==TRUE)) %>%
                                                                 dplyr::select(figid))[[1]]) else filter(., TRUE) }
  })
  })
  
  ## UPDATE FILTERS
  observe ({
    withProgress(message = 'Updating filter', detail = "options",
                 style = getShinyOption("progress.style", default = "notification"),
                 value = NULL, {
    updateSelectizeInput(session, 'annots',
                         choices = sort(unique(df.reactive.annots()$jensenknow7)),
                         selected = input$annots
    )
    updateSelectizeInput(session, 'genes',
                         choices = sort(unique(df.reactive.genes()$hgnc_symbol)),
                         selected = input$genes
    )
    updateSelectizeInput(session, 'years',
                         choices = sort(unique(df.reactive.years()$year), decreasing = T),
                         selected = input$years
    )
  })
  })
  
   ## PLOT: DISEASE ANNOT
  output$top.annots <- renderPlot({
    withProgress(message = 'Updating plot', detail = "by disease",
                 style = getShinyOption("progress.style", default = "notification"),
                 value = NULL, {
    df.reactive.annot.plot <- df.reactive.annots() %>%
      group_by(jensenknow7) %>%
      summarize(annot_cnt = n()) %>%
      arrange(desc(annot_cnt), jensenknow7) 
    
    df.reactive.annot.plot$jensenknow7 <- factor(df.reactive.annot.plot$jensenknow7, 
                                           levels = df.reactive.annot.plot$jensenknow7)
    
    df.reactive.annot.plot %>%
      filter(row_number() <=40) %>% #breaks ties, unlike top_n()
      ggplot(aes(x=jensenknow7, y=annot_cnt)) +
      geom_bar(fill = "#CC6699",stat="identity") +
      theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 10),
            axis.text.y = element_text(size = 12)) +
      ggtitle("Top Diseases Associated with Figures") +
      xlab("") + ylab("")
  })
  })
  
  ## PLOT: GENE
  output$top.genes <- renderPlot({
    withProgress(message = 'Updating plot', detail = "by gene",
                 style = getShinyOption("progress.style", default = "notification"),
                 value = NULL, {
    df.reactive.gene.plot <- df.reactive.genes() %>%
      group_by(figid,symbol) %>%
      summarize(fig_sym_cnt = n()) %>%
      group_by(symbol) %>%
      summarize(gene_cnt = n()) %>%
      arrange(desc(gene_cnt), symbol) 
    
    df.reactive.gene.plot$symbol <- factor(df.reactive.gene.plot$symbol, 
                                           levels = df.reactive.gene.plot$symbol)
    
    df.reactive.gene.plot %>%
      filter(row_number() <=40) %>%
      ggplot(aes(x=symbol, y=gene_cnt)) +
      geom_bar(fill = "#66CC99",stat="identity") +
      theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 12),
            axis.text.y = element_text(size = 12))  +
      ggtitle("Top Gene Symbols Used in Figures") +
      xlab("") + ylab("")
  })
  })
  
  ## PLOT: TIMELINE
  output$years <- renderPlot({
    withProgress(message = 'Updating plot', detail = "by year",
                 style = getShinyOption("progress.style", default = "notification"),
                 value = NULL, {
    df.reactive.year.plot <- df.reactive.years() %>%
      group_by(year) %>%
      summarize(fig_cnt = n())
    
    df.reactive.year.plot %>%
      ggplot(aes(x=factor(year, levels = 1995:2019), y=fig_cnt, 
                 fill = case_when(
                   year %in% input$years ~ "yes",
                   is.null(input$years) ~ "yes",
                   TRUE ~ "no"
                 ))) +
      geom_bar(stat="identity") +
      scale_fill_manual(values = c("yes" = "blue", "no" = "grey" ), guide = FALSE ) + 
      theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 14),
            axis.text.y = element_text(size = 12)) +
      ggtitle("Figures by Year") +
      xlab("") + ylab("")+
      scale_x_discrete(breaks = factor(1995:2019), drop=FALSE)
    
  })
  })
  
  ## TABLE OF FILTERED FIGURES
  output$table <- DT::renderDataTable(
    withProgress(message = 'Updating table...', detail = "",
                 style = getShinyOption("progress.style", default = "notification"),
                 value = NULL, {
    DT::datatable(df.reactive.table()[,c('pmcid','paper.title','authors','year','number','figure.title' )],
                  extensions = 'Buttons',
                  filter = 'top',
                  rownames= FALSE,
                  selection = list(mode = 'single', selected = c(2272)), #top row sorted by desc(year)
                  options = list(pageLength = 10,
                                 order = list(list(3, 'desc')),
                                 autoWidth = TRUE,
                                 scrollX=TRUE,
                                 search = list(regex = TRUE, caseInsensitive = TRUE),
                                 dom = 'Bfrtip',
                                 buttons = c('copy', 'csv', 'excel', 'pdf'),
                                 columnDefs = list(
                                   list(targets = "_all"
                                   ),
                                   list(targets=c(0), visible=TRUE, width='75'), #pmcid
                                   list(targets=c(1), visible=TRUE,              #papertitle
                                        render = JS(
                                          "function(data, type, row, meta) {",
                                          "return type === 'display' && data != null && data.length > 50 ?",
                                          "'<span title=\"' + data + '\">' + data.substr(0, 50) + '...</span>' : data;",
                                          "}")
                                   ),
                                   list(targets=c(2), visible=TRUE, width='120',  #authors
                                        render = JS(
                                          "function(data, type, row, meta) {",
                                          "return type === 'display' && data != null && data.length > 15 ?",
                                          "'<span title=\"' + data + '\">' + data.substr(0, 15) + '...</span>' : data;",
                                          "}")
                                   ),
                                   list(targets=c(3), visible=TRUE, width='35'), #year
                                   list(targets=c(4), visible=TRUE, width='50'), #number
                                   list(targets=c(5), visible=TRUE, width='250',  #figuretitle
                                        render = JS(
                                          "function(data, type, row, meta) {",
                                          "return type === 'display' && data != null && data.length > 35 ?",
                                          "'<span title=\"' + data + '\">' + data.substr(0, 35) + '...</span>' : data;",
                                          "}")
                                   )
                                 )
                  )
    )
    })
  )
           
  
  ## REACTIVE TABLE SELECTION
  observeEvent(input$table_rows_selected,{
    sel.figid <- df.reactive.table()$figid[c(input$table_rows_selected)]
    sel.figlink <- df.reactive.table()$figure.link[c(input$table_rows_selected)]
    figid.split <- strsplit(sel.figid, "__")[[1]]
    src <- paste0("https://www.ncbi.nlm.nih.gov/pmc/articles/",figid.split[1],"/bin/",figid.split[2])
    linkout <- paste0("https://www.ncbi.nlm.nih.gov/",sel.figlink)
    output$figlink <- renderText({c('Link to figure: <a href="',linkout,'" target="_blank">',linkout,'</a>')})
    output$figure<-renderText({c('<a href="',linkout,'" target="_blank"><img src="',src,'", width="600px"></a>')})
  
    ## TABLE OF SELECTED FIGURE
    output$figtable <- DT::renderDataTable(
      DT::datatable(df.genes[which(df.genes$figid == sel.figid),c('symbol','source','hgnc_symbol','entrez' )],
                    extensions = 'Buttons',
                    rownames= FALSE,
                    selection = 'none',
                    options = list(pageLength = 10,
                                   order = list(list(2, "asc")),
                                   autoWidth = TRUE,
                                   dom = 'Bfrtip',
                                   buttons = c('copy', 'csv', 'excel', 'pdf')
                    )
      )
    )
  })
  
}
shinyApp(ui, server)