
MendeleySQL <- "mend.sqlite"
BibTeXFile <- "library.bib"



## library(RefManageR)
## library(bibtex)



## bibfile <- read.bib(file = BibTeXFile) ## Nope: ignores incomplete entries
## bibfile <- ReadBib(file = BibTeXFile, check = FALSE): Drops fields I care about



source("sqlite-functions.R")
source("bibtex-functions.R")

bibfile <- myBibtexReader(BibTeXFile)

res <- dbGetQuery(con, sqliteQuery1) 



con <- dbConnect(SQLite(), MendeleySQL)
dbListTables(con)

## All the tables
tables <- dbListTables(con)
sapply(tables, function(x) dbListFields(con, x))














## Documents: date added, notes, and bibtexkey.
## Mendeley should export the notes in the "annote" filed but it doesn't
## always, specially if you have newlines. It is a known bug.

## For the cast thing, see: https://github.com/rstats-db/RSQLite/issues/65
## The date is in milliseconds since 1970, and that is > 2^31, which is
## largest R integer. SImilar to
## http://stackoverflow.com/questions/24688682/importing-sqlite-integer-column-which-is-231-1
## So I take some code for the cast and the idea of dividing and adding
## from the issue in github.

## Note that keywords are the same as mendeley-tags in bibtex

## ## some initial checks:
## dd <- dbReadTable(con, "Documents")
## nE <- nrow(dd)
## if(length(unique(dd$id)) != nE)
##     stop("Eh? multiple entries for same document?")

## if(length(unique(dd$citationKey)) != nE) {
##     warning("Repeated bibtex entries")
##     which(duplicated(dd$citationKey))
## }

## if(any(is.na(dd$citationKey))) {
##     warning("NA in bibtex entries")
##     which(is.na(dd$citationKey))
## }
## dn <-  dbReadTable(con, "DocumentNotes")
## nE <- nrow(dn)
## if(length(unique(dn$documentId)) != nE)
##     stop("Eh? multiple entries for same document in notes?")


minimalDBchecks(con)

bibtexDBConsistencyCheck(res, bib) ## to write this






res$timestamp <- as.character(format(round(as.POSIXct("1970-01-01",
                                                       tz="GMT+2") +
                                                           res$Ref_added/1000,
                                            "secs")))

## some extra checks
if(nrow(res) != length(unique(res$Ref_id)))
    stop("repeated Ref_Id")
if(length(unique(res$Ref_PDFNotes)) == 1)
    steop("unique PDFnotes")
if(length(unique(res$Ref_notes)) == 1)
    steop("unique notes")
if(length(unique(res$timestamp)) == 1)
    steop("unique timestamp")
if(length(unique(res$Ref_BibtexKey)) == 1)
    steop("unique bibtex key")



## Folders in Mendeley, collections in Zotero, groups in JabRef
## This is what they look like
## dbReadTable(con, "DocumentFolders")[1:10, ]
## dbReadTable(con, "DocumentFoldersBase")[1:10, ]
## dbReadTable(con, "Folders")[1:10, ] ## folder names

## Unclear what the difference is between DocumentFolders and
## DocumentFoldersBase. We use both, and then unique

df1 <- dbReadTable(con, "DocumentFolders")[, -3] ## remove "status" column
df2 <- dbReadTable(con, "DocumentFoldersBase")
folders <- rbind(df1, df2)
## Then use bibtex key and folder name.
folderDocuments <- by(folders, folders$folderId,
                      function(x) {unique(x$documentId)})

folderNames <- dbReadTable(con, "Folders")[, c(1, 3, 4)]
## parentId takes 0, -1, and then values that match those of other folder
## ids. No idea what is the differences between 0 and -1.

## There are probably better ways, but this works.  Actually, this should
## work with arbitrarily deep nesting. Not what follows below.


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




folderNames$depth <- computeFolderDepth(folderNames)




orderedFolderNames <- orderFolderNames(folderNames)




write(file = "jabref-groups.txt",
      outFolders(folderNames, folderDocuments, res))




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
