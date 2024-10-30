#' ---
#' title: "ENA submission"
#' author: "Nicolas Delhomme"
#' date: "`r Sys.Date()`"
#' output:
#'  html_document:
#'    toc: true
#'    number_sections: true
#'    code_folding: hide
#' ---
#' # Setup
#' * Libraries
suppressPackageStartupMessages({
  library(dplyr)
  library(here)
  library(readr)
  library(UpSetR)
})

#' # Datasets
#' 
#' ## Public
#' 
#' ### SVP
SVP <- read_csv(here("doc/ENA/SVP-samples-ENA-submission.csv"),show_col_types=FALSE) %>% 
  mutate(ID=sub("_S.*","",FileName)) %>% 
  select(ID) %>% distinct(ID)

#' ### FT1  
FT1 <-read_csv(here("doc/ENA/ENA-submission-UPSC-0190.csv"),show_col_types=FALSE) %>% 
  mutate(ID=sub("_S.*","",FileName)) %>% 
  select(ID) %>% distinct(ID)

#' ## Private
#' 
#' ### Annual samples
year <- read_csv(here("doc/ENA/year-samples-ENA-submission.csv"),show_col_types=FALSE) %>% 
  mutate(ID=sub("_S.*","",FileName)) %>% 
  select(ID) %>% distinct(ID)

#' ### This study
it <- read_csv(here("doc/Sample-annotation-transcriptomic-project.csv"),show_col_types=FALSE) %>% 
  mutate(ID=paste(P1,P2,sep="_")) %>% 
  select(ID) %>% distinct(ID)

#' ## Check
allIDs <- sort(unique(c(FT1$ID,SVP$ID,it$ID,year$ID)))
df <- data.frame(FT1=as.numeric(allIDs %in% FT1$ID),
                 SVP=as.numeric(allIDs %in% SVP$ID),
                 it=as.numeric(allIDs %in% it$ID),
                 year=as.numeric(allIDs %in% year$ID))

#' We have 66 samples left to publish
upset(df)

#' ## Submission
#'
#' IDs to submit
IDs <- setdiff(sort(it$ID),sort(unique(c(SVP$ID,FT1$ID,year$ID))))

#' create the data structure
tb <- tibble(
  ExperimentTitle=rep("A transcriptional roadmap of the yearly growth cycle in Populus trees",length(IDs)),
  SampleName=IDs,
  SampleDescription="",
  SequencingDate="",
  FileName=IDs,
  FileLocation="",
  DataSet=sub("_.*","",IDs)
)

#' gather dataset info (date and location)
tb[tb$DataSet=="P10011",c("SequencingDate","FileLocation")] <- read_csv(here("doc/ENA/SVP-samples-ENA-submission.csv"),
                                                                        col_types=c("cccccc"),show_col_types=FALSE,n_max=1) %>% 
  select(SequencingDate,FileLocation)

tb[tb$DataSet=="P12869",c("SequencingDate","FileLocation")] <- data.frame(SequencingDate="2019-05-13T10:00:00",
                                                                          FileLocation="/mnt/picea/storage/data/aspseq/onilsson/aspen-FTL1-growth-cessation/P12869/links")

tb[tb$DataSet=="P17253",c("SequencingDate","FileLocation")] <- data.frame(SequencingDate="2020-10-19T10:00:00",
                                                                          FileLocation="/mnt/picea/storage/data/aspseq/onilsson/T89-diurnal-analysis/links")

#' create the sample description
info <- read_csv(here("doc/Sample-annotation-transcriptomic-project.csv"),show_col_types=FALSE) %>% 
  mutate(ID=paste(P1,P2,sep="_"),SampleDescription=sprintf("Sample from %s grown %s collected under the treatment %s",tolower(Tissue),tolower(Location),Treatment))

tb$SampleDescription <- unlist(info[match(tb$SampleName,info$ID),"SampleDescription"])

#' find the files
flist <- apply(tb,1,function(ro){
  list.files(path=ro["FileLocation"],pattern=ro["FileName"],full.names=TRUE)
})

#' duplicate the lines
tb <- tb[rep(1:nrow(tb),S4Vectors::elementNROWS(flist)),]
tb$FileName <- basename(unlist(flist))

#' Sanity
stopifnot(all(grep("R1",tb$FileName) == seq(1,nrow(tb),2)))
stopifnot(all(grep("R2",tb$FileName) == seq(2,nrow(tb),2)))

#' change IDs to separate tech reps
reps <- names(table(tb$SampleName))[table(tb$SampleName)==4]
tb[tb$SampleName %in% reps,"SampleDescription"] <- paste(unlist(tb[tb$SampleName %in% reps,"SampleDescription"])," technical replicate ",c(1,1,2,2))
tb[tb$SampleName %in% reps,"SampleName"] <- paste(unlist(tb[tb$SampleName %in% reps,"SampleName"]),c(1,1,2,2),sep="_")
   
#' # Export
#' 
#' the doc
write_csv(tb %>% select(-DataSet),file=here("doc/ENA/ENA-submission-UPSC-0224.csv"))

#' create data links
dir.create(here("data/raw"),recursive=TRUE)
sapply(tb %>% mutate(Link=file.path(FileLocation,FileName)) %>% select(Link) %>% unlist(use.names=FALSE),
       function(p){system(sprintf("cd data/raw && ln -s %s",p))
       })

#' # Session Info
#' ```{r session info, echo=FALSE}
#' sessionInfo()
#' ```
