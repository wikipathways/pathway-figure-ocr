# titles - v2 of the curator app to update figure number, title and caption

library(shiny)
library(shinyjs)
library(filesstrings)  
library(tidyr)
library(dplyr)
library(magrittr)


## Read in PFOCR analysis set
pfocr.figs.df <- readRDS("~/Dropbox (Gladstone)/PFOCR_25Years/pfocr_figures_fixed.rds")
afigs <- read.table("~/Dropbox (Gladstone)/PFOCR_25Years/analysis_set_figure_ids.tsv", sep="\t", stringsAsFactors = F)
pfocr.df <- pfocr.figs.df %>% filter(figid %in% afigs$V1)
  
fig.list <- unlist(unname(as.list(pfocr.df[,1])))

# set headers for output files
headers <- c("figid","pmcid","filename","number", "figtitle", "papertitle", "caption", "organism")
if(!file.exists("pfocr_curated.rds")){
  df <- data.frame(matrix(ncol=8,nrow=0))
  names(df)<-headers
  saveRDS(df, "pfocr_curated.rds")
}


getFigListTodo <- function(){
  data <- readRDS("pfocr_curated.rds")
  fig.list.done <<-data[,1, drop=TRUE]
  todo<-base::setdiff(fig.list, fig.list.done)
  done<-base::intersect(fig.list, fig.list.done)
  return(list(done,todo))
}

saveInput <- function(df){
  df.old <- readRDS("pfocr_curated.rds")
  df <- df[,names(df.old)]
  df.new <- rbind(df.old,df)
  saveRDS(df.new, "pfocr_curated.rds")
}

undoSave <- function(){
  data <- readRDS("pfocr_curated.rds")
  data <- head(data, -1)
  saveRDS(data, "pfocr_curated.rds")
}

ungreekText <- function(input.text){
  greek.text <- input.text
  greek.text <- gsub("α-", "Alpha-", greek.text)
  greek.text <- gsub("β-", "Beta-", greek.text)
  greek.text <- gsub("γ-", "Gamma-", greek.text)
  greek.text <- gsub("Ω-", "Omega-", greek.text)
  greek.text <- gsub("ω-", "omega-", greek.text)
  greek.text <- gsub("(-)?α", "A", greek.text)
  greek.text <- gsub("(-)?β", "B", greek.text)
  greek.text <- gsub("(-)?γ", "G", greek.text)
  greek.text <- gsub("(-)?δ", "D", greek.text)
  greek.text <- gsub("(-)?ε", "E", greek.text) #latin
  greek.text <- gsub("(-)?ϵ", "E", greek.text )#greek
  greek.text <- gsub("(-)?κ", "K", greek.text)
  return(greek.text)
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
        textInput("fig.org", "Organism","Homo sapiens"),
        textAreaInput("fig.title", "Figure title", "NA", width = "100%",rows = 3, resize = "vertical" ),
        textAreaInput("fig.caption", "Figure caption", "NA", width = "100%", rows = 6, resize = "vertical" ),
        
        hr(),
        # Buttons
        actionButton("preamble", label = "Remove Preamble"),
        actionButton("word", label = "Remove Word"),
        actionButton("greek", label = "Un-Greek"),
        actionButton("cap", label = "Capitalize"),
        br(),
        actionButton("papertitle", label = "Replace: Paper Title"),
        actionButton("xxxpathway", label = "Replace: ... pathway"),
        
        hr(),
        # Buttons
        tags$script(HTML("$(function(){ 
          $(document).keyup(function(e) {
            if (e.which == 39) {
              $('#save').click()
            }
          });
        })")),
        actionButton("save", label = "Save"), #right arrow
        tags$script(HTML("$(function(){ 
          $(document).keyup(function(e) {
            if (e.which == 38) {
              $('#reload').click()
            }
          });
        })")),
        actionButton("reload", label = "Reload"), #up arrow
        actionButton("reject", label = "Reject"),
        tags$script(HTML("$(function(){ 
                         $(document).keyup(function(e) {
                         if (e.which == 40) {
                         $('#other').click()
                         }
                         });
                         })")),
        actionButton("other", label = "Non-human"), #down arrow
        tags$script(HTML("$(function(){ 
                         $(document).keyup(function(e) {
                         if (e.which == 37) {
                         $('#undo').click()
                         }
                         });
                         })")),
        actionButton("undo", label = "Undo"), #left arrow
      ),
      width = 6
    ),
    
    mainPanel(
      htmlOutput("figure"),
      # imageOutput("figure"),
      width = 6
    )
  )
)

