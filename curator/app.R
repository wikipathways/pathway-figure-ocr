library(shiny)
# library(shinyjs)
library(filesstrings)  

# SHINY UI
ui <- fluidPage(
  titlePanel("PFOCR Curator"),
  
  sidebarLayout(
    sidebarPanel(
      fluidPage(
        # Figure directory
        ## TODO: user specifies dir path and presses 'Go'
        
        # Figure information
        h5("Figures remaing:"),
        p(textOutput("fig.count")),
        h5("Current figure file:"),
        p(textOutput("fig.title")),
        h5("Link to paper:"),
        p(uiOutput("url")),
        h5("Figure number:"),
        p(textInput("fig.num", NULL,"NA")),
        
        ## TODO: figure number extracted (allow override)
        ## TODO: link to paper
        ## TODO: figure caption retrieval (allow override)
        ## TODO: figure title field
        
        hr(),
        # Buttons
        actionButton("keep", label = "Save"),
        actionButton("trash", label = "Reject"),
        
        hr(),
        # Action taken
        fluidRow(column(12, textOutput("value")))
        
      )
    ),
    
    mainPanel(
      imageOutput("figure")
    )
  )
)

# SHINY SERVER
server <- function(input, output, session) {
  
  ## INITIALIZATION
  # TODO: get filepath from user
  image.dir <- "/git/wikipathways/pathway-figure-ocr/20181216/test_images"
  keep.dir <- "curated"
  trash.dir <- "rejected"
  dir.create(paste(image.dir,keep.dir,sep='/'), FALSE)
  dir.create(paste(image.dir,trash.dir,sep='/'), FALSE)
  
  ## FUNCTION: retrieve next figure
  nextFigure <- function(){
    f <- list()
    fig.list <- list.files(image.dir, pattern = "\\.jpg$")
    
    # Display remaining count and select next figure to process
    fig.cnt <- length(fig.list)
    output$fig.count <- renderText({fig.cnt})
    if (fig.cnt == 0){
      fig.list <- c("No more figures in this directory!")
      # shinyjs::disable("keep") ## not working...
      # shinyjs::disable("trash")
    }
    next.fig <- fig.list[1]
    output$fig.title <- renderText({next.fig})
    output$figure <- renderImage({
      list(src = paste(image.dir,next.fig, sep = '/'),
           alt = "No image available")
    }, deleteFile = FALSE)
    if (fig.cnt > 0){
      # Attempt extract figure number from filename
      f$fn <- gsub("PMC\\d+__.*[0]{0,3}([S]{0,1}[1-9]{0,1}[0-9][a-z]{0,1})[_HTML]{0,5}\\.jpg", "\\1", next.fig)
      updateTextInput(session, "fig.num", value=f$fn) 
      # Construct paper and figure url
      f.split <- unlist(strsplit(next.fig, "__"))
      f$pmc <- f.split[1]
      f$fig <- f.split[2]
      f$pmc.url <- paste0("https://www.ncbi.nlm.nih.gov/pmc/articles/",f$pmc)
      f$fig.url <- paste0("https://www.ncbi.nlm.nih.gov/pmc/articles/",f$pmc,"/bin/",f$fig)
      display.url <- a(f$pmc, href=f$pmc.url)
      output$url <- renderUI({display.url})
    }
    f$cf <- next.fig
    return(f)
  }
  fig <- nextFigure()
  
  ## DEFINE SHARED VARS
  rv <- reactiveValues(value='',cf=fig$cf, fn=fig$fn, pu=fig$pmc.url, fu=fig$fig.url)  
  
  ## BUTTON FUNCTIONALITY
  observeEvent(input$keep, {
    rv$value <- "kept"
    f.path.from<-paste(image.dir,rv$cf, sep = '/')
    f.path.to<-paste(image.dir,keep.dir, sep = '/')
    write.table(data.frame(rv$cf,input$fig.num, rv$pu, rv$fu, "fig title","fig caption"), 
              paste(f.path.to,"pfocr_curated.tsv",sep = '/'), 
              append = TRUE,
              sep = '\t',
              quote = FALSE,
              col.names = FALSE, 
              row.names = FALSE)
    filesstrings::file.move(f.path.from,f.path.to)
    fig <- nextFigure()
    rv$cf <- fig$cf
    rv$fn <- fig$fn
  })
  
  observeEvent(input$trash, {
    rv$value <- "trashed"
    f.path.from<-paste(image.dir,rv$cf, sep = '/')
    f.path.to<-paste(image.dir,trash.dir, sep = '/')
    filesstrings::file.move(f.path.from,f.path.to)
    fig <- nextFigure()
    rv$cf <- fig$cf
    rv$fn <- fig$fn
  })
  
  ## OTHER OUTPUTS
  output$value <- renderText({rv$value})
  
}

shinyApp(ui = ui, server = server)