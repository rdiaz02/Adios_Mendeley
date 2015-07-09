library(RSQLite)

con <- dbConnect(SQLite(), "mend.sqlite")


## Folders
dbReadTable(con, "DocumentFolders")[1:10, ]
dbReadTable(con, "DocumentFoldersBase")[1:10, ]
dbReadTable(con, "Folders")[1:10, ] ## folder names

## Do i need tgas? notes?

## I need data added

## - exporting from Mendeley the folders
##     - It is in the DocumentFolders and DocumentFoldersBase (for names)



## check the two books for hpbbm
