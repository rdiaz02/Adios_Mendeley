
Why move:
- Does not check for duplicated bibtex citation keys and will not generate
  bibtex entry if you do not have author, date entries. This sucks, as for
  me the place I look for stuff is the bibtex file (much faster
  searching).

- Mendeley has cluttered interface, compared to zotero.
- Zotero: much faster searches
- My troubles: http://support.mendeley.com/customer/en/portal/questions/12997701-restore-from-a-local-backup?new=12997701

- Sorting files into subfolders: who thought it was a good idea to use
  spaces in the "folder" (directory) name?

- In general, it is easy to shoot yourself in the foot.

- Keyboard shortcuts: few, and where are they documented? Unavoidable to
  use/abuse the mouse.

- No BibTeX export if no author/year (i.e., no key)

- Inflexible what fields you are shown (some you cannot uncheck, which
  sucks with long abstracts)

- Persisten errors in entries, like adding links to file that you
  have removed which results in the broken link in mendeley and paths to
  inexistent files in the bibtex file.

- No export of bibtex entry if no key.

- spaces and ' and & and ... in file and directory names.

- very long file and directory names.



Why through Bibtex:
- Because you can incorporate loads of additional information, including
  the Mendely folders the tags, etc.
- Because to me it is much simpler than trying to directly manipulate the
  Zotero sqlite database.


Several pieces:
- Get the tags, date added, etc from the Mendeley sqlite database. This is
  basically just a little bit of sqlite code, but I call it from R using
  RSQLite.
- Get the information about the folders (Mendeley jargon), groups (JabRef
  jargon), collections (Zotero jardon) from the Mendeley database and
  produce output in a format compatible with JabRef, because the Zoter
  importer of bibtex files understands JabRef's groups [zz](zz).
  https://github.com/ZotPlus/zotero-better-bibtex/issues/97






Notes and warnings
==================

- Collections/folders: tried it only with two levels. Should work with
  more convoluted ones, since algorithms are fairly simple, but I have not
  checked it.






Logic
=====

mendeley keywords and keywords are combined and then keywords are imported
as tags in Zotero

annote and mendnote (my own direct extraction from sqlite, to circumvent
the bug in mendeley) are combined in annote, which is a note in Zotero


Use bibitex from mend, and add fields and folders. Fields from sqlite,
folders from sqlite plus some massaging. Restropectibvely, better to have
forgotten about Mendeley bibtex and have generated my own.


Todo
## - write the script to clean bibtex for tablet: entr project: http://entrproject.org/
## - helm-bibtex issues?



Not perfect: for instance, if you have latex code in the notes, it can
break things.


poppler not workig fior extracting highlights:
http://coda.caseykuhlman.com/entries/2014/pdf-extract.html

PDF extraction: for pdf.js as standalone:
https://groups.google.com/forum/#!topic/mozilla.dev.pdf-js/cDZwsFS1kio

try zotfile? just for pdf extraction




using ruby pdf-reader and this gist
https://gist.github.com/danlucraft/5277732




citation key format
[auth:fold:lower][Title:fold:nopunct:skipwords:select,1,1:lower:prefix,_][year:prefix,_][0]



Pay attention to the not imported note
"Better BibTeX coudl not import ..."



Tablet:
refMaster
library
erathostenes


Relative paths
https://github.com/ZotPlus/zotero-better-bibtex/issues/126



helm and ebib and C-x C-f
use a modified bib file, with sed taking care of things



## Automatically propagating changes in the database to helm and tablet ##
Whenever there is a change in the Zotero database, the bibtex gets
updated. Now, we want to have these changes propagate automagically to the
tablet and the file I use with helm-bibtex, after creating appropriately
modified files (for file paths and removing the jabref group structure,
that we don¡t use for anything). This I do with the sed scripts
**sed-helm-tablets.sh**.

