leelaPath <- "~/Sources/Leela-master/leela"
pdfextractPath <- "~/Sources/extract.rb/5277732"
pdfDir <- "/home/ramon/Zotero-storage"


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
pdfe_anot <- sapply(list.of.pdfs, function(x) {
    a0 <- ""
    a <- paste("* [[", x, "]]", sep = "")
    b <- system(paste0("ruby extract.rb ",  x),
                intern = TRUE)
    return(c(a0, a, b))
})




write(file = "anot-leela.txt", unlist(leela_anot))
write(file = "anot-pdfe.txt", unlist(pdfe_anot))

setwd("~/tmp")
## remove more stuff, as I find it, or become annoyed by it
system("egrep -v '^<[0-9]+,[0-9]+:link>$' anot-leela.txt | egrep -v '^<[0-9]+,[0-9]+:highlight>$' | egrep -v '^<[0-9]+,[0-9]+:widget>Citation Link$' | egrep -v '^<[0-9]+,[0-9]+:underline>$' > ~/Zotero-data/storage/leela-annotations-in-PDFs-of-refs.org")
## system("egrep -v '^<[0-9]+,[0-9]+:link>$' anot-pdfe.txt | egrep -v '^<[0-9]+,[0-9]+:highlight>$' | egrep -v '^<[0-9]+,[0-9]+:widget>Citation Link$' | egrep -v '^<[0-9]+,[0-9]+:underline>$' > ~/Zotero-data/storage/leela-annotations-in-PDFs-of-refs.org")
system("mv anot-pdfe.txt ~/Zotero-data/storage/pdfe-annotations-in-PDFs-of-refs.org")

## It would be nice to remove those PDFs without any annotations. Some other time.

