# screen - segregate pathway, composite and other images

library(shiny)
library(filesstrings)  
library(magrittr)

## LOCAL INFO PER INSTALLATION
fetch.path <- "/git/wikipathways/pathway-figure-ocr/20191020"
image.path <- paste(fetch.path, "images", sep = '/')
to.dir <- c("pathway", "composite", "other", "skip")
dir.create(image.path, FALSE)
lapply(to.dir, function(x){
  dir.create(paste(image.path,x,sep='/'), FALSE)
})

## Read in PFOCR fetch results
setwd(fetch.path)
pmc.df.all <- readRDS("pmc.df.all.rds")
fig.list <- pmc.df.all$pmc.figid
# set headers for output files
headers <- c(names(pmc.df.all), "cur.figtype")
lapply(to.dir, function(x){
  f.path.to<-paste(image.path,x, sep = '/')
  fn <- (paste(f.path.to,paste0("pfocr_",x,".rds"),sep = '/'))
  if(!file.exists(fn)){
    df <- data.frame(matrix(ncol=10,nrow=0))
    names(df)<-headers
    saveRDS(df, fn)
  }
})

getFigListTodo <- function(){
  fig.list.done <<- unlist(lapply(to.dir, function(x){
    next.file <- paste(image.path,x,paste0("pfocr_",x,".rds"),sep = '/')
    if (file.exists(next.file)){
      data <- readRDS(next.file)
      as.character(data$pmc.figid)
    }
  }))
  setdiff(fig.list, fig.list.done)
}

getBulkFigures <- function(fig.todo) {
  df.todo <- pmc.df.all %>%
    filter(pmc.figid %in% fig.todo) %>%
    droplevels()
  withProgress(message="Fetching more images...", {
    by(df.todo, 1:nrow(df.todo), function(df){
      figname <- df$pmc.filename
      pmcid <- df$pmc.pmcid
      ## retrieve image from PMC
      figure_link <- paste0("https://www.ncbi.nlm.nih.gov/pmc/articles/",pmcid,"/bin/",figname)
      download.file(figure_link,paste(image.path,figname,sep = '/'), mode = 'wb')
      incProgress(1/nrow(df.todo))
    })
  })
}

saveChoice <- function(df){
  f.path.from<-paste(image.path,df$pmc.filename, sep = '/')
  f.path.to<-paste(image.path,df$choice, sep = '/')
  fn <- paste(f.path.to,paste0("pfocr_",df$choice,".rds"),sep = '/')
  ## read/save rds
  df.old <- readRDS(fn)
  names(df) <- names(df.old)
  df.new <- rbind(df.old,df)
  saveRDS(df.new, fn)
  ## move figure
  if(file.exists(f.path.from))
    filesstrings::file.move(f.path.from,f.path.to,overwrite = TRUE)
}

# SHINY UI
ui <- fluidPage(
  titlePanel("PFOCR Curator"),
  
  sidebarLayout(
    sidebarPanel(
      fluidPage(
        # Figure information
        textOutput("fig.count"),
        h5("Current figure"),
        textOutput("fig.name"),
        p(textOutput("fig.title")),
        uiOutput("url"),
        
        hr(),
        # Buttons
        tags$script(HTML("$(function(){ 
          $(document).keyup(function(e) {
            if (e.which == 37) {
              $('#one').click()
            }
          });
        })")),
        actionButton("one", label = "Pathway"), #left arrow
        
        tags$script(HTML("$(function(){ 
          $(document).keyup(function(e) {
            if (e.which == 40) {
              $('#two').click()
            }
          });
        })")),
        actionButton("two", label = "Composite"), #down arrow
        
        tags$script(HTML("$(function(){ 
          $(document).keyup(function(e) {
            if (e.which == 39) {
              $('#three').click()
            }
          });
        })")),
        actionButton("three", label = "Other"), #right arrow
        
        hr(),
        tags$script(HTML("$(function(){ 
          $(document).keyup(function(e) {
                         if (e.which == 32) {
                         $('#skip').click()
                         }
                         });
                         })")),
        actionButton("skip", label = "Skip") #space bar
      ),
      width = 4
    ),
    
    mainPanel(
      imageOutput("figure"),
      width = 8
    )
  )
)

# SHINY SERVER
server <- function(input, output, session) {
  
  ## FUNCTION: retrieve next figure
  nextFigure <- function(){
    # Display remaining count and select next figure to process
    fig.list.todo <- getFigListTodo() 
    fig.cnt <- length(fig.list.todo)
    output$fig.count <- renderText({paste(fig.cnt,"figures remaining")})
    if (fig.cnt == 0){
      #TODO: fail gracefully
      # shinyjs::disable("keep") ## not working...
      # shinyjs::disable("trash")
    }
    # Assess bulk set of images
    fig.list <- list.files(image.path, pattern = "\\.jpg$")
    if(length(fig.list) < 1){
      bulk <- ifelse(length(fig.list.todo) < 50, length(fig.list.todo), 50)
      getBulkFigures(fig.list.todo[1:bulk])
      fig.list <- list.files(image.path, pattern = "\\.jpg$")
    }
    # Get next fig info
    df <- pmc.df.all %>% 
      filter(pmc.figid==fig.list.todo[1])  %>% 
      droplevels()
    # output$reftext <- renderText({as.character(df$pmc.reftext)})
    figname <- df$pmc.filename
    pmcid <- df$pmc.pmcid
    output$fig.name <- renderText({as.character(df$pmc.filename)})
    ## retrieve image from local
    output$figure <- renderImage({
      list(src = paste(image.path,figname, sep = '/'),
           alt = "No image available",
           width="600px")
    }, deleteFile = FALSE)
    output$fig.title <- renderText({as.character(df$pmc.figtitle)})
    pmc.url <- paste0("https://www.ncbi.nlm.nih.gov/pmc/articles/",pmcid)
    display.url <- a(pmcid, href=pmc.url)
    output$url <- renderUI({display.url})
    
    return(df)
  }
  fig <- nextFigure()
  
  ## DEFINE SHARED VARS
  rv <- reactiveValues(fig.df=fig)  
  
  ## BUTTON FUNCTIONALITY
  observeEvent(input$one, {
    rv$fig.df$choice <- to.dir[1]
    saveChoice(rv$fig.df)
    rv$fig.df <- nextFigure()
  })
  
  observeEvent(input$two, {
    rv$fig.df$choice <- to.dir[2]
    saveChoice(rv$fig.df)
    rv$fig.df <- nextFigure()
  })
  
  observeEvent(input$three, {
    rv$fig.df$choice <- to.dir[3]
    saveChoice(rv$fig.df)
    rv$fig.df <- nextFigure()
  })

  observeEvent(input$skip, {
    rv$fig.df$choice <- to.dir[4]
    saveChoice(rv$fig.df)
    rv$fig.df <- nextFigure()
  })
}

shinyApp(ui = ui, server = server)