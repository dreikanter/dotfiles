---
description: "Code-review a GitHub PR; renders an HTML report. Args: PR URL and optional Jira IDs."
---

Run the `cr` shell script with the user-supplied arguments and open the
resulting HTML report.

Steps:

1. Pass all arguments after `/cr` (PR URL, optional Jira IDs/URLs) directly to
   `cr` via Bash. The script handles arg parsing, data gathering, the LLM
   call, and HTML rendering itself — do not pre-process arguments here.
2. The script prints the absolute path of the generated HTML file on stdout.
3. Open it: `open <path>` on macOS.
4. Report the path to the user. Do not print the HTML contents in chat.

If the script fails, surface its stderr to the user verbatim and stop.
