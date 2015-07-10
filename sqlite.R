library(RSQLite)

con <- dbConnect(SQLite(), "mend.sqlite")
dbListTables(con)

## All the tables
tables <- dbListTables(con)
sapply(tables, function(x) dbListFields(con, x))





## Do i need tasg? notes?
## tags in DocumentTags?

## Notes in the PDF
dbReadTable(con, "FileNotes")[1:10, ] ## notes
## fields note and baseNote are identical


## Notes in the entry itself
cucu <- dbReadTable(con, "DocumentNotes")
## use the text field

## I need date added

dbListFields(con, "Documents")
## yes, it is the added field, but R seems to screw up reading it or something
## see similar issue here http://stackoverflow.com/questions/24688682/importing-sqlite-integer-column-which-is-231-1
## https://github.com/rstats-db/RSQLite/issues/65
### Note workaround
## library(RSQLite)
## drv <- dbDriver("SQLite")
## con <- dbConnect(drv, dbname="test.db")
## res <- dbSendQuery(con, "select cast(t as real) from data")
## t <- as.numeric(dbFetch(res))
## as.POSIXct("1970-01-01 00:00:00", tz="UTC") + t/1000
## dbClearResult(res)
## dbDisconnect(con)

dd <- dbReadTable(con, "Documents")

res7 <- dbGetQuery(con, "
SELECT
Documents.id AS Ref_id,
cast(Documents.added as real) AS Ref_added,
DocumentNotes.text AS Ref_notes
FROM
Documents
LEFT OUTER JOIN DocumentNotes ON Documents.id = DocumentNotes.documentId 
")
dim(res7); names(res7)


as.character(format(round(as.POSIXct("1970-01-01", tz="GMT+2") + res7$Ref_added/1000,  "secs")))[1]




## The added field is weird because it it has a non-monotonic
## correspondence to the date of addition of a document. I know because
## largest and smallest values are not those from the first and last
## documents added.


## DocumentCanonicalIds has some date info, but not clear to me what.

## all the tables
tables <- dbListTables(con)
sapply(tables, function(x) dbListFields(con, x))


## - exporting from Mendeley the folders
##     - It is in the DocumentFolders and DocumentFoldersBase (for names)



## check the two books for hpbbm







## Folders in Mendeley, collections in Zotero, groups in JabRef
## This is what they look like
dbReadTable(con, "DocumentFolders")[1:10, ]
dbReadTable(con, "DocumentFoldersBase")[1:10, ]
dbReadTable(con, "Folders")[1:10, ] ## folder names
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
    fullDoc[fullDoc$Ref_id == docId, "Ref_Bibtex"]
}

getBibtexRefsGroup <- function (folderId, folderInfo, fullDoc) {
    refIds <- folderInfo[[folderId]]
    return(vapply(refIds, function(x) getBibTex(x, fullDoc)))
}

eachFolder <- function(x, folderInfo = folderDocuments,
                       fullDoc = AllDocInfo) {
    ## This works by line, not id!!
    ## To be used with apply/lapply, etc
    first <- paste0(x$depth, " ExplicitGroup:",
                x$name, "\;0\;")
    refs <- getBibtexRefsGroup(x$id, folderInfo, fullDoc)
    return(paste0(first, refs, ";"))
}


outFolders <- function(folders) {
    head <- "\n@comment{jabref-meta: groupsversion:3;}\n\n
@comment{jabref-meta: groupstree:\n0 AllEntriesGroup:;"
    lout <- vector(mode = "list", nrow(folders))
    ## lout <- lapply()
     for(ff in seq.int(nrow(folders))) {
         lout[ff] <- eachFolder(folder)
         a <- folders[ff, ]
     }
}


## Output will be:

## digit of level