# SHINY SERVER
server <- function(input, output, session) {
  
  ## FUNCTION: retrieve next figure
  nextFigure <- function(){
    # Display remaining count and select next figure to process
    flt <- getFigListTodo() 
    fig.list.todo <- flt[[2]]
    fig.done <- length(flt[[1]])
    fig.cnt <- length(flt[[2]])
    output$fig.count <- renderText({paste(fig.done,"curated /",fig.cnt,"remaining")})
    if (fig.cnt == 0){
      shinyjs::disable("save")
      
      df<-data.frame(filename="No more files!")
      output$fig.name <- renderText({as.character(df$filename)})
      updateTextInput(session, "fig.org", value="") 
      updateTextInput(session, "fig.num", value="") 
      updateTextInput(session, "fig.title", value="") 
      updateTextInput(session, "fig.caption", value="") 
      display.url <- a("", href="")
      output$url <- renderUI({display.url})
      return(df)
    }
    # Get next fig info
    df <- pfocr.df %>% 
      dplyr::filter(figid==fig.list.todo[1])  %>% 
      droplevels()
    # output$reftext <- renderText({as.character(df$reftext)})
    figname <- df$filename
    pmcid <- df$pmcid
    output$fig.name <- renderText({as.character(df$filename)})
    ## retrieve image from local
    # output$figure <- renderImage({
    #   list(src = df$figid,
    #        alt = "No image available",
    #        width="600px")
    # }, deleteFile = FALSE)
    ## retrieve image from online
    linkout <- paste0("https://www.ncbi.nlm.nih.gov/",df$figlink)
    figid.split <- strsplit(df$figid, "__")[[1]]
    src <- paste0("https://www.ncbi.nlm.nih.gov/pmc/articles/",figid.split[1],"/bin/",figid.split[2])
    output$figure <- renderText({
      c('<a href="',linkout,'" target="_blank"><img src="',src,'", width="600px"></a>')})
    updateTextInput(session, "fig.org", value="Homo sapiens") 
    updateTextInput(session, "fig.num", value=df$number) 
    updateTextInput(session, "fig.title", value=df$figtitle) 
    updateTextInput(session, "fig.caption", value=df$caption) 
    pmc.url <- paste0("https://www.ncbi.nlm.nih.gov/pmc/articles/",pmcid)
    display.url <- a(df$papertitle, href=pmc.url)
    output$url <- renderUI({display.url})
    
    # Check for preamble
    ## update top 20 preambles so far
    df.cur <- readRDS("pfocr_curated.rds")
    df.ori <- as.data.frame(pfocr.df %>%
                              filter(figid %in% df.cur$figid))
    df.diff <- merge(df.ori, df.cur, by="figid")
    df.diff <- droplevels(df.diff)
    sub_v <- Vectorize(sub, c("pattern", "x"))
    df.diff <- df.diff %>%
      mutate(diff = unname(sub_v(tolower(figtitle.y), "XXXXXX", tolower(figtitle.x)))) %>%
      tidyr::separate(diff, c("diff.pre","diff.suf"),"XXXXXX", remove = F, fill="right") %>%
      mutate(diff.pre = ifelse(diff.pre == diff|diff.pre == "", NA, diff.pre))
    pre.20 <- names(sort(table(df.diff$diff.pre),decreasing = T)[1:40])
    pre.20 <- pre.20[order(nchar(pre.20), pre.20, decreasing = T)]
    ## update title
    cur.title <- as.character(df$figtitle)
    new.title.list <- sapply(pre.20, function(x){
      sub(paste0("^",x),"", cur.title, ignore.case = T)
    })
    new.title.list <- new.title.list[order(nchar(new.title.list), new.title.list, decreasing = F)]
    new.title <- unname(new.title.list[1])
    ## Check for "of the"
    pattern <- "^(.*\\s(of|by|between)\\s((the|which)\\s)?)"
    if (grepl(pattern, cur.title)){
      new.title2 <- gsub(pattern, "", cur.title)
      if (nchar(new.title2) < nchar(new.title)) { #keep shortest
        new.title <- new.title2
      }
    }
    ## Did we find anything?
    if(is.na(cur.title)|cur.title == ""){
      cur.title <- df$papertitle
      updateTextInput(session, "fig.title", value=df$papertitle)
      shinyjs::disable("preamble")
    } else {
      if (!nchar(new.title) < nchar(cur.title)){
        df$new.title <- cur.title
        shinyjs::disable("preamble")
      } else {
        ## capitalize first characters
        substr(new.title, 1, 1) <- toupper(substr(new.title, 1, 1))
        new.title.cnt <- sapply(strsplit(new.title, " "), length)
        if(new.title.cnt > 3){ #if more than 3 words remain, then apply it now!
          cur.title<-new.title
          updateTextInput(session, "fig.title", value=new.title)
          shinyjs::disable("preamble")
        } else { #store it as a button option
          df$new.title <- new.title
          shinyjs::enable("preamble")
        }
      }
    }
    
    ## Un-Greek, every time!
    ungreek.title <- ungreekText(cur.title)
    updateTextInput(session, "fig.title", value=ungreek.title) 

    # Check for "XXX pathway"
    pattern <- "^.*?\\s*?([A-Za-z0-9_/-]+\\s([Ss]ignaling\\s)*pathway).*$"
    if (grepl(pattern, cur.title)){
      df$alt.title <- gsub(pattern, "\\1", cur.title)
      substr(df$alt.title, 1, 1) <- toupper(substr(df$alt.title, 1, 1))
      shinyjs::enable("xxxpathway")
    } else {
      df$alt.title <- df$figtitle
      shinyjs::disable("xxxpathway")
    }
      
    return(df)
  }
  fig <- nextFigure()
  
  ## DEFINE SHARED VARS
  rv <- reactiveValues(fig.df=fig)  

  ## FUNCTION: override rv with input values
  getInputValues <- function(df) {
    df$fig.df$number <- input$fig.num 
    df$fig.df$organism <- input$fig.org 
    df$fig.df$figtitle <- input$fig.title
    df$fig.df$caption <- input$fig.caption
    return(df)
  }
  
  ## BUTTON FUNCTIONALITY
  observeEvent(input$save, {
    rv <- getInputValues(rv)
    saveInput(rv$fig.df)
    rv$fig.df <- nextFigure()
  })
  
  observeEvent(input$reload, {
    rv$fig.df <- nextFigure()
  })
  
  observeEvent(input$reject, {
    updateTextInput(session, "fig.org", value="REJECT") 
    updateTextInput(session, "fig.num", value="REJECT") 
    updateTextInput(session, "fig.title", value="REJECT") 
    updateTextInput(session, "fig.caption", value="REJECT") 
  })
  
  observeEvent(input$other, {
    updateTextInput(session, "fig.org", value="XXX") 
  })
  
  observeEvent(input$undo, {
    undoSave()
    rv$fig.df <- nextFigure()
  })
  
  observeEvent(input$preamble, {
    updateTextInput(session, "fig.title", value=rv$fig.df$new.title) 
  })
  
  observeEvent(input$papertitle, {
    updateTextInput(session, "fig.title", value=rv$fig.df$papertitle) 
  })
  
  observeEvent(input$xxxpathway, {
    updateTextInput(session, "fig.title", value=rv$fig.df$alt.title) 
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
  
  observeEvent(input$greek, {
    ungreek.title <- ungreekText(input$fig.title)
    updateTextInput(session, "fig.title", value=ungreek.title) 
  })
  
}

shinyApp(ui = ui, server = server)