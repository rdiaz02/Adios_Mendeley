

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
