

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
