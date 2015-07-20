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

##   - rootFileDir: we assume all your PDFs (or ps, or tar.gz ---any file
##   associated with an entry) live in directories as follows:
##         /rootFileDir/some_other_directory/file_name.pdf

##   where the some_other_directory is generally the name of the entry or
##   similar.  The name is not very relevant. What matters here is that I
##   assume that there is exactly one directory between the name of the
##   file and the rootFileDir. This of course need not be so. It is the
##   way I have things organized, and the code expects that. Change at
##   will. (Search for functions that use 'rootFileDir')

##   - tmpFilePaths: a temporary holder for files. We rename many
##   files. This directory needs to exist. Files will be placed in there,
##   and Zotero will take files from there. After all is done, you can
##   remove it.




## Remember to empty the trash of mendeley
MendeleySQL <- "mend.sqlite"
BibTeXFile <- "library-fixed.bib"
out <- "new-library.bib" ## the new bibtex file that will be created
rootFileDir <- "/home/ramon/Mendeley-pdfs" ## The Mendeley pdfs hang from here.
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

checkFileDirNesting(bibfile, rootFileDir, numdirs = 1)
## Continue if things are ok

## Add the extra information not exported by default by Mendeley
bibfile2 <- addInfoToBibTex(bibfile, res)

## Fix file names: nothing longer than 20 chars and no spaces in file names.
bibfileFileFixed <- fixFileNames(bibfile2, rootFileDir, tmpFilePaths)



jabrefGr <- jabrefGroups(con, res)
## If you want to see what it looks like
## write(file = "jabref-groups.txt",
##       jabrefGr)


outFullBibTex(bibfileFileFixed, jabrefGr, out)


## You should have the bibtex file in the one you called out.  Go import
## that into Zotero. You might want to first import into JabRef and see
## what happens.













