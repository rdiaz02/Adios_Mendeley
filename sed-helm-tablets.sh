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
##  exact jabref format.
sed -e '/file = {/{
    s/\/home\/ramon\/Zotero-data\/storage/\/sdcard\/Zotero-storage/g 
}' $ZOTDIR/helm.bib > $ZOTDIR/tablet-erathostenes.bib


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




