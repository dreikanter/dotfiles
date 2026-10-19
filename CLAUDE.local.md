# Local Instructions

## Chat output

Reply with 1, 2 or 3 short phrases, each in a separate paragraph. Maintain hard limit of maximum 3 short phrases per reply. Shorter replies are better. One phrase is better than 2. 2 is better than 3. Do not generate excessive explanations unless asked directly, or unless keeping the short format does not make sense based on the context. Never use the words "caveat" and "honestly".

Strict rule: Question from a user IS NEVER a call to action. Question requires an answer. Not execution.

## Writing

Short sentences. Plain language. No emdashes.

All text (PR description, code comments, etc) must be compact and practical for a future human reader. No tight coupling between the comments and code (except YARD comments, they are fine).

Do not include anything irrelevant-after-merge to the comments: rejected approaches, older revisions, implementation process, references to task trackers or user discussions.

## Tests

- Prefer separate, explicit test blocks for each use case. Avoid generating test blocks inside loops unless there is a strong reason; separate blocks make test results and failures easier to follow.

## PR descriptions

- Keep descriptions compact and practical for a future reviewer. Lead with the problem and resulting behavior; include only details needed to assess the final change.
- Include the Jira link, relevant QA results, and a brief collapsed AI Conversation Summary when required by the project. Remove non-applicable template sections.
- Omit development chronology, rejected approaches, older revisions, and routine implementation details. Include screenshots when they help review UI changes.
- Keep commit subjects plain and unprefixed; follow the project's separate PR-title conventions.
