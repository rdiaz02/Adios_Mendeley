computeFolderDepth <- function(folderNames) {
    depth <- 0
    depth[folderNames$parentId %in% c(0, -1) ] <- 1
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

getBibKey <- function(x) {
    strsplit(strsplit(x, "{",
                      fixed = TRUE)[[1]][2], ",", fixed = TRUE)[[1]][1]
    ## do something
}

myBibtexReader <- function(file) {
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
