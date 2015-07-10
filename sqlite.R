library(RSQLite)

con <- dbConnect(SQLite(), "mend.sqlite")
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

## some initial checks:
dd <- dbReadTable(con, "Documents")
nE <- nrow(dd)
if(length(unique(dd$id)) != nE)
    stop("Eh? multiple entries for same document?")

if(length(unique(dd$citationKey)) != nE) {
    warning("Repeated bibtex entries")
    which(duplicated(dd$citationKey))
}

if(any(is.na(dd$citationKey))) {
    warning("NA in bibtex entries")
    which(is.na(dd$citationKey))
}


dn <-  dbReadTable(con, "DocumentNotes")
nE <- nrow(dn)
if(length(unique(dn$documentId)) != nE)
    stop("Eh? multiple entries for same document in notes?")


res <- dbGetQuery(con, "
SELECT
Documents.id AS Ref_id,
Documents.citationKey AS Ref_BibtexKey,
cast(Documents.added as real) AS Ref_added,
DocumentNotes.text AS Ref_notes,
GROUP_CONCAT(FileNotes.note) AS Ref_PDFNotes
FROM Documents
LEFT OUTER JOIN FileNotes on FileNotes.documentId = Documents.id
LEFT OUTER JOIN DocumentNotes ON Documents.id = DocumentNotes.documentId
GROUP BY Documents.id"
                  )
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
folderNames$depth <- 0
folderNames$depth[folderNames$parentId %in% c(0, -1) ] <- 1
depthFolder <- function(id, df = folderNames) {
    ## In terms of id, because easier for error checking.
    pos <- which(df$id == id)
    parentId <- df[pos, "parentId"]
    if(parentId %in% c(0, -1) ) return(1)
    else {
        posParent <- which(df$id == parentId)
        return(df[posParent, "depth"] + 1)
    }
}
changesDepth <- TRUE
while(changesDepth) {
    formerDepth <- folderNames$depth
    folderNames$depth <- sapply(folderNames$id, depthFolder)
    if(all(formerDepth == folderNames$depth))
        changesDepth <- FALSE
}


## We need to output each folder and its children immediately below

## first, sort by depth

## until stable thing
##    for each with depth >= 2
##      start with depth == 2
##      locate its parent position: pi
##      place that element at pi + 1
##      shift index of all elements under pi by 1

folderNames <- folderNames[order(folderNames$depth), ]
originalFolderNames <- folderNames ## just in case

folderNames <- originalFolderNames
changesOrder <- TRUE
maybe.move <- folderNames$id[which(folderNames$depth >= 2)]

for(i in maybe.move) {
    i.element <- i
    pos.i <- which(folderNames$id == i.element)
    pi <- folderNames[pos.i, "parentId"]
    pos.pi <- which(folderNames$id == pi)
    new.df <- folderNames[1:pos.pi, ]
    new.df <- rbind(new.df, folderNames[pos.i, ])
    remaining <- folderNames[-pos.i, ] ## necessarily after the pi
    remaining <- remaining[-(1:pos.pi), ]
    new.df <- rbind(new.df, remaining)
    folderNames <- new.df
}

getBibTex <- function(docId, fullDoc) {
    fullDoc[fullDoc$Ref_id == docId, "Ref_BibtexKey"]
}

getBibtexRefsGroup <- function (folderId, folderInfo, fullDoc) {
    refIds <- folderInfo[[as.character(folderId)]]
    return(vapply(refIds, function(x) getBibTex(x, fullDoc), "a"))
}


eachFolder <- function(x, folderInfo = folderDocuments,
                       fullDoc = AllDocInfo) {
    ## This works by line, not id!!
    ## To be used with apply/lapply, etc
    first <- paste0(x$depth, " ExplicitGroup:",  x$name, "\\;0\\;")
    refs <- paste(getBibtexRefsGroup(x$id, folderInfo, fullDoc),
                  collapse = "\\;")
    return(paste0(first, refs, ";;"))
}


outFolders <- function(folders, folderInfo, fullDoc) {
    head <- "\n@comment{jabref-meta: groupsversion:3;}\n
@comment{jabref-meta: groupstree:\n0 AllEntriesGroup:;\n"
    lout <- vector(mode = "list", nrow(folders))
    ## lout <- lapply()
     for(ff in seq.int(nrow(folders))) {
         lout[ff] <- eachFolder(folders[ff, ],
                                folderInfo,
                                fullDoc)
     }
    lout <- paste(lout, collapse = "\n")
    return(paste0(head,
                 lout,
                 "\n}"))
}


write(file = "jabref-groups.txt",
      outFolders(folderNames, folderDocuments, res))













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
