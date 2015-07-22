## An ugly kludge to place all PDF annotations (and highlight with the
## Ruby library) on an org-mode file.


leelaPath <- "~/Sources/Leela-master/leela"
pdfextractPath <- "~/Sources/extract.rb/5277732"
pdfDir <- "/home/ramon/Zotero-storage"

runRubyExtract <- TRUE ## might want to set it to FALSE as this is very slow


setwd("~/tmp")

list.of.pdfs <- system(paste0("find ", pdfDir, " -name '*.pdf'"), 
                       intern = TRUE)


leela_anot <- sapply(list.of.pdfs, function(x) {
    a0 <- ""
    a <- paste("* [[", x, "]]", sep = "")
    b <- system(paste0(leelaPath, ' annot \"',  x, '\"'),
                intern = TRUE)
    return(c(a0, a, b))
})

setwd(pdfextractPath)

## This is BAD! Calling this with each file. But I know no ruby. And this
## is extremely slow
if(runRubyExtract){
 pdfe_anot <- sapply(list.of.pdfs, function(x) {
    a0 <- ""
    a <- paste("* [[", x, "]]", sep = "")
    b <- system(paste0("ruby extract.rb ",  x),
                intern = TRUE)
    return(c(a0, a, b))
 } )
}


setwd("~/tmp")

write(file = "anot-leela.txt", unlist(leela_anot))

## remove more stuff, as I find it, or become annoyed by it
system("egrep -v '^<[0-9]+,[0-9]+:link>$' anot-leela.txt \\
        | egrep -v '^<[0-9]+,[0-9]+:highlight>$' \\
        | egrep -v '^<[0-9]+,[0-9]+:widget>Citation Link$' \\
        |  egrep -v '^<[0-9]+,[0-9]+:underline>$' >  \\
        ~/Zotero-data/storage/leela-annotations-in-PDFs-of-refs.org")
## It would be nice to remove those PDFs without any annotations. Some other time.


if(runRubyExtract) {
    write(file = "anot-pdfe.txt", unlist(pdfe_anot))
    system("mv anot-pdfe.txt ~/Zotero-data/storage/pdfe-annotations-in-PDFs-of-refs.org")
}


