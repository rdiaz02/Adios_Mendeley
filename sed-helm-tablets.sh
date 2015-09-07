#!/bin/bash

## Or pass the dir as argument, or whatever
ZOTDIR="/home/ramon/Zotero-data/storage"

sed -e '/file = {/{
    s/{[^/:]*:/{ /
    s/:[^/:}]*\/[^/:}]*}/ }/
    s/:[^/:]*\/[^/:]*;/ /g
    s/ [^/:]*:/ /g
}' $ZOTDIR/zotero-$HOSTNAME.bib > $ZOTDIR/helm.bib




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
}' $ZOTDIR/zotero-$HOSTNAME.bib > $ZOTDIR/tablet-erathostenes.bib


## For helm we do not need the jabref group structure
sed -i -n '/@comment{jabref-meta: groupsversion:3;}/q;p' $ZOTDIR/helm.bib


## In the tablet, Library uses the same file as Refmaster. Library can
## deal with multiple attached files per entry. With RefMaster you can
## only use one file. It uses relative paths
sed -e '/file = {/{
    s/\/home\/ramon\/Zotero-data\/storage//g 
}' $ZOTDIR/zotero-$HOSTNAME.bib > $ZOTDIR/tablet-refmaster.bib
## And remove jabref groups
sed -i -n '/@comment{jabref-meta: groupsversion:3;}/q;p' $ZOTDIR/tablet-refmaster.bib