All that remains to be done is run the script when the bib file
changes. We could do it with `inotifywatch` but using
[entr](http://entrproject.org/) is much simpler. In my `.xsession` I have

    ls ~/Zotero-data/storage/zotero-$HOSTNAME.bib | entr ~/Adios_Mendeley/sed-helm-tablets.sh &

The reason why I have specific files per host is explained in the
[Notes about using syncthing](#Notes-about-using-syncthing) section



## Extracting all PDF annotations and placing them in an org-mode file ##

A very simple way, for me, to be able to quickly search all annotations in
PDFs (and even highlights) is to extract the annotations and highlights,
and place them in an [org mode](http://orgmode.org/) file, where the
heading is an org mode link to the file and for each file I have all the
comments and highlights. Then, I can easily search from them. To do that,
I have a cron job that every night runs **leela-rub-extract.R** (simply a
call to Rscript).

I am using [Leela](https://github.com/TrilbyWhite/Leela) (see
[my old web entry](http://ligarto.org/rdiaz/Zotero-Mendeley-Tablet.html#sec-9) for
details) and also
[this ruby script](https://gist.github.com/danlucraft/5277732) that uses
[pdf reader](https://github.com/yob/pdf-reader). The ruby script will
extract highlights too, whereas that is not working with Leela (or any
other poppler-based approaches).

[Zotfile](http://zotfile.com/) allows for similar things (or even better,
depending on your point of view) but it requires manual triggering. With
the approach I use, extraction takes place automatically.


There is much room for improvement here:

- Trigger the extraction only for the PDF that is modified
- Create a file in a way that [helm bibtex](https://github.com/tmalsburg/helm-bibtex) will understand (when the
  [version of helm-bibtex that uses a single notes file is ready](https://github.com/tmalsburg/helm-bibtex/issues/40).


## Notes about using syncthing ##

I use [syncthing](https://syncthing.net/) for syncing the PDFs and other
attachments.

First, you most likely do not want to sync the sqlite files themselves via
syncthing (read the Zotero docs).

Why do I have different bib files in different computers? The bib file is
exported, from Zotero, to the storage directory, but since any change in
the bib file triggers a change in the helm and tablet bib files, I do not
want to have this triggered in all the computers almost simultaneously if
they are online as this could lead to conflicts via syncthing (the helm
and tablet bibs being changed about the same time in all online
machines). By keeping different Zotero bib files per machine, the bib in
the machine I am working might change, and the changes in the helm and
tablet bib will only appear in the machine I am working, and then be
propagated to the other machines without leading to conflicts.


If you use
[PDF full text indexing](https://www.zotero.org/support/pdf_fulltext_indexing),
in the storage directory you might want to add an `.stignore` file as
follows:

    .zotero-ft-cache
    .zotero-ft-info

to prevent the indexes from being sent to the tablet (where they are
probably of little use).



Using a tablet
==============

Here things are not as easy and nice as they were with
[Referey](https://play.google.com/store/apps/details?id=com.kmk.Referey&hl=en). I
have tried all of the apps listed in
(https://www.zotero.org/support/mobile), including Zandy, Zed Lite, Zed
beta, Zojo, and Zotfile. The main problem with the first four is that you
cannot do something that to me is necessary: get the database file from
whererever the app deams suitable, but take the PDFs (more generally,
attached files) from a place I sync on my own. I do not store my attached
files in Zotero's servers, but sync them on my own with
[syncthing](https://syncthing.net/). Zotfile is nice, but not really what
I need and I find it too complicated and requires too much manual
intervention ---see the comments in my
[web page entry](http://ligarto.org/rdiaz/Zotero-Mendeley-Tablet.html#sec-6-2).



My setup up
Zotero-data is where the sqlite lives. Not synced by syncthing

Zotero-data/storage is a link to Zotero-storage

Zotero-storage: synced by syncthing.



For syncthing: exclude Zotero-Bufo.bib and Zotero-coleonyx.bib


RefMaster: does not support multiple files. It is a future feature as
shown in


https://play.google.com/store/apps/details?id=me.bares.refmaster



Erathostenes: slow, very slow, but you can open multiple files

Library: can open multiple files, and much faster than erathostenes. Can
use smae file as refmaster, and in setup path conversion, add the
appropriate prefix (like is done in tablet-erathostenes)

Problem of library is that you can search by name, etc, but not sort
easily as with RefMaster


<!---
Local Variables:
mode: gfm
--->
