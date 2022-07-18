# Adios Mendeley #

*Move from Mendeley to Zotero preserving notes, dates,
 folders/collections, and PDF annotations.*

I have used the code here (and code from
https://github.com/flinz/mendeley2zotero) to move from Mendeley to Zotero. In this moving
I haven't lost any of the Mendeley annotations for entries, the
annotations of Mendeley in the PDFs themselves, Mendeley's folder
structure (somewhat equivalent to Zotero's collections), or the date the
reference is added.

A few other files here allow me to automatically extract annotations and
highlights from PDFs (annotations and highlights in the PDF itself), as
well as prepare the BibTeX file for easy usage with Emacs and with a
tablet.

## Update (post mid-2018): READ THIS FIRST ##

Importing from Mendeley has become more complicated, after Mendeley started encrypting the local database (*your* database). See details and follow the steps given here:
https://www.zotero.org/support/kB/mendeley_import#mendeley_database_encryption
https://www.zotero.org/support/kB/mendeley_import
https://forums.zotero.org/discussion/80051/has-anybody-decrypted-mendeleys-library

## Update (2018-06-29): READ THIS FIRST ##

Zotero has now a way to import directly from Mendeley. You most likely want to try that first (and second, and third, ... before playing around with these scripts, messing around with R, etc). These are two links:
https://www.zotero.org/support/kb/mendeley_import 
https://forums.zotero.org/discussion/72260/available-for-beta-testing-mendeley-import

(and, for the sake of historical records, you can look at https://github.com/rdiaz02/Adios_Mendeley/issues/4 where Brenton Wiernik alerted me to the issue, and the conversation that followed).

## Using it ##

1. Start R, make the needed changes in the first four variables defined in
**mend-to-bibtex.R**, and run it, paying attention to possible errors and
warnings. In particular:
	- Mendeley makes no provision to avoid repeated BibTeX keys. So go and fix
      them: the run will give you the titles of the files with repeated keys.

	- Mendeley will not export a BibTeX entry if there is no BibTeX
  key. You might have deleted the key, or if you set Mendeley to
  automatically create keys, no key will be created if there is no author
  and no title. Again, the program will tell you which entries have no
  key.

2. Once you have your new BibTeX file, before importing it into Zotero, open
it up in [JabRef](http://jabref.sourceforge.net/). Why? Because there can
be things that are not OK, like a keyword entry with newlines, or latex
code itself in the notes, and this will break the import into Zotero
(since this only happened to me in two entries, I did not change the code
to catch and fix these issues).

  If you first go through JabRef first, you will find the problem very
  quickly and easily (as easy as being told about the problematic line
  number). Fix any remaining issues.

3. When done, import into Zotero. Beware that imports of large bibliographies
can be slow, even more if you enable full PDF indexing ---I do the import
first without PDF indexing, by changing the settings to 0 pages and 0
characters, and only after I have my full bibliography in Zotero I enable
the indexing back.

  Beware that I've only imported into a Zotero that had Better BibTeX,
  [BBT](https://zotplus.github.io/better-bibtex/), as an extension. I am not
  sure, but this might add also some extra functionality in the import (it
  definitely does for the export of BibTeX and I find it absolutely
  essential).



4. Finally, when you import in Zotero, pay attention to the "not imported"
note you might see as one of your last references. In my case, two
references that imported fine in JabRef did not in Zotero (weird
characters in authors' names). You will see in the text of the note
something like "Better BibTeX could not import ...". Fix those entries if
they are just a few, and add them by themselves (possibly adding them to
their corresponding collections), or fix the entries in the complete
BibTeX and go back to step 3.

5. Fix the dates. My
[naive expectation](https://forums.zotero.org/discussion/50759) that the
timestamp field would be recognized does not work. But you can use Alex
Seeholzer's [mendeley2zotero](https://github.com/flinz/mendeley2zotero).
	1. Make a backup copy of your databases.
	2. ~Modify the script to have line `d_added =
	datetime.datetime.utcfromtimestamp(d_added)` be `d_added =
	datetime.datetime.utcfromtimestamp(d_added/1000)` (at least as of July
	2015 Mendeley is using time in miliseconds since 1970).~  (This was fixed by
	in the [issue](https://github.com/flinz/mendeley2zotero/issues/2)) I filed.~
	3. Run the script with the `added_dates` option. You might get some warnings that, as far as I can
	tell, are inoquous.
	4. Copy the zot.sqlite as the new zotero.sqlite, start Zotero, and
       check.



Enjoy! Mendeley is now just a bad dream of days gone by. :-)


### Using it: what operating systems? ###

I've only used this with GNU Linux. I guess it should work in other Unixes
(Macs, for instance) but some things might not work with Windows directly,
and you'll need to modify the code.



## What and how: details  ##

I use both the BibTeX file exported from Mendeley and the sqlite
database. The BibTeX file that Mendeley exports is missing many things
that you probably want to keep, so I query the sqlite database,
grab that info, and place it in a new BibTeX file. In the process, I fix a
few major problems with things Mendeley does with files, etc.  Finally,
from the sqlite file I also extract the folder structure, and I add that
to the new BibTeX file using the format that
[JabRef](http://jabref.sourceforge.net/) uses for groups. Since the Zotero
import can use JabRef's groups' information (see
[this ZotPlus closed issue](https://github.com/ZotPlus/zotero-better-bibtex/issues/97)),
you do not need to enter any of the folder/collection information by
hand. The functions for doing all of this are defined in
**sqlite-bibtex-functions.R**. 


These are the pieces of information I get from the Mendeley sqlite file
(and some details of what is done and where they are left in the BibTeX
file):

- Date the file was added (field `timestamp`). But note this is not
  directly incorporated into Zotero (see step 5 in [Using it](#using-it)).

- Annotations in the entry. You might think you have these in the BibTeX
  file, but maybe you don't: as of July 2015, with Mendeley's v. 1.14 the
  exporter is buggy and you will not get the full annotations in the entry
  if there are newlines, for instance; this is a know bug (search the
  Mendeley forum). So I circumvent the bug by grabbing all of the
  annotations from the sqlite db (and include any that might have been
  placed in the `annote` field and not be in the sqlite field `text` in
  table `DocumentNotes` ---nope, I did not check if this happened at all;
  I just took the safer way of using the union of both). These are all in
  the `annote` field in the BibTeX file, and Zotero will recognize this as
  notes.

- Annotations in the PDFs made from within Mendeley. If you are naive
  enough (as I was when I started using Mendeley) you might be using
  Mendeley's PDF editor which does/did NOT place the annotations and
  highlights in the PDF itself (this is easy to check if you open a
  Mendeley-annotated file in any other pdf viewer). So I grab the PDF
  annotations and place them in a new field in the BibTeX file that I call
  `mendpfnotes`. You might, alternatively, want to use [Menextract2pdf](https://github.com/cycomanic/Menextract2pdf) 
  that "extracts highlights and notes from the Mendeley database and adds them directly to all 
  relevant PDF files, which can then be read by most PDF readers".

- Keywords and tags. In Mendeley's dbs and BibTeX you get a `keywords` and
  a `mendeley-tags` field. I think `keywords` often contain the author's
  keywords, but not always, and one of the two can be missing or
  overlapping the other. So I return a single field (called `keywords`),
  which is the union (after tokenizing by commas) of `keywords` and
  `mendeley-tags`. This is happily recognized by Zotero as tags.

- The original Mendeley id, in case you need to go back to the sqlite
  database (field `mendid`).


### Some clean up operations ###


I also do some cleaning up of strings, such as some of the HTML markup in
the notes that will prevent proper import and/or make life harder when
reading them (e.g., I think you definitely want a newline if you have a
`<br/>`).


Another important clean up operation affects file names. Again, if you
allow Mendeley to rename files for you (which was a silly thing I did
sometime in the past) you will find that you end up with file names that
can be really long and that contain spaces and other annoying
characters. I fix this before importing into Zotero: any file with a name
longer than a user-specified length (I used 40, but this is a
user-modfiable function argument), or with spaces or characters that are
not letters, numbers, the period or the hyphen, are renamed using as the
new name the BibTeX key and a randomly generated sequence of letters and
numbers (length of the random part is also a user-modifiable argument).


I actually wonder why Mendeley can create such long file names. This seems
like an obviously bad idea (I once tried to encrypt a home partition using
eCryptfs or encfs, or both, and hit the maximum length possible, which is
not difficult, given that Mendeley can also create horrendously long
directory names).


### Caveats and warnings ###

- Getting the collections/folders. I've only used it with a set of folders
  (Mendeley jargon) or collections (Zotero jargon) of up to two levels of
  depth.  I think the code should work with arbitrarily deeply nested
  structures, since the algorithms I wrote are fairly simple, but I have
  not checked it.
- If you have latex code in the notes, it can break things (it did for
  me) during the import.
- If you have keywords that contain things that get interpreted as
newlines in the BibTeX text file, it can break things during the import.
- I have noticed that some of my lower-level collections have been
  duplicated as upper level. I think this is a different issue that
  appeared later as I did something wrong. But check it. (I say this
  because JabRef does not show any problems). Anyway, this should be a
  matter of removing the duplicated upper-level collection (**not the
  collection and items**).





### Why through BibTeX ###

Initially, it looked like a good idea:

- Because to me it is much simpler than trying to directly manipulate the
  Zotero sqlite database.
- You can incorporate loads of additional information, including the
  Mendely folders the tags, etc, as new BibTeX custom fields. 

However, maybe I should not have used the originally exported Mendeley
BibTeX file and modified it, but just directly created the BibTeX file from
scratch from the sqlite db. 



### Why R? ###

The initial getting the info out of the Mendeley db involves just a couple
of queries to the sqlite database which I do using the
[RSQlite](https://github.com/rstats-db/RSQLite) package. The rest is
massaging and cleaning, checking, modifying the bibtex, and preparing the
JabRef group structure. I do it from R just because it is easier for me
than using, say, Python.


### Other ways of doing this ###

Ideas and suggestions of how to go about moving from Mendeley to Zotero
are available in Zotero's forum. For instance
[this](https://forums.zotero.org/discussion/28786/mendeley-import/) and
[this](https://forums.zotero.org/discussion/26453/moving-from-mendeley-to-zotero/). But
most of the ideas still involve a fair amount of manual work. Alex
Seeholzer has written a
[Python script to move from Mendeley to Zotero](https://github.com/flinz/mendeley2zotero)
but it did not fully fit my needs; in particular, the folder/collection
structure needs to be created before hand in Zotero, I think the PDF
annotations by Mendeley do not get transferred, and I think you might not
get the full `annote` and `keywords` fields. As you have seen, though, I
use it for fixing the dates (see step 5 in [Using it](#using-it)). 
[Menextract2pdf](https://github.com/cycomanic/Menextract2pdf) "extracts highlights 
and notes from the Mendeley database and adds them directly to all 
relevant PDF files, which can then be read by most PDF readers".



## Why move away from Mendeley? ##

There are several good reasons:

- Mendeley is not free software. It is not even open source.

- It is not possible (or I have not been able to) just recover all of your
  database from a backup you have yourself. I do not mean the backup that
  Mendeley creates, I mean the backups you create by whatever reasonable
  backup procedure you use, which creates copies at specific time points,
  etc. If you have a decent backup policy of your machines and on day `t`
  your db gets screwed up, you might think that it is just a matter of
  going to your backup of `t - k`, and restoring from there (maybe you are
  lucky and `k` is less than a day old). Well, nope, it does not work that
  way and there is no simple way to say "here, this is the database; use
  this, and forget anything and everything in your servers". (And yes, I
  asked about this in the Mendeley forum to no avail.)

  With Zotero, in my limited tests, it does: in desperate cases you can
  tell it to overwrite all the server stuff with your database (the
  "Restore to Zotero servers"). And if you keep a backup of your BibTeX
  files, you might also be able to restore most or even all of your stuff
  from there (at least if you use
  [BBT](https://zotplus.github.io/better-bibtex/) and export notes, etc).


- Mendeley does not check for duplicated BibTeX citation keys and will not
  generate a BibTeX entry if you do not have author and date entries. This
  sucks, as for me the place I look for stuff is the BibTeX file (much
  faster searching than via Mendeley itself).

- Mendeley, in my opinion, has a cluttered interface, compared to Zotero.

- Mendeley, in my experience, is much worse at getting the reference
  information from the PDF itself and will insist in screwing up when you
  ask it to review a reference or use the DOI. Too much manual
  intervention. 

- Mendeley's searchers are slow. Zotero's are not blazing fast, but I find
  them faster.

- Sorting files into subfolders: who thought it was a good idea to use
  spaces in the "folder" (directory) name? What about spaces in the file
  name itself? What about apostrophes, or question marks, or ...? 

- In general, it is easy to shoot yourself in the foot (or it is for me).

- Keyboard shortcuts: few, and where are they documented? I find it
  unavoidable to use/abuse the mouse (I often end up with wrist pain after
  intensive bibliography work with Mendeley).

- Inflexible about what fields you are shown (some you cannot uncheck,
  which sucks with long abstracts).

- Persistent errors in entries, like adding links to files that you have
  removed which results in the broken link in Mendeley and paths to
  inexistent files in the BibTeX file.


### Why not before? ###

Because of the manual or programming work involved, I did not decide to
take the plunge until a recent Mendeley crash that did not allow me to
recover my library to a sane state. As well, I have been very happy with
my usage of
[Referey](https://play.google.com/store/apps/details?id=com.kmk.Referey&hl=en)
to read papers in a tablet (see my
[former web page entry](http://ligarto.org/rdiaz/Zotero-Mendeley-Tablet.html)). 


## Using a tablet ##


**This is left here for historical purposes, but it is OUTDATED!!!**
I am now using
[Referey](https://play.google.com/store/apps/details?id=com.kmk.Referey),
after converting the Zotero db to a db that Referey will understand. The
code is available from the repo
[Zotero-to-Referey](https://github.com/rdiaz02/Zotero-to-Referey).



~~Here things are not nearly as easy and nice as they were with
[Referey](https://play.google.com/store/apps/details?id=com.kmk.Referey&hl=en)
and Mendeley. I have tried all of the apps listed in
(https://www.zotero.org/support/mobile), including Zandy, Zed Lite, Zed
beta, Zojo, Zotero Reader, Zotable, and Zotfile. The main problem is that with none
of them you can do something that to me is necessary: get the database
file from whererever the app deams suitable, but take the PDFs (more
generally, attached files) from a place I sync on my own. I do not store
my attached files in Zotero's servers and I do not use Dropbox, but sync
them with
[syncthing](https://syncthing.net/). I do not want to set
up a WebDAV server either, since it is just simpler to keep my 
Zotero storage directory (where the PDFs live) synced between computers and tablets
with syncthing.
[Zotfile](http://zotfile.com/) is
nice, but not really what I need and I find it too complicated and
requires too much manual intervention ---see the comments in my
[web page entry](http://ligarto.org/rdiaz/Zotero-Mendeley-Tablet.html#sec-6-2);
for instance, I need to decide what to send back and forth; too much work,
and requires making accurate predictions about what I'll want/need to read.~~


~~So what I am doing now is using Android applications that understand
BibTeX files. There are three:
[RefMaster](https://play.google.com/store/apps/details?id=me.bares.refmaster),
[Library](https://play.google.com/store/apps/details?id=com.cgogolin.library),
and
[Erathostenes](https://play.google.com/store/apps/details?id=com.mm.eratos).~~

~~Erathostenes understands the nesting in JabRef's
groups, though it will only display the lower-most level, if
you have several levels of nesting. So you can see part of the
structure of your Zotero collections. However, Erathostenes
takes a very long time to load my BibTeX file. It is Erathostenes
what I use most of the time, but I am not fully satisfied. (Erathostenes
might support Zotero in the near future: see [the changelog for future versions](https://bitbucket.org/mkmatlock/eratosthenes/wiki/Changelog#!planned-for-08-to-be-released-september-2014)).~~


~~RefMaster is nice (sorting by several fields) and in my experience faster
than Erathostenes, but it does not support multiple files per entry (it is
a "future feature", but this might take long to arrive, given that
RefMaster's last version is from over two years ago). JabRef groups are not supported yet
either.~~

~~Library is much faster than the two above and supports multiple files and
you can of course search the library. However, you cannot sort by date
(this is a
[requested feature](https://github.com/cgogolin/library/issues/1)) and there
is no support for JabRef's groups.~~


~~Things, thus, are not as easy and simple as they were with Referey, and I
do miss that.~~



### How do I use Zotero and the tablet? ###

**Again, this is left here for historical purposes, but it is OUTDATED!!!**
I am now using
[Referey](https://play.google.com/store/apps/details?id=com.kmk.Referey),
after converting the Zotero db to a db that Referey will understand. The
code is available from the repo
[Zotero-to-Referey](https://github.com/rdiaz02/Zotero-to-Referey).


~~First, I only use the tablet to read and annotate the PDFs. I am not that
interested now in modifying the BibTeX file (or Zotero's db) itself. So
this is just a matter of getting the BibTeX exported from Zotero into the
tablet. I use [syncthing](https://syncthing.net/) for syncing the PDFs and
other attachments and for syncing the BibTeX file.~~

~~But what BibTeX file? Not the one immediately exported by Zotero, since
that has stuff I might not need (the collection structure if using Library or RefMaster) and it is better
to change the file paths. So I process Zotero's BibTeX with a little sed
script that I run whenever Zotero produces a new BibTeX file. See all the
details in
[Automatically propagating changes in the database to helm and tablet](#automatically-propagating-changes-in-the-database-to-helm-and-tablet).~~




## Odds and ends ##

### Extracting all PDF annotations and placing them in an org-mode file ###

**Beware: the approach explained here is not working well**. I find that I am
**missing many annotations or highlights** made in the tablet with at least
one PDF reading application. The annotations are there, you can
see them in Emacs with pdf-tools or in Okular or whatever, but neither leela
nor the ruby script will extract them. Fortunately, **Zotfile can extract them**. If you
do not want to miss annotations/highlight, use Zotfile from Zotero and extract
annotations. Then, run and advanced search searching for your term in "Note" (not
"Annotation"). Thus, what follows is likely useless. 

A very simple way, for me, to be able to quickly search all annotations in
PDFs (and even highlights) is to extract the annotations and highlights,
and place them in an [org mode](http://orgmode.org/) file, where the
heading is an org mode link to the file and for each file I have all the
comments and highlights. Then, I can easily search from them. To do that,
I have a cron job that every night calls Rscript with
**leela-ruby-extract.R**.

I am using [Leela](https://github.com/TrilbyWhite/Leela) (see
[my old web entry](http://ligarto.org/rdiaz/Zotero-Mendeley-Tablet.html#sec-9)
for details) and also
[this ruby script by Dan Lucraft](https://gist.github.com/danlucraft/5277732)
that uses [pdf reader](https://github.com/yob/pdf-reader). The ruby script
will extract highlights too, whereas that is not working with Leela.

It seems that [pdf.js](https://mozilla.github.io/pdf.js/) is a very
capable platform that extracts highlights and annotations, and that is in
fact used by [Zotfile](http://zotfile.com/). But I have no idea if/how to
run it from the command line as just a simple standalone, although
[there are pointers out there](https://groups.google.com/forum/#!topic/mozilla.dev.pdf-js/cDZwsFS1kio)
I could not figure out how to follow quickly.


[Zotfile](http://zotfile.com/), a Zotero extension, allows for similar
things (or even better, depending on your point of view) but it requires
manual triggering (and, file by file, is a lot slower than Leela). With
the approach I use, extraction takes place automagically.


Finally, it is also possible to do this directly from Emacs itself with
pdf-tools, and include the notes in an org file:
[Note Taking with PDF Tools](http://matt.hackinghistory.ca/2015/11/11/note-taking-with-pdf-tools/). It
works great, and not only do we get both notes and the text of the
highlight (i.e., what I was doing through the ruby script or Zotfile), but
we also get a **link to the precise location of the
annotation** [thanks to the added "++" syntax in org-pdfview](https://github.com/markus1189/org-pdfview/pull/7). However,
I still have to figure out how to, automatically from a cron job, generate
a single file with all annotations (or scan my library to generate one
file of annotations per PDF).

So there is much room for improvement here:

- Trigger the extraction only for the PDF that is modified (and neatly
  insert the annotation in the proper place).
- Populate the annotation file only for files with annotations (not with useless
  links to PDFs that contain no annotations).
- Create the annotation file in the best way for 
  [helm-bibtex](https://github.com/tmalsburg/helm-bibtex) to  understand
  (helm-bibtex supports keeping all notes in one file: see
  [this commit](https://github.com/tmalsburg/helm-bibtex/commit/5d028b983465e997cc59dd0237a171eab8fb56ba)
  and this
  [news entry](https://github.com/tmalsburg/helm-bibtex/commit/fe78fd04630ae078443aed1fa82b13b2f512f3ef)).
- Use the approach in
  [Note Taking with PDF Tools](http://matt.hackinghistory.ca/2015/11/11/note-taking-with-pdf-tools/)
  to generate that file for helm-bibtex.
- Figure out whether I want a single file with all annotations or a file
  per entry (preliminary tests suggest that a single huge file will lead
  to deals in helm-bibtex).
- Add the notes from Zotero itself to the org file(s) with annotations, or
  merge them into just one `annote` field. This way, I'd have a single
  place to do all and every search
  ([helm-bibtex can search on additional search fields](https://github.com/tmalsburg/helm-bibtex#fields-used-for-searching),
  but
  [if you have several per entry only the last one is used](https://github.com/tmalsburg/helm-bibtex/issues/56)).



### Using the BibTeX file from Emacs ###


**Left here for historical purposes, but now OUTDATED**
[helm-bibtex](https://github.com/tmalsburg/helm-bibtex) can, since mid
November 2015, deal with the File field (see
[this merge](https://github.com/tmalsburg/helm-bibtex/pull/73) and
[this commit](https://github.com/tmalsburg/helm-bibtex/commit/f6f2864bed775908294a2b5956d4ab5e302a2485)).
So I am still using helm-bibtex, of course, but I no longer need to do any
of the things below.



~~After seeing it mentioned in the org mode list, I've started using the
really great [helm-bibtex](https://github.com/tmalsburg/helm-bibtex), a
bibliography manager for Emacs. Searching for stuff and inserting
references in something you are writing is amazingly simple and
powerful. However, I am not using `helm-bibtex-find-pdf` since I often
have multiple PDFs associated with one entry. (I also have other issues,
such as how the path is specified, but these could be fixed with the hints
that Titus von der Malsburg gave me
[here](https://github.com/tmalsburg/helm-bibtex/issues/53)).~~


~~What I do, if I want access to the PDF, is open the entry I want from
helm-bibtex and then go the the `file` field, and `C-x C-f` to open the
file (I am using
[ffap with ido](http://www.gnu.org/software/emacs/manual/html_node/ido/Find-File-At-Point.html),
so `C-x C-f` on top of the file path opens it). I am now using
[pdf-tools](https://github.com/politza/pdf-tools) to view the PDFs from
within Emacs, but it would work the same with Okular or another viewer.~~


~~In fact, it is very simple to have helm-bibtex jump to the file field
directly as the default action (and, once in there, if you have multiple
files, moving between them is simple with `forward-sexp`). I have this in
my `.emacs`:~~

    (defun rdu-helm-bibtex-go-to-file-field (KEY)
      "Jump to the file field in the entry."
      (helm-bibtex-show-entry KEY)
      (search-forward "file = { ")
    )
    
    (helm-add-action-to-source "Go to file field" 'rdu-helm-bibtex-go-to-file-field
    			   helm-source-bibtex 0)
    (helm-delete-action-from-source "Show entry" helm-source-bibtex)
    (helm-add-action-to-source "Show entry" 'helm-bibtex-show-entry
    			   helm-source-bibtex 1)



~~For that to work, I generate, from the Zotero BibTeX file, a bib file with
the file paths stripped of extraneous information, so that the file field
contains only file paths. This is done with the script
**sed-helm-tablets.sh**, and further details are provided in
[Automatically propagating changes in the database to helm and tablet](#automatically-propagating-changes-in-the-database-to-helm-and-tablet).~~


**Beware** that because of the way BBT works, if you want to preserve the
  full path, you might not want to export to a bib file that lives right in
  your data directory. See
  [this thread](https://github.com/ZotPlus/zotero-better-bibtex/issues/126). (So,
  in my case, I export directly to
  `~/Zotero-storage/zotero-$HOSTNAME.bib`, not to
  `~/Zotero-data/storage/zotero-$HOSTNAME.bib`). You mileage might vary
  and, regardless, this would be an issue of modifying the sed script to
  your needs.

### Automatically propagating changes in the database to helm and tablet ###

**Outdated too: not needed any more. See above and [Zotero-to-Referey](https://github.com/rdiaz02/Zotero-to-Referey)**

~~Whenever there is a change in the Zotero database, the BiBTeX file gets
updated (this is something you configure in Zotero, and I have it so that
each machine running Zotero writes its own `zotero-$HOSTNAME.bib`
file). But we want to modify this file, so it is easier to use in the
tablets and with Emacs. We want BiBTeX files without the JabRef group
structure for Library and RefMaster (we leave it if using Erathostenes) and with easier to use file paths (easier to open from Emacs and
the tablets). This I do with the sed scripts **sed-helm-tablets.sh**.~~


~~Since we want to have these changes propagate automagically to the tablet
and the file I use with helm-bibtex, all that remains to be done is run
the script when the BibTeX file changes. We could do it with
`inotifywatch` but using [entr](http://entrproject.org/) is much
simpler. So that I do not need to remember to launch it manually, in my
`.xsession` I have~~

    ls ~/Zotero-data/storage/zotero-$HOSTNAME.bib | entr ~/Adios_Mendeley/sed-helm-tablets.sh &

The reason why I have specific files per host is explained in the
[Notes about using syncthing](#notes-about-using-syncthing) section




### Notes about using syncthing ###

I use [syncthing](https://syncthing.net/) for syncing the PDFs and other
attachments. Of course, beware that you most likely do not want to sync
the sqlite files themselves via syncthing (read the Zotero docs and
forum). My actual directory structure is to keep the Zotero db under
`~/Zotero-data` and have the `storage` subdirectory be a symbolic link to
`~/Zotero-storage`. All the attachments and the BibTeX files live under
`~/Zotero-storage` and that gets synced (except for the files mentioned
below).

Why do I have different bib files in different computers? The bib file is
exported, from Zotero, to the storage directory, but since any change in
the bib file triggers a change in the helm and tablet bib files, I do not
want to have this triggered in all the computers almost simultaneously if
they are online: this could lead to conflicts via syncthing (the helm and
tablet bibs being changed about the same time in all online machines). By
keeping different Zotero bib files per machine, the bib in the machine I
am working might change, and the changes in the helm and tablet bib will
only appear in the machine I am working, and then be propagated to the
other machines without leading to conflicts.


If you use
[PDF full text indexing](https://www.zotero.org/support/pdf_fulltext_indexing),
in the storage directory you might want to add an `.stignore` file as
follows:

    .zotero-ft-cache
    .zotero-ft-info

to prevent the indexes from being sent to the tablet (where they are
probably of little use).




## License ##

All the code here is copyright, 2015, Ramon Diaz-Uriarte, and is licensed
under the [GNU Affero GPL Version 3 License](http://www.gnu.org/licenses/agpl-3.0.en.html).




<!---
Local Variables:
mode: gfm
--->
