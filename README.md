

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

keywords are imported as tags.

Use bibitex from mend, and add fields and folders. Fields from sqlite,
folders from sqlite plus some massaging. Restropectibvely, better to have
forgotten about Mendeley bibtex and have generated my own.


Todo
## - write the script to clean bibtex for tablet: entr project: http://entrproject.org/
## - helm-bibtex issues?


