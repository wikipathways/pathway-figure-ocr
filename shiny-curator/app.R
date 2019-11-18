# curator - update figure number, title and caption

library(shiny)
library(shinyjs)
library(filesstrings)  
library(tidyr)
library(dplyr)
library(magrittr)



## LOCAL INFO PER INSTALLATION
fetch.path <- "SET_TO_LOCAL_DIRECTORY"
image.path <- paste(fetch.path, "images", "pathway", sep = '/')

## Read in PFOCR fetch results
setwd(image.path)
pmc.df.all <- readRDS("pfocr_pathway.rds")
fig.list <- unlist(unname(as.list(pmc.df.all[,1])))
# set headers for output files
headers <- names(pmc.df.all)
if(!file.exists("pfocr_curated.rds")){
  df <- data.frame(matrix(ncol=10,nrow=0))
  names(df)<-headers
  saveRDS(df, "pfocr_curated.rds")
}


getFigListTodo <- function(){
  data <- readRDS("pfocr_curated.rds")
  fig.list.done <<-data[,1, drop=TRUE]
  base::setdiff(fig.list, fig.list.done)
}

saveChoice <- function(df){
  df.old <- readRDS("pfocr_curated.rds")
  df <- df[,names(df.old)]
  df.new <- rbind(df.old,df)
  saveRDS(df.new, "pfocr_curated.rds")
}

# SHINY UI
ui <- fluidPage(
  titlePanel("PFOCR Curator"),
  
  sidebarLayout(
    sidebarPanel(
      fluidPage(
        useShinyjs(),
        # Figure information
        textOutput("fig.count"),
        h5("Current figure"),
        textOutput("fig.name"),
        uiOutput("url"),
        # textOutput("reftext"),
        p(),
        textInput("fig.num", "Figure number","NA"),
        textAreaInput("fig.title", "Figure title", "NA", width = "100%",rows = 3, resize = "vertical" ),
        textAreaInput("fig.caption", "Figure caption", "NA", width = "100%", rows = 6, resize = "vertical" ),
        
        hr(),
        # Buttons
        actionButton("preamble", label = "Remove Preamble"),
        actionButton("word", label = "Remove Word"),
        actionButton("cap", label = "Capitalize"),
        
        hr(),
        # Buttons
        actionButton("save", label = "Save")
      ),
      width = 6
    ),
    
    mainPanel(
      imageOutput("figure"),
      width = 6
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
      shinyjs::disable("save")
      
      df<-data.frame(pmc.filename="No more files!")
      output$fig.name <- renderText({as.character(df$pmc.filename)})
      updateTextInput(session, "fig.num", value="") 
      updateTextInput(session, "fig.title", value="") 
      updateTextInput(session, "fig.caption", value="") 
      display.url <- a("", href="")
      output$url <- renderUI({display.url})
      return(df)
    }
    # Get next fig info
    df <- pmc.df.all %>% 
      dplyr::filter(pmc.figid==fig.list.todo[1])  %>% 
      droplevels()
    # output$reftext <- renderText({as.character(df$pmc.reftext)})
    figname <- df$pmc.filename
    pmcid <- df$pmc.pmcid
    output$fig.name <- renderText({as.character(df$pmc.filename)})
    ## retrieve image from local
    output$figure <- renderImage({
      list(src = df$pmc.figid,
           alt = "No image available",
           width="600px")
    }, deleteFile = FALSE)
    updateTextInput(session, "fig.num", value=df$pmc.number) 
    updateTextInput(session, "fig.title", value=df$pmc.figtitle) 
    updateTextInput(session, "fig.caption", value=df$pmc.caption) 
    pmc.url <- paste0("https://www.ncbi.nlm.nih.gov/pmc/articles/",pmcid)
    display.url <- a(pmcid, href=pmc.url)
    output$url <- renderUI({display.url})
    
    # Check for preamble
    ## update top 20 preambles so far
    df.cur <- readRDS("pfocr_curated.rds")
    df.ori <- as.data.frame(pmc.df.all %>%
                              filter(pmc.figid %in% df.cur$pmc.figid))
    df.diff <- merge(df.ori, df.cur, by="pmc.figid")
    df.diff <- droplevels(df.diff)
    gsub_v <- Vectorize(gsub, c("pattern", "x"))
    df.diff <- df.diff %>%
      mutate(diff = unname(gsub_v(tolower(pmc.figtitle.y), "XXXXXX", tolower(pmc.figtitle.x)))) %>%
      tidyr::separate(diff, c("diff.pre","diff.suf"),"XXXXXX", remove = F, fill="right") %>%
      mutate(diff.pre = ifelse(diff.pre == diff|diff.pre == "", NA, diff.pre))
    pre.20 <- names(sort(table(df.diff$diff.pre),decreasing = T)[1:20])
    pre.20 <- pre.20[order(nchar(pre.20), pre.20, decreasing = T)]
    ## update title
    cur.title <- as.character(df$pmc.figtitle)
    new.title.list <- sapply(pre.20, function(x){
      sub(paste0("^",x),"", cur.title, ignore.case = T)
    })
    new.title.list <- new.title.list[order(nchar(new.title.list), new.title.list, decreasing = F)]
    new.title <- unname(new.title.list[1])
    ## capitalize first characters
    substr(new.title, 1, 1) <- toupper(substr(new.title, 1, 1))
    df$new.title <- new.title
    if (!nchar(new.title) < nchar(cur.title)){
      shinyjs::disable("preamble")
    } else {
      shinyjs::enable("preamble")
    }
      
    return(df)
  }
  fig <- nextFigure()
  
  ## DEFINE SHARED VARS
  rv <- reactiveValues(fig.df=fig)  

  ## FUNCTION: override rv with input values
  getInputValues <- function(df) {
    df$fig.df$pmc.number <- input$fig.num 
    df$fig.df$pmc.figtitle <- input$fig.title
    df$fig.df$pmc.caption <- input$fig.caption
    return(df)
  }
  
  ## BUTTON FUNCTIONALITY
  observeEvent(input$save, {
    rv <- getInputValues(rv)
    saveChoice(rv$fig.df)
    rv$fig.df <- nextFigure()
  })
  
  observeEvent(input$preamble, {
    updateTextInput(session, "fig.title", value=rv$fig.df$new.title) 
  })

  observeEvent(input$word, {
    new.title <- input$fig.title
    new.title <- gsub("^\\w+\\s","",new.title)
    substr(new.title, 1, 1) <- toupper(substr(new.title, 1, 1))
    updateTextInput(session, "fig.title", value=new.title) 
  })
  
  observeEvent(input$cap, {
    new.title <- input$fig.title
    substr(new.title, 1, 1) <- toupper(substr(new.title, 1, 1))
    updateTextInput(session, "fig.title", value=new.title) 
  })
  
}

shinyApp(ui = ui, server = server)