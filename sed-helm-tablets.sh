#!/bin/bash


## For helm-bibtex I want the export from the Better BibTex. For the
## tablets the bibtex key is irrelevant. But the plain Zotero bibtex
## export takes seconds, whereas the one from better bibtex can take 9 to
## 10 minutes.

## Thus, I use zotero auto export (http://rokdd.de/b/zotero-autoexport) to
## export the plain bib every hour.


OUT=$1

## Or pass the dir as argument, or whatever
ZOTDIR="/home/ramon/Zotero-data/storage"


if [[ $OUT == "helm" ]]; then
    sed -e '/file = {/{
    s/{[^/:]*:/{ /
    s/:[^/:}]*\/[^/:}]*}/ }/
    s/:[^/:]*\/[^/:]*;/ /g
    s/ [^/:]*:/ /g
}' $ZOTDIR/zotero-$HOSTNAME.bib > $ZOTDIR/helm.bib

    ## For helm we do not need the jabref group structure
    sed -i -n '/@comment{jabref-meta: groupsversion:3;}/q;p' $ZOTDIR/helm.bib
fi

if [[ $OUT == "tablet" ]]; then

    ##  Erathostenes had a bug and crashed with groups. Is it fixed now? We
    ##  keep them for now. Note that Erathostenes can use paths without the
    ##  exact jabref format. For info about paths see this issue:
    ##  https://bitbucket.org/mkmatlock/eratosthenes/issues/206/attachment-location
    ##  so it seems we want to remove all the path, except what hangs from the common
    ##  location of bib and files.

    # sed -e '/file = {/{
    #      s/\/home\/ramon\/Zotero-data\/storage//g 
    # }' $ZOTDIR/helm.bib > $ZOTDIR/tablet-erathostenes.bib


    # sed -e '/file = {/{
    #     s/\/home\/ramon\/Zotero-data\/storage/\/sdcard\/Zotero-storage/g 
    # }' $ZOTDIR/helm.bib > $ZOTDIR/tablet-erathostenes.bib

    # This is a larger file. Not sure I want all the extra stuff.
    sed -e '/file = {/{
    s/\/home\/ramon\/Zotero-data\/storage//g 
}' $ZOTDIR/zotero-$HOSTNAME-plain-bib.bib > $ZOTDIR/tablet-erathostenes.bib




    ## In the tablet, Library uses the same file as Refmaster. Library can
    ## deal with multiple attached files per entry. With RefMaster you can
    ## only use one file. It uses relative paths
    sed -e '/file = {/{
    s/\/home\/ramon\/Zotero-data\/storage//g 
}' $ZOTDIR/zotero-$HOSTNAME-plain-bib.bib > $ZOTDIR/tablet-refmaster.bib
    ## And remove jabref groups
    sed -i -n '/@comment{jabref-meta: groupsversion:3;}/q;p' $ZOTDIR/tablet-refmaster.bib

fi



## Now, for using entr and automatic processing use something like this in .xsession or similar:
## ls ~/Zotero-data/storage/zotero-$HOSTNAME.bib | entr ~/Adios_Mendeley/sed-helm-tablets.sh helm &
## ls ~/Zotero-data/storage/zotero-$HOSTNAME-plain-bib.bib | entr ~/Adios_Mendeley/sed-helm-tablets.sh tablet &
