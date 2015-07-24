## This probably is only of interest to me. Left here for the sake of
## historical record.


## So a whole bunch (291) of files were renamed, with either file names or
## path names shortened. No idea why or by whom. I suspect of Mendeley,
## but cannot say for sure.

## Regardless of who is the culprit, as we have said, this idea of having
## unhealthily long directory or file names is ... well, unhealthy.

## Fortunately, seafile recorded the event (I keep a backup of a bunch of
## things via seafile on my own servers). I just found the day, and
## copied, as text file, the list of files affected. Below I just copy
## things back. I will only need to do this once, to make sure all files
## exist at the paths Menedely claims. Then, I will export things to
## bibtex, etc, and will live happily ever after (after my divorce from
## Mendeley, I mean).


renamedFiles <- "renamed-files-20-06.txt"
tmpf <- "renamed2.txt"

parentDir <- "/home/ramon/Mendeley-pdfs"


###########################################################################
gsubTheCrap <- function(x) {
    ## This is a good example of the kinds of things that Mendeley makes
    ## possible, and shouldn't
    x <- gsub(" ", "\\ ", x, fixed = TRUE)
    x <- gsub("(", "\\(", x, fixed = TRUE)
    x <- gsub(")", "\\)", x, fixed = TRUE)
    x <- gsub("'", "\\'", x, fixed = TRUE)
    x <- gsub("&", "\\&", x, fixed = TRUE)
    return(x)
}

splitRename <- function(x) {
    tmp <- strsplit(x, " ==> ")[[1]]
    return(c(from = gsubTheCrap(tmp[1]), to = gsubTheCrap(tmp[2])))
}

## FIXME will not work if messing with new directories

## FIXME: need to check for directory and create it if it does not

createDirIfNeed <- function(x) {
    ## If the directory is not present, it creates it. We assume a single
    ## directory.
    dir <- strsplit(x, "/")[[1]][1]
    ## we just do it, it will fail if exists
    system(paste("mkdir", dir))
}


cpBack <- function(x) {
    y <- splitRename(x)
    createDirIfNeed(y["from"])
    cmd <- system(paste("cp ", y["to"], " ",
                        y["from"]), intern = FALSE)
    if(cmd) {
        cat("\n Copying file failed for ", y["to"])
        warning("\n Copying file failed for ", y["to"])
    }
}

###########################################################################

##
rfs <- readLines(tmpf)

setwd(parentDir)

sapply(rfs, cpBack)
