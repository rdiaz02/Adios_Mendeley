######################################################################
######################################################################
####                                                              ####
####        How this thing works                                  ####
####                                                              ####
######################################################################
######################################################################


## Input:
##    - MendeleySQL: the mendeley sqlite db (make a copy just in case)
##    - BibTexFile: the bibtex file that Mendeley produces.

## Before starting, remember to clean the trash of mendeley and then copy
## or link the sqlite file.


## Output
##   - out: a bibtex file that you can then import into Zotero

## Other things you need to specify and we assume:

##   - tmpFilePaths: a temporary holder for files. We rename many
##   files. This directory needs to exist. Files will be placed in there,
##   and Zotero will take files from there. After all is done, you can
##   remove it.




## Remember to empty the trash of mendeley
MendeleySQL <- "mend.sqlite"
BibTeXFile <- "library-fixed.bib"
out <- "new-library.bib" ## the new bibtex file that will be created
tmpFilePaths <- "/home/ramon/tmp/mend" ## A temporary directory for
                                       ## placing renamed files.

source("sqlite-bibtex-functions.R")


con <- dbConnect(SQLite(), MendeleySQL)
minimalDBchecks(con)
## Continue if things are ok

res <- dbGetQuery(con, sqliteQuery1) 
res$timestamp <- getTimestamp(res)
minimalDBDFchecks(res)


bibfile <- myBibtexReaderandCheck(BibTeXFile)
bibtexDBConsistencyCheck(res, bibfile)

## Continue if things are ok

## Add the extra information not exported by default by Mendeley
bibfile2 <- addInfoToBibTex(bibfile, res)

## Fix file names: nothing longer than maxlength and no spaces or special
## chars in in file names.
bibfileFileFixed <- fixFileNames(bibfile2, tmpFilePaths)


jabrefGr <- jabrefGroups(con, res)
## If you want to see what it looks like
## write(file = "jabref-groups.txt",
##       jabrefGr)


outFullBibTex(bibfileFileFixed, jabrefGr, out)

## You should have the bibtex file in the one you called out.  Go import
## that into Zotero. You might want to first import into JabRef and see
## what happens.

## After imported OK into Zotero, you might want to fix the dates. See
## general instructions in README.md.












