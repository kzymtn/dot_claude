---
name: "create-new-file"
description: "judge if create new file, when trying to create new file"
---

## Flows

- 1 check if new file is update of the existing file
- 2 if the "potentially" new file is the update of the existing file, then git commit old file and update the content of the existing file and commit again.
- 3 this skill aim to avoid the directory include the similar files with the names which differ , say, only suffix.
