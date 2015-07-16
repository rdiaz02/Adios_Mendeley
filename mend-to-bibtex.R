MendeleySQL <- "mend.sqlite"
BibTeXFile <- "library.bib"



source("sqlite-bibtex-functions.R")


con <- dbConnect(SQLite(), MendeleySQL)
minimalDBchecks(con)

## Continue if things are ok


res <- dbGetQuery(con, sqliteQuery1) 
res$timestamp <- getTimestamp(res)
minimalDBDFchecks(res)


## FIXME check here for missing latex keys



bibfile <- myBibtexReader(BibTeXFile)

bibtexDBConsistencyCheck(res, bib) 


jabrefGr <- jabrefGroups(con, res)

## If you want to see what it looks like
write(file = "jabref-groups.txt",
      jabrefGr)

##   add info to bibtex
## can I add arbitrary info to bibtex
## FIXME: append the jabrefGr to the rest of the jabref DB
## FIXME: rename the long files
## - fix repeated entries
## - write the script to clean bibtex for tablet


## df1 <- dbReadTable(con, "DocumentFolders")[, -3] ## remove "status" column
## df2 <- dbReadTable(con, "DocumentFoldersBase")
## folders <- rbind(df1, df2)

## folders <- foldersDBread(con)
## Then use bibtex key and folder name.
## folderDocuments <- by(folders, folders$folderId,
##                       function(x) {unique(x$documentId)})

## folderNames <- dbReadTable(con, "Folders")[, c(1, 3, 4)]



## folderNames$depth <- 0
## folderNames$depth[folderNames$parentId %in% c(0, -1) ] <- 1
## depthFolder <- function(id, df = folderNames) {
##     ## In terms of id, because easier for error checking.
##     pos <- which(df$id == id)
##     parentId <- df[pos, "parentId"]
##     if(parentId %in% c(0, -1) ) return(1)
##     else {
##         posParent <- which(df$id == parentId)
##         return(df[posParent, "depth"] + 1)
##     }
## }
## changesDepth <- TRUE
## while(changesDepth) {
##     formerDepth <- folderNames$depth
##     folderNames$depth <- sapply(folderNames$id, depthFolder)
##     if(all(formerDepth == folderNames$depth))
##         changesDepth <- FALSE
## }




## folderNames$depth <- computeFolderDepth(folderNames)
## orderedFolderNames <- orderFolderNames(folderNames)





## to do still:

## rename long file names
## add info to bibtex
## check bibtex errors/warnings


## bibtex0 <- readLines(con = "mini.bib")



## bibfile <- myBibtexReader(bibtex0)
## bibtex2 <- readLines(con = "library.bib")
## bibfile2 <- myBibtexReader(bibtex2)

## why do I have NAs in bibtex keys? Because many things are not exported
## to bibtex! Any that do not have keys!!!

## FIXME: check num rows in dd and length bibfile are the same!
## add mendeley id to bibtex too







## Miscell stuff
## Notes in the PDF
dbReadTable(con, "FileNotes")[1:10, ] ## notes fields note and baseNote
## are identical But those I already have in the PDF. Since easy and
## cheap, make sure I have all.

## Notes in the entry itself
cucu <- dbReadTable(con, "DocumentNotes")
## use the text field

## I need date added

dbListFields(con, "Documents")




dd <- dbReadTable(con, "Documents")

res7 <- dbGetQuery(con, "
SELECT
Documents.id AS Ref_id,
Documents.citationKey AS Ref_BibtexKey,
cast(Documents.added as real) AS Ref_added,
DocumentNotes.text AS Ref_notes
FROM
Documents
LEFT OUTER JOIN DocumentNotes ON Documents.id = DocumentNotes.documentId 
")
res7$timestamp <- as.character(format(round(as.POSIXct("1970-01-01",
                                                       tz="GMT+2") +
                                                           res7$Ref_added/1000,
                                            "secs")))
dim(res7); names(res7)


as.character(format(round(as.POSIXct("1970-01-01", tz="GMT+2") + res7$Ref_added/1000,  "secs")))[1]





## all the tables
tables <- dbListTables(con)
sapply(tables, function(x) dbListFields(con, x))


## - exporting from Mendeley the folders
##     - It is in the DocumentFolders and DocumentFoldersBase (for names)



## check the two books for hpbbm




## resPdf <- dbGetQuery(con, "
## SELECT FileNotes.documentId, group_concat(FileNotes.note, ' \n ')
## FROM FileNotes
## GROUP BY FileNotes.documentId
## ")



## res <- dbGetQuery(con, "
## SELECT
## Documents.id AS Ref_id,
## Documents.citationKey AS Ref_BibtexKey,
## cast(Documents.added as real) AS Ref_added,
## DocumentNotes.text AS Ref_notes,
## (SELECT group_concat(FileNotes.note, ' \n ')
##  FROM FileNotes GROUP BY FileNotes.documentId
##  ) AS Ref_PDFnotes
## FROM
## Documents
## LEFT OUTER JOIN DocumentNotes ON Documents.id = DocumentNotes.documentId
## LEFT OUTER JOIN FileNotes ON Documents.id = FileNotes.documentId")
