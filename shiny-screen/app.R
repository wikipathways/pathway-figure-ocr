# screen - segregate pathway, composite and other images

library(shiny)
library(shinyjs)
library(filesstrings)  
library(magrittr)
library(dplyr)

## LOCAL INFO PER INSTALLATION
fetch.path <- "/git/wikipathways/pathway-figure-ocr/20200131"
image.path <- paste(fetch.path, "images", sep = '/')
to.dir <- c("pathway", "composite", "other", "skip")
dir.create(image.path, FALSE)
lapply(to.dir, function(x){
  dir.create(paste(image.path,x,sep='/'), FALSE)
})

## Read in PFOCR fetch results
setwd(fetch.path)
df.all <- readRDS("pfocr.man.235k_10k.rds") ## MOD: df.target.rds or df.all.rds
df.all <- df.all %>%
  arrange((as.numeric(pathway_score_diff))) %>%
  top_n(-100) %>%
  dplyr::select(figid, pmcid, filename, figtitle) 

fig.list <- df.all$figid
# set headers for output files
headers <- c(names(df.all), "type.man")
lapply(to.dir, function(x){
  f.path.to<-paste(image.path,x, sep = '/')
  fn <- (paste(f.path.to,paste0("pfocr_",x,".rds"),sep = '/'))
  if(!file.exists(fn)){
    df <- data.frame(matrix(ncol=5,nrow=0))
    names(df)<-headers
    saveRDS(df, fn)
  }
})

getFigListTodo <- function(){
  fig.list.done <<- unlist(lapply(to.dir, function(x){
    next.file <- paste(image.path,x,paste0("pfocr_",x,".rds"),sep = '/')
    if (file.exists(next.file)){
      data <- readRDS(next.file)
      as.character(data$figid)
    }
  }))
  list(todo=BiocGenerics::setdiff(fig.list, fig.list.done), done=fig.list.done)
}

getBulkFigures <- function(fig.todo) {
  df.todo <- df.all %>%
    filter(figid %in% fig.todo) %>%
    droplevels()
  withProgress(message="Fetching more images...", {
    by(df.todo, 1:nrow(df.todo), function(df){
      figname <- df$filename
      pmcid <- df$pmcid
      ## retrieve image from PMC #NOTE: USE PMC+FILENAME TO KEEP UNIQUE 
      figure_link <- paste0("https://www.ncbi.nlm.nih.gov/pmc/articles/",pmcid,"/bin/",figname)
      download.file(figure_link,paste(image.path,df$figid,sep = '/'), mode = 'wb')
      ## retrieve from local folder ## MOD: local vs PMC
      # f.path.from<-paste(fetch.path, "all_images",df$figid, sep = '/')
      # f.path.to<-paste(image.path)
      # if(file.exists(f.path.from)){
      #   filesstrings::file.move(f.path.from,f.path.to,overwrite = TRUE)
      # }
      ## count it!
      incProgress(1/nrow(df.todo))
    })
  })
}

saveChoice <- function(df){
  f.path.from<-paste(image.path,df$figid, sep = '/')
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

undoChoice <- function(choice){
  fn <- paste(image.path,choice,paste0("pfocr_",choice,".rds"),sep = '/')
  ## read/save rds
  df.old <- readRDS(fn)
  figid <- tail(df.old$figid,1)
  df.new <- df.old[-nrow(df.old),]
  saveRDS(df.new, fn)
  ## move figure
  f.path.from<-paste(image.path,choice,figid, sep = '/')
  f.path.to<-paste(image.path)
  if(file.exists(f.path.from))
    filesstrings::file.move(f.path.from,f.path.to,overwrite = TRUE)
}

# SHINY UI
ui <- fluidPage(
  titlePanel("PFOCR Screen"),
  
  sidebarLayout(
    sidebarPanel(
      fluidPage(
        useShinyjs(),
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
        actionButton("skip", label = "Skip"), #space bar
        
        hr(),
        tags$script(HTML("$(function(){ 
                         $(document).keyup(function(e) {
                         if (e.which == 90) {
                         $('#undo').click()
                         }
                         });
                         })")),
        actionButton("undo", label = "Undo"), #z key
        textOutput("last.choice")
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
    fig.todo.lists <- getFigListTodo() 
    fig.list.todo <- fig.todo.lists$todo
    fig.cnt <- length(fig.list.todo)
    fig.cnt.done <- length(fig.todo.lists$done)
    output$fig.count <- renderText({paste0(fig.cnt.done,"/",fig.cnt.done+fig.cnt," (",fig.cnt," remaining)")})
    if (fig.cnt == 0){
      shinyjs::disable("one")
      shinyjs::disable("two")
      shinyjs::disable("three")
      shinyjs::disable("skip")
      
      df<-data.frame(figtitle="No more files!")
      output$fig.title <- renderText({as.character(df$figtitle)})
      output$fig.name <- renderText({as.character("")})
      display.url <- a("", href="")
      output$url <- renderUI({display.url})
      return(df)
    }
    # Assess bulk set of images
    fig.list <- list.files(image.path, pattern = "\\.jpg$")
    if(length(fig.list) < 1){
      bulk <- ifelse(fig.cnt < 50, fig.cnt, 50)
      getBulkFigures(head(fig.list.todo,bulk)) ## MOD: head or tail
      fig.list <- list.files(image.path, pattern = "\\.jpg$")
    }
    # Get next fig info
    df <- df.all %>% 
      filter(figid==head(fig.list.todo,1))  %>% ## MOD: head or tail
      droplevels()
    figname <- df$filename
    pmcid <- df$pmcid
    output$fig.name <- renderText({as.character(figname)})
    ## retrieve image from local
    output$figure <- renderImage({
      list(src = paste(image.path,df$figid, sep = '/'),
           alt = "No image available",
           width="600px")
    }, deleteFile = FALSE)
    output$fig.title <- renderText({as.character(df$figtitle)})
    url <- paste0("https://www.ncbi.nlm.nih.gov/pmc/articles/",pmcid)
    display.url <- a(pmcid, href=url)
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
    rv$fig.df$choice <- to.dir[1] # temp track last choice for undo
    output$last.choice <- renderText({as.character(rv$fig.df$choice)})
    shinyjs::enable("undo")
  })
  
  observeEvent(input$two, {
    rv$fig.df$choice <- to.dir[2]
    saveChoice(rv$fig.df)
    rv$fig.df <- nextFigure()
    rv$fig.df$choice <- to.dir[2] # temp track last choice for undo
    output$last.choice <- renderText({as.character(rv$fig.df$choice)})
    shinyjs::enable("undo")
  })
  
  observeEvent(input$three, {
    rv$fig.df$choice <- to.dir[3]
    saveChoice(rv$fig.df)
    rv$fig.df <- nextFigure()
    rv$fig.df$choice <- to.dir[3] # temp track last choice for undo
    output$last.choice <- renderText({as.character(rv$fig.df$choice)})
    shinyjs::enable("undo")
  })
  
  observeEvent(input$skip, {
    rv$fig.df$choice <- to.dir[4]
    saveChoice(rv$fig.df)
    rv$fig.df <- nextFigure()
    rv$fig.df$choice <- to.dir[4] # temp track last choice for undo
    output$last.choice <- renderText({as.character(rv$fig.df$choice)})
    shinyjs::enable("undo")
  })
  
  observeEvent(input$undo, {
    if(!is.null(rv$fig.df$choice)){ #only respond if last.choice is known
      undoChoice(rv$fig.df$choice)
      rv$fig.df <- nextFigure()
    }
    shinyjs::disable("undo")
  })
}

shinyApp(ui = ui, server = server)