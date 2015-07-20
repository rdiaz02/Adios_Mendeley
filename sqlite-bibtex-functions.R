library(RSQLite)


## Documents: date added, notes, and bibtexkey.
## Mendeley should export the notes in the "annote" filed but it doesn't
## always, specially if you have newlines. It is a known bug.

## For the cast thing, see: https://github.com/rstats-db/RSQLite/issues/65
## The date is in milliseconds since 1970, and that is > 2^31, which is
## largest R integer. SImilar to
## http://stackoverflow.com/questions/24688682/importing-sqlite-integer-column-which-is-231-1
## So I take some code for the cast and the idea of dividing and adding
## from the issue in github.


sqliteQuery1 <- "
SELECT
Documents.id AS mendid,
Documents.citationKey AS Ref_BibtexKey,
cast(Documents.added as real) AS Ref_added,
DocumentNotes.text AS mendnotes,
GROUP_CONCAT(FileNotes.note) AS mendpdfnotes
FROM Documents
LEFT OUTER JOIN FileNotes on FileNotes.documentId = Documents.id
LEFT OUTER JOIN DocumentNotes ON Documents.id = DocumentNotes.documentId
GROUP BY Documents.id"

getTimestamp <- function(dbdf) {
    as.character(format(round(as.POSIXct("1970-01-01",
                                         tz="GMT+2") +
                                             dbdf$Ref_added/1000,
                              "secs")))
}

minimalDBchecks <- function(con) {
    dd <- dbReadTable(con, "Documents")
    nE <- nrow(dd)
    if(length(unique(dd$id)) != nE)
        stop("Eh? multiple entries for same document?")
    if(length(unique(dd$citationKey)) != nE) {
        warning("Repeated bibtex entries")
        cat("\n\nRepeated bibtex entries\n")
        print(dd[which(duplicated(dd$citationKey)), "title"])
        cat("\n\n")
    }
    if(any(is.na(dd$citationKey))) {
        warning("NA in bibtex entries")
        cat("\n\nNA in bibtex entries\n")
        print(dd[which(is.na(dd$citationKey)), "title"])
        cat("\n\n")
    }
    dn <-  dbReadTable(con, "DocumentNotes")
    nE <- nrow(dn)
    if(length(unique(dn$documentId)) != nE)
        stop("Eh? multiple entries for same document in notes?")
}

minimalDBDFchecks <- function(dbdf) {
    ## some extra checks
    if(nrow(dbdf) != length(unique(dbdf$mendid)))
        stop("repeated Mendeley Id")
    if(length(unique(dbdf$mendpdfnotes)) == 1)
        stop("unique PDFnotes")
    if(length(unique(dbdf$mendnotes)) == 1)
        stop("unique notes")
    if(length(unique(dbdf$timestamp)) == 1)
        stop("unique timestamp")
    if(length(unique(dbdf$Ref_BibtexKey)) == 1)
        stop("unique bibtex key")
}



## Folders in Mendeley, collections in Zotero, groups in JabRef
## This is what they look like
## dbReadTable(con, "DocumentFolders")[1:10, ]
## dbReadTable(con, "DocumentFoldersBase")[1:10, ]
## dbReadTable(con, "Folders")[1:10, ] ## folder names

## Unclear what the difference is between DocumentFolders and
## DocumentFoldersBase. We use both, and then unique

foldersDBread <- function(con) {
    ## Returns a data frame with documentId and folderId
    df1 <- dbReadTable(con, "DocumentFolders")[, -3] ## remove "status" column
    df2 <- dbReadTable(con, "DocumentFoldersBase")
    folders <- rbind(df1, df2)
    return(folders)
}



## parentId takes 0, -1, and then values that match those of other folder
## ids. No idea what is the differences between 0 and -1.

## There are probably better ways, but this works.  Actually, this should
## work with arbitrarily deep nesting. 

