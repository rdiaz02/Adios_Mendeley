library(RSQLite)

con <- dbConnect(SQLite(), "mend.sqlite")
dbListTables(con)

## Folders
dbReadTable(con, "DocumentFolders")[1:10, ]
dbReadTable(con, "DocumentFoldersBase")[1:10, ]
dbReadTable(con, "Folders")[1:10, ] ## folder names

## Do i need tgas? notes?
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


res <- dbSendQuery(con, "select  cast(t as real) from data")

t <- as.numeric(dbFetch(res))


as.POSIXct("1970-01-01 00:00:00", tz="UTC") + t/1000
dbClearResult(res)
dbDisconnect(con)



res <- dbGetQuery(con, 'SELECT * FROM Documents LIMIT 5')


max.date <- max(dd$added)
min.date <- min(dd$added)

ad <- dd$added
mo <- dd$modified
mo[is.na(mo)] <- 0 ## ??

as.POSIXct(min.date + max.date, origin = "1970-01-01", tz = "GMT")

## last time a change? And this matches, kind of
as.POSIXct(min(dbReadTable(con, "EventLog")$timestamp), origin = "1970-01-01",
           tz = "GMT+2")

last.change <- min(dbReadTable(con, "EventLog")$timestamp)
last.change.posix <- as.POSIXct(last.change, origin = "1970-01-01",
                          tz = "GMT+2")

myDate <- function(x, min = min.date, last = last.change) {
    as.POSIXct(x + min + last, origin = "1970-01-01",
               tz = "GMT+2")
}


## I am unable to figure it out. So I use one I know, which is the first
## entry ever:
d1 <- min(dd$added)
o1 <- "2010-07-22"
myDate2 <- function(x, base = d1, origin = o1) {
    as.POSIXct(x + base, origin = origin,  tz = "GMT+2")
}



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


