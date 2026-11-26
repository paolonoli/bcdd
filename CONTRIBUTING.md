# Contributing to BCDD

Thank you for your interest in BCDD. Collaboration is voluntary. Discussions and issues can be written in English or
Italian.

## Ways to take part

- **Try BCDD and report.** Write the CSCs of a system you know, run `bcdd check`, and report what was clear, what was
  difficult and what the report said. This is the most useful contribution at version 1.0-beta.
- **Discuss.** Questions, ideas and proposed applications go in
  [Discussions](https://github.com/paolonoli/bcdd/discussions).
- **Report a problem.** Open an [issue](https://github.com/paolonoli/bcdd/issues) giving the command you ran, the file
  (or a reduced version of it), the report of `bcdd check`, what you expected and what happened.
- **Propose a change.** Pull requests are welcome as proposals; see below.

## How pull requests are handled

This repository is published from the project's main source tree, so a pull request is not merged here as it stands:
the maintainer reviews it, applies the change to the main source tree and publishes it in a later commit of this
repository, naming the author in the commit message. If the change is not adopted, the pull request is closed with the
reason.

Before a large change, open a discussion or an issue first, so that the direction can be agreed on.

## Tests

`nimble test` builds `bcdd` and runs its test suite. `nimble testeditor` builds everything and runs the suite of
`bcdd-editor`; it needs Xvfb. In both cases check the result in the last line that the suite prints, which begins with
`controlli:` (the word is Italian). A change to the programs should keep the suite passing and add a check for the new
behaviour.

## Licences of contributions

By contributing, you agree that your contribution is distributed under the project's licences: BSD-3-Clause for the
code (`LICENSE`) and CC BY 4.0 for the documentation (`LICENSE_DOCS.md`). Add a `Signed-off-by` line to each commit
(`git commit -s`) to certify that you have the right to submit it under those terms (Developer Certificate of Origin,
<https://developercertificate.org/>).

## Contact

bcdd@nolisoft.it