computeFolderDepth <- function(folderNames) {
    depth <- rep(0, nrow(folderNames))
    depth[folderNames$parentId %in% c(0, -1) ] <- 1

    depthFolder <- function(id, prevdepth = depth, df = folderNames) {
        ## In terms of id, because easier for error checking.
        pos <- which(df$id == id)
        parentId <- df[pos, "parentId"]
        if(parentId %in% c(0, -1) ) return(1)
        else {
            posParent <- which(df$id == parentId)
            return(prevdepth[posParent] + 1)
##            return(df[posParent, "depth"] + 1)
        }
    }
    changesDepth <- TRUE
    while(changesDepth) {
        formerDepth <- depth
        depth <- sapply(folderNames$id, depthFolder)
        if(all(formerDepth == depth))
            changesDepth <- FALSE
    }
    return(depth)
}

orderFolderNames <- function(folderNames) {
    ## We need to output each folder and its children immediately below
    ## changesOrder <- TRUE
    folderNames <- folderNames[order(folderNames$depth), ]
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
    return(folderNames)
}

getBibTex <- function(docId, fullDoc) {
    fullDoc[fullDoc$mendid == docId, "Ref_BibtexKey"]
}

getBibtexRefsGroup <- function (folderId, folderInfo, fullDoc) {
    refIds <- folderInfo[[as.character(folderId)]]
    return(vapply(refIds, function(x) getBibTex(x, fullDoc), "a"))
}


eachFolderOut <- function(x, folderInfo = folderDocuments,
                          fullDoc = AllDocInfo) {
    ## Give each line for a folder/group/collection.
    ## The fullDoc object is needed because we need to get the bibtexkey.
    ## This works by line, not id!!
    ## To be used with apply/lapply, etc
    first <- paste0(x$depth, " ExplicitGroup:",  x$name, "\\;0\\;")
    refs <- paste(getBibtexRefsGroup(x$id, folderInfo, fullDoc),
                  collapse = "\\;")
    return(paste0(first, refs, "\\;;"))
}

## like jabrefGroups, but without taking con
## outFolders <- function(folders, folderInfo, fullDoc) {
##     head <- "\n@comment{jabref-meta: groupsversion:3;}\n
## @comment{jabref-meta: groupstree:\n0 AllEntriesGroup:;\n"
##     lout <- vector(mode = "list", nrow(folders))
##     ## lout <- lapply()
##      for(ff in seq.int(nrow(folders))) {
##          lout[ff] <- eachFolderOut(folders[ff, ],
##                                    folderInfo,
##                                    fullDoc)
##      }
##     lout <- paste(lout, collapse = "\n")
##     return(paste0(head,
##                  lout,
##                  "\n}"))
## }

getBibKey <- function(x) {
    bibk <- strsplit(strsplit(x, "{",
                              fixed = TRUE)[[1]][2], ",", fixed = TRUE)[[1]][1]
    if(grepl(";", bibk, fixed = TRUE)) {
        cat("You have a ';' in a bibtex key. Expect problems in jabref groups. ")
        cat("The offending entry is ", bibk, "\n")
        warning("You have a ';' in a bibtex key. Expect problems in jabref groups")
    }
    if(grepl("[^a-zA-Z0-9:_-]", bibk)) {
        cat("A character not in [a-zA-Z0-9:_-] in the bibkey.  ")
        cat("Change it? The entry is ", bibk, "\n")
        warning("A character not in [a-zA-Z0-9:_-] in the bibkey.  ")
    }
    return(bibk)
}

myBibtexReaderandCheck <- function(file) {
    cat("\n Starting readLines for bibtex file\n")
    x <- readLines(con = file)
    cat("\n Done with  readLines for bibtex file\n")
    startEntry <- "^@"
    endEntry <- "^}$"
    starts <- grep(startEntry, x)
    ends <- grep(endEntry, x)
    if(length(starts) != length(ends))
        stop("length of starts and ends differ")
    if(!all(starts < ends))
        stop("starts !< ends")
    out <- vector(mode = "list", length = length(starts))
    names <- vector(mode = "character", length = length(starts))
    for(i in seq.int(length(starts))) {
        out[[i]] <- x[starts[i]:ends[i]]
        names[i] <- getBibKey(x[starts[i]])
    }
    names(out) <- names
    return(out)
}

