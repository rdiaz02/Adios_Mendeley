library(RSQLite)


sqliteQuery1 <- "
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


minimalDBchecks <- function(con) {
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


