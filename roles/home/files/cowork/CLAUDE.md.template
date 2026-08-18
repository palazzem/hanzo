# Workspace Rules

This is not a project repository. It is a shared workspace where Claude Code sessions handle independent one-shot tasks: questions, experiments, scripts, code snippets, documents, or any other generated files.

## Task isolation

- Every new task (question, chat, experiment, etc.) gets its own folder at the root of this workspace, named with a freshly generated UUID (e.g. `a1b2c3d4-...`). Create it before writing any files for that task:

  ```sh
  # macOS
  mkdir "$(uuidgen | tr '[:upper:]' '[:lower:]')"
  # Linux
  mkdir "$(cat /proc/sys/kernel/random/uuid)"
  ```
- A task folder is fully self-contained: all code, notes, outputs, and intermediate files for that task live inside it.
- Never read, modify, or reference files inside other task folders. Each folder belongs to a different, unrelated task — treat its contents as off-limits context.
- If a follow-up clearly continues a previous task in the same conversation, keep using that task's existing folder instead of creating a new one.

## Workspace hygiene

- Keep the workspace root clean: only `CLAUDE.md` and task folders live at the root. Never write loose files there.
- Purely conversational answers that produce no files do not need a folder — only create one when something must be written to disk.
- Do not initialize git, add dependencies, or create configuration at the workspace root; if a task needs any of those, do it inside its own task folder.