bibtexDBConsistencyCheck <- function(res, bib) {
    ## Check same bibtex entries in bibtex file and the mendely db
    if(length(bib) != nrow(res))
        stop("Different number of entries")
    sb <- sort(names(bib))
    sr <- sort(res$Ref_BibtexKey)
    if(!identical(sb, sr))
        stop("At least one key is different")
}



getFolderInfo <- function(con) {

    ## folder Id, name as a string, and the parentId
    folderNames <- dbReadTable(con, "Folders")[, c(1, 3, 4)]
    ## documentID and folderId
    folders <- foldersDBread(con)
    ## Single line for each folderId with all contained documentIDs
    folderDocuments <- by(folders, folders$folderId,
                      function(x) {unique(x$documentId)})

    ## order the folderNames info: each folder and its children
    ## immediately below
    folderNames$depth <- computeFolderDepth(folderNames)
    folderNames <- orderFolderNames(folderNames)

    return(allFolderInfo = list(
               folderNames = folderNames,
               folderDocuments = folderDocuments
    ))
}



jabrefGroups <- function(con, res) {
    ## Return the strings to add to the end of the bibtex file with the
    ## JabRef group info.
    fi <- getFolderInfo(con)
    head <- "\n@comment{jabref-meta: groupsversion:3;}\n
@comment{jabref-meta: groupstree:\n0 AllEntriesGroup:;\n"
    lout <- vector(mode = "list", nrow(fi$folderNames))
    ## lout <- lapply()
     for(ff in seq.int(nrow(fi$folderNames))) {
         lout[ff] <- eachFolderOut(fi$folderNames[ff, ],
                                   fi$folderDocuments,
                                   res)
     }
    lout <- paste(lout, collapse = "\n")
    return(paste0(head,
                 lout,
                 "\n}"))
    
}


newBibItems <- function(x) {
    ## Take a named vector, and return a vector of strings, as new bibtex
    ## entries.
    lx <- length(x)
    out <- vector(mode = "character", length = lx)
    for(i in seq.int(lx)) {
        u <- x[i]
        out[i] <- paste0(names(u), " = ", "{", u, "},")
    }
    return(out)
}


getAField <- function(x, field) {
    return(grep(paste0("^", field, " = \\{"), x))
}


## checkSameKeywordsMendtags <- function(x) {
##     kwd <- gsub("^keywords", "", x[getAField(x, "keywords")])
##     mt <- gsub("^mendeley-tags", "", x[getAField(x, "mendeley-tags")])
##     if(length(kwd) && length(mt)) {
##         if(kwd != mt) {
##             stop("Keyword != mendeley-tags in ", x[1])
##         }
##     }
##     if(length(mt) && !length(kwd))
##         stop("kwd no length in", x[1])
## }

## checkAnnoteInMendnote <- function(x) {
##     an <- gsub("^annote", "", x[getAField(x, "annote")])
##     mn <- gsub("^mendnotes", "", x[getAField(x, "mendnotes")])
##     if(length(an) && !length(mn)) {
##         stop("an but not mn in ", x[1])
##     }
##     if(length(an) && length(mn)) {
##         if(! (an %in% mn )) {
##             stop("annote not all in mendnote in ", x[1])
##         }
##     }
## }

renameField <- function(x, oldname, newname) {
    pos <- getAField(x, oldname)
    x[pos] <- gsub(paste0("^", oldname, " = \\{"),
                   paste0(newname, " = \\{"),
                   x[pos])
    return(x)
}


combineFields <- function(x, field1, field2) {
    ## place info of fields1 and field2 in a single field1, and remove
    ## field2
    pf1 <- getAField(x, field1)
    pf2 <- getAField(x, field2)
    f1 <- gsub(paste0("^", field1, " = \\{"), "", x[pf1])
    f2 <- gsub(paste0("^", field2, " = \\{"), "", x[pf2])

    f1 <- gsub("\\},$", "", f1)
    f2 <- gsub("\\},$", "", f2)

    f1 <- gsub("\\}$", "", f1)
    f2 <- gsub("\\}$", "", f2)

    if(!identical(f1, f2)) {
        f1 <- c(f1, f2)        
    } 
    newx <- x[-pf2]
    newx[pf1] <- paste0(field1, " = \\{", f1, "\\},")
    return(newx)
}


## more complicated, and do the right way:
## parse by words (split by commas), create single list, and spit that out

addInfoToBibEntry <- function(x, y) {
    ## x is the list entry
    ll <- length(x)
    if(ll <  3)
        stop("This entry must be wrong")
    lastitem <- x[ll]
    lnew <- y[c("mendid", "timestamp", "mendnotes", "mendpdfnotes")]
    lnew <- lnew[which(!is.na(lnew))] ## I want the names of the vector
    ## Simpler if I leave until the end the one before last, because of
    ## the comma
    newx <- c(x[1:(ll - 2)],
              newBibItems(lnew),
              x[c(ll-1, ll)])
    newx <- combineFields(newx, "annote", "mendnotes")
    newx <- combineFields(newx, "keywords", "mendeley-tags")
    ## checkSameKeywordsMendtags(newx)
    ## checkAnnoteInMendnote(newx)
    ## ## Remove redundant fields
    ## newx <- newx[-getAField(newx, "mendeley-tags")]
    ## newx <- newx[-getAField(newx, "annote")]
    ## newx <- renameField(newx, "mendnotes", "annote")
    return(newx)
}


addInfoToBibTex <- function(bib, db) {
    pm <- match(names(bib), db$Ref_BibtexKey)
    if(any(is.na(pm)))
        stop("NAs in the match")
    if(length(pm) != nrow(db))
        stop("length match relative to db")
    if(length(pm) != length(bib))
        stop("length match relative to bib")
    if(any(duplicated(pm)))
        stop("duplicated matches")
    
    db <- db[pm, ]
    
    ll <- length(bib)
    for(i in seq.int(ll)) {
        bib[[i]] <- addInfoToBibEntry(bib[[i]], db[i, ])
    }
    return(bib)
}




outFullBibTex <- function(bib, jabrefgr, outfile) {
    x1 <- paste0(
        paste(lapply(bib,
                     function(x) paste(x, collapse = "\n")),
              collapse = "\n"),
        "\n\n",
        jabrefgr)
    write(file = outfile, x1)
}



## Yes, getting them this way a lot simpler than via the "Files" table
getFilesBib <- function(x) {
    ## x is each list entry, so a full bibtex entry
    ## We need to:
    ##  - get the list of files
    ##  - really get just the path:
    ##        - remove the file and {} stuff
    ##        - remove the :filetype stuff
    
    fpos <- grep("^file = \\{", x)
    ff <- x[fpos]
    if(length(fpos) == 0)
        return(list(files = NULL, filepos = fpos))
    
    strs.remove <- c("file = {", "},")
    for(cc in strs.remove)
        ff <- gsub(cc, "", ff, fixed = TRUE)
    
    files <- strsplit(ff, ";")[[1]]
    files <- vapply(files, function(x) gsub("^:", "/", x), "a")
    files <- vapply(files, function(x) strsplit(x, ":")[[1]][1], "a")
    return(list(files = files, filepos = fpos))
}



innerCheckDirNesting <- function(x, i,  rootFileDir, num.dirs = 1) {
    ## Make sure all exactly one directory
    if(is.null(x))
        return(TRUE)
    y <- strsplit(x, rootFileDir)[[1]][2]
    numd <- length(grep("/", strsplit(y, '')[[1]], value = FALSE)) - 1
    if(num.dirs != numd) {
        cat("\n Here, at i = ", i, "\n")
        cat(y)
        cat("and this is x ", x)
        warning("not expected number of directories. Fix before continuing")
        return(FALSE)
    } else {
        return(TRUE)
    }
}

checkFileDirNesting <- function(bib, rootFileDir, numdirs = 1) {
    ## numdirs is the number of directories between the rootFileDir and
    ## the file.

    ## Yes, we go through same data several times, but checking this is a
    ## distinct operation.
    thefiles <- lapply(bib, function(x) getFilesBib(x)$files)
    ## yes, loop so as to give the exact place where it fails
    out <- rep(TRUE, length(thefiles))
    for(i in seq.int(length(thefiles)))
        out[i] <- innerCheckDirNesting(thefiles[[i]], i, rootFileDir, numdirs)
    if(!all(out))
        stop("checkFileDirNesting failed")
}

justTheFile <- function(x, rootFileDir) {
    ## This will fail if more than one level of nesting in files. I assume
    ## the directory with the files hangs directly from rootFileDir.
    strsplit(strsplit(x, rootFileDir)[[1]][2], "/")[[1]][3]
}

newFname <- function(bibtexkey, oldfilename, tmpdir, ranletters) {
    extension <- getFileExtension(oldfilename)
    nn <- paste0(bibtexkey, "-",
                 paste(paste(sample(letters, ranletters,
                                    replace = TRUE)),
                       collapse = ""))
    nn <- paste0(tmpdir, "/", nn)
    if(extension != "")
        return(paste0(nn, ".", extension))
    else
        return(nn)
}

createNewFileField <- function(files, extensions) {
    if(length(files) != length(extensions))
        stop("lengths file != extensions")
    head <- "file = {"
    fs <- paste0(":", files)
    exts <- paste0(":", extensions)
    allfiles <- paste0(paste0(fs, exts), collapse = ";")
    return(paste0(head, allfiles, "}"))
}


getFileExtension <- function(x) {
    ## x is just the file name, without paths
    extension <- ""
    if(grepl("\\.tar\\.gz", x)) {
        extension <- "tar.gz"
    } else if(grepl("\\.tar\\.bz2", x)) {
        extension <- "tar.bz2"
    } else {
        fsp <- strsplit(x, "\\.")[[1]]
        if(length(fsp) > 1)
            extension <- fsp[length(fsp)]
    }
    return(extension)
}

## gsubTheCrap <- function(x) {
##     ## This is a good example of the kinds of things that Mendeley makes
##     ## possible, and shouldn't
##     x <- gsub(" ", "\\ ", x, fixed = TRUE)
##     x <- gsub("(", "\\(", x, fixed = TRUE)
##     x <- gsub(")", "\\)", x, fixed = TRUE)
##     x <- gsub("'", "\\'", x, fixed = TRUE)
##     x <- gsub("&", "\\&", x, fixed = TRUE)
##     return(x)
## }




fixFilesSingleEntry <- function(bibentry, rootFileDir,
                                tmpFilePaths, ranletters = 8,
                                maxlength = 40) {
    ## Returns the new entry with file names fixed, or same as input if
    ## nothing changed.

    ## What is fixing? That no file name be longer than maxlength
    ## (actually, final name can be up to bibkey + ranletters) and that it
    ## contains only a-Z, 0-9, _, . So nothing like ?&:, etc and no
    ## spaces either. And not _, as that can mess things up later.
    
    bibkey <- getBibKey(bibentry[1])

    filesp <- getFilesBib(bibentry)
    newf <- FALSE

    if(!is.null(filesp$files)) {
        newf <- FALSE
        ## trouble for creating new files
        ## tmpdir <- paste0(tmpFilePaths, "/",
        ##                  paste(sample(letters, 8, replace = TRUE),
        ##                        collapse = ""))
        tmpdir <- tmpFilePaths
        for(nfile in seq_along(filesp$files)) {
            f1 <- justTheFile(filesp$files[nfile], rootFileDir)
            ## We must make sure the stupid spaces from directory names do
            ## not screw things up.

            ## No longer gsub and replacing by escaped chars, as we now
            ## quote the path. But need to fix the \\& and \\_ that
            ## Mendeley inserted
            oldpath <- gsub("\\&", "&", filesp$files[nfile], fixed = TRUE)
            oldpath <- gsub("\\_", "_", oldpath, fixed = TRUE)
            ## oldpath <- gsubTheCrap(filesp$files[nfile])
            
            if( (nchar(f1) > maxlength) || grepl("[^a-zA-Z0-9.-]", f1) ) {
                filesp$files[nfile] <- newFname(bibkey, f1,
                                                tmpdir,
                                                ranletters)
                newf <- TRUE
                ## I can't use file.copy as the spaces and what not can
                ## screw things up. And I can't use system2 either, for
                ## some reason I just don't follow but cannot pursue. This
                ## whole spaces thing really sucks.
                cmd <- system(paste("cp", shQuote(oldpath), 
                       filesp$files[nfile]), intern = FALSE)
                ## cmd <- system(paste("cp ", oldpath, " ",
                ##                     filesp$files[nfile]), intern = FALSE)
                if(cmd) {
                    cat("\n Copying file failed for ", oldpath)
                    warning("\n Copying file failed for ", oldpath)
                }
            } ## else if(grepl("[^a-zA-Z0-9._-]", f1)) {
              ##   ## remove any weird characters
              ##   filesp$files[nfile] <- newFname(bibkeys[i], f1,
              ##                                   tmpdir, ranletters)
              ##   newf <- TRUE
              ##   cmd <- system(paste0("cp", " \'", oldpath, "\' ",
              ##          filesp$files[nfile]), intern = FALSE)
              ##   if(cmd) {
              ##       cat("\n Copying file failed for ", oldpath)
              ##       warning("\n Copying file failed for ", oldpath)
              ##   }
            ## }
        }
        if(newf) {
            ## We need the extensions of all, included those not changed.
            exts <- vapply(filesp$files, getFileExtension, "a")
            newFileField <- createNewFileField(filesp$files, exts)
            newBibEntry <- bibentry
            ## If not last field, needs a comma
            if(filesp$filepos != (length(bibentry) - 1))
                newFileField <- paste0(newFileField, ",")
            newBibEntry[filesp$filepos] <- newFileField
            return(newBibEntry)
        }
    }
    return(bibentry)
}

fixFileNames <- function(bibfile, rootFileDir,
                         tmpFilePaths, ranletters = 8,
                         maxlength = 40) {
    ## Returns a new bibfile with file names "fixed"
    return(lapply(bibfile, function(x)
        fixFilesSingleEntry(x, rootFileDir, tmpFilePaths,
                            ranletters, maxlength)))
}





## ## some examples
## bibfile[[1961]][]

## bibfile[[801]][5]
## bibfile[[1128]][4]
## bibfile[[255]][5]
## bibfile[[2205]][6] ## two levels of dir nesting



## minibib <- bibfile[c(2, 3, 801, 1128, 255, 1962)]
## minibib2 <- fixFileNames(minibib, rootFileDir, tmpFilePaths)
## outFullBibTex(minibib2, jabrefGr, out)


## fixFilesSingleEntry(bibfile[[1]], rootFileDir, tmpFilePaths)


## dbListTables(con)

## ## All the tables
## tables <- dbListTables(con)
## sapply(tables, function(x) dbListFields(con, x))

## df <- dbReadTable(con, "Files")


## - exporting from Mendeley the folders
##     - It is in the DocumentFolders and DocumentFoldersBase (for names)


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




## Miscell stuff
## Notes in the PDF
## dbReadTable(con, "FileNotes")[1:10, ] ## notes fields note and baseNote
## ## are identical But those I already have in the PDF. Since easy and
## ## cheap, make sure I have all.

## ## Notes in the entry itself
## dbReadTable(con, "DocumentNotes")
## ## use the text field

## ## I need date added

## dbListFields(con, "Documents")



## dd <- dbReadTable(con, "Documents")




## library(RefManageR)
## library(bibtex)



## bibfile <- read.bib(file = BibTeXFile) ## Nope: ignores incomplete entries
## bibfile <- ReadBib(file = BibTeXFile, check = FALSE): Drops fields I care about



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







