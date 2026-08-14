---
name: remail
description: Use when answering questions about the user's email — listing recent messages, reading one, finding who wrote about a topic, or locating a file attached to a message. Requires a local mailbox maintained by the `remail` CLI.
---

# remail

`remail` keeps a local, read-only copy of an IMAP mailbox as ordinary files.
Reading never contacts the mail server, so these commands are always safe.

## The mail directory

One directory holds one mailbox. Run from inside it or pass `--path <dir>`. If
you do not know where the user keeps it, ask rather than guess.

Originals live in `raw/` and the readable export in `messages/`. Read the
export.

## Commands

Run `remail <command> --help` for a command's full flags. Add `--json` to any
command for machine-readable output.

### list

Show messages, most recent first.

```sh
remail list                 # the 20 most recent
remail list -n 50
remail list -n 0            # all of them
remail list --since 7d
remail list --since 2026-08-01
```

Each row is: id, date, attachment count, sender, subject.

JSON output shape:

```json
{
  "messages": [{"id": "...", "date": "...", "from": "...", "subject": "...",
                "attachments": ["..."], "dir": "/abs/path"}],
  "count": 12
}
```

### read

Print one message.

```sh
remail read a1b2c3d4
remail read a1b2           # any unambiguous id prefix works
```

Output is a YAML frontmatter block, then the body:

```
---
id: a1b2c3d4
date: 2026-08-13T09:15:02Z
from: Acme Billing <billing@acme.example>
subject: Invoice 4417
attachments:
    - invoice.pdf
raw: ../../../raw/2026-08/2026-08-13T091502Z-a1b2c3d4.eml
---

Body text follows here.
```

`date` is the server's receipt time and is reliable; `sent` is the sender's own
header and is not. HTML-only mail is converted to Markdown, marked
`converted: true`. `raw` points at the original, which has the full headers.

An ambiguous prefix is an error naming the candidates, never a guess.

### files

Print absolute paths to a message's attachments, one per line.

```sh
remail files a1b2
remail files a1b2 --inline    # also images embedded in the body
```

Embedded images are excluded by default so they do not bury real attachments.

JSON output shape:

```json
{"id": "a1b2c3d4", "dir": "/abs/message/dir", "files": ["/abs/path/invoice.pdf"]}
```

### sync

Fetch mail that arrived since the last run.

```sh
remail sync
```

Needs network and may prompt for a password, so prefer what is already on
disk unless the user asks for fresh mail. Safe to interrupt.

JSON output shape:

```json
{"fetched": 3, "exported": 3, "rebuilt": 0, "skipped": 0}
```

### init

`remail init --account you@example.com` creates a new mail directory. The user
runs this once; you rarely need it.

### skill

`remail skill --install` rewrites this document into the skills directory of
every agent it detects. Run it after upgrading remail to refresh a stale copy.

## Searching

The mailbox is just files, so search it rather than reading messages one at a
time:

```sh
rg -l 'invoice' <mail-dir>/messages
```

Each hit sits in a directory named `<date>-<subject>-<id>`, so the id is
already in the path.

## PDF attachments

Resolve the path with `remail files <id>` first, then extract the text with a
command-line tool instead of reading the document into context. Extraction is
what makes bulk work affordable — many attachments, or one attachment scanned
for a couple of fields.

In order of preference:

```sh
pdftotext -layout report.pdf -    # poppler; best for column-aligned documents
uvx --python 3.12 --from 'markitdown[pdf]' markitdown report.pdf
```

`markitdown` is the portable fallback when poppler is not installed. Both flags
are load-bearing: the PDF converter lives behind the `pdf` extra, and the
package needs Python 3.10 or newer, so the bare `uvx markitdown` invocation
fails on either count. Its table rendering can interleave cells from adjacent
columns, so it suits simple layouts better than dense grids.

For a document built out of table grids, a few lines of `pdfplumber` recover
rows far more cleanly than any generic converter:

```sh
cat > /tmp/tables.py <<'EOF'
# /// script
# dependencies = ["pdfplumber"]
# ///
import sys

import pdfplumber

with pdfplumber.open(sys.argv[1]) as pdf:
    for page in pdf.pages:
        for table in page.extract_tables():
            for row in table:
                print("\t".join(cell or "" for cell in row))
EOF
uv run /tmp/tables.py report.pdf
```

Read the PDF directly instead — if you can — when the document is short, when
its layout carries the meaning, or when the extracted text comes out ambiguous:
a footnote, a stamp, or a signature block that extraction mangles.

Extraction output goes to a scratch or temp location. Nothing in the mail
directory is ever written to.

## JSON output and errors

Every command accepts `--json` and emits one JSON object on stdout; plain text
and JSON are never mixed. On failure it emits this envelope and exits
non-zero:

    { "error": { "message": "..." } }

## Do not

- Do not modify or delete anything in the mail directory. `raw/` holds the only
  copy of the originals.
- Do not parse `.eml` files yourself. `read` has already decoded the MIME
  structure, character sets, and headers.
