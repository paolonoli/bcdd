# The BCDD manual

<!-- SPDX-License-Identifier: CC-BY-4.0 -->
*Copyright 2026 Noli Paolo. Document distributed under the Creative Commons Attribution 4.0 International licence ([CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.en)).*

---

## How to read this manual

**BCDD** is a language for specifying the behaviour of a system through its interfaces with the outside,
called *boundaries* (chapter 1). A BCDD description consists of text files containing **CSCs**
(chapter 1) and entities (chapter 12).

`bcdd` is the command-line program that checks CSC files; its use is described in chapter 2, and its
four commands are summarised in chapter 29.

The text is built around a practical example, the staircase light of a block of flats, considered as a
system: pressing a button switches the light on and, after a certain time, the light switches itself off. Chapter 28
applies the same forms to a real system, an audio measurement kit; chapter 29 rewrites the staircase light
from beginning to end.

Terms used with a particular meaning are explained in the text at their first occurrence and collected
in the glossary (appendix C). Appendix A lists the keywords with the chapter in which each one is
described; appendix B lists the errors reported by `bcdd` and what the program does not check.

The manual describes `bcdd` at version 1.0-beta, which recognises all the forms of the language described in the
manual. `bcdd` checks the form, names and types of formulas, but does not evaluate them on scenarios: the report
lists the checks not executed (chapter 24). The manual also describes recording verification (chapter 24), which
no program described here performs.

The outputs of `bcdd` shown in this manual are those of the program in English, its default language, on the files
shown. With `bcdd --lang it …` (the option precedes the command) or with the environment variable `BCDD_LANG=it` the
program writes its messages in Italian.

The manual illustrates the rules of the language specification without adding rules of its own:
where the two texts disagree, the specification prevails.

---

## Index

For each chapter, the index gives the content and the topics introduced. The chapters are meant to be read
in order, because each builds on the previous ones. There are two exceptions. A reader who has to describe a single
boundary can go from chapter 10 to part three; part four, however, also requires part two,
because its examples take up the entities of part two.
Chapters 14, 15, 19 and 20 deal with special cases and can be postponed until they are needed; chapters 19 and 20
are nevertheless required for chapter 28.

### Part one — One boundary, described in words

This part describes the staircase light from the consumer's point of view, first in words and then in a file.
It presents writing, checking, approving and modifying the description of a system.

**1. The boundary and the guarantee** — The chapter considers the staircase light from the consumer's point of view.
From it the chapter derives the two concepts on which the language is founded: the boundary, that is the interface
between a system and its consumer, and the guarantee, that is what the system guarantees on that boundary, together
with the way to verify it.

**2. The first CSC** — The first CSC file is presented: the staircase light
described with two guarantees in words. The file is then submitted to the `bcdd` program, which checks
its form.

**3. Assumptions** — The assumption is introduced, that is a condition on whoever is on the other side of the
boundary, a condition on which a guarantee depends. In the example the guarantee is that the light switches on if the button is
held down for at least a tenth of a second: if the button is only brushed, the guarantee is not violated.

**4. The two sides of a boundary** — The chapter states that a CSC is written from the side of whoever keeps the
guarantees, while whoever is on the other side reads the same lines the other way round. On this basis a signal is added
to the light for the person on the stairs: a warning shortly before it switches off.

**5. Requests** — Starting from the caretaker's request to keep the light on for
cleaning, the chapter describes how to write a request, which first has a response, accepted or rejected, and then an
outcome, succeeded or failed.

**6. The types of values** — The light now has three modes: off, on, and on for cleaning. To describe them
the chapter introduces types, which establish which values what is observed at the boundary can take, and named lists
of values.

**7. Pending approval and approved** — The chapter states who approves a guarantee pending approval: a person with
the authority to do so, never the program or the language model. The file records the decision that approved it.
At the end of the chapter the CSC of the light is approved in full, and the `bcdd` command that prepares the
skeleton of a new file is presented.

**8. Making a guarantee precise** — “It switches off after a while” becomes “it switches off 60 seconds after the last
press, with a tolerance of 5 seconds”, and a new press restarts the time. For this purpose the chapter
introduces a more precise line, which is added without deleting the guarantee in words, and named constants. It
also introduces numbers not yet decided and the use of the language model, which asks questions about the points
that are still vague.

**9. Examples that fix the intention** — Scenarios are introduced, described instant by instant, which
show what the light must do and what it must not do: two presses 100 seconds apart are
admitted, a switch-off that comes too early is not. The chapter also states their limit: a scenario forbids
nothing that it does not describe.

**10. Changing a CSC already approved** — The on-time goes from 60 to 90 seconds. Since an
approved CSC is not modified, a new version of it is written; the chapter states what must be approved
again and what remains approved.

### Part two — More boundaries: entities

In part one the light has a single boundary, but a system often has more than one. This part describes what
stands behind those boundaries and connects them, which is called an entity.

**11. One boundary or separate boundaries** — The button and the light can be described separately, and the CSC is split
in two: one for the button pressed, one for the light observed. The chapter states when it is worth splitting a
boundary and highlights a problem: a guarantee that concerns both boundaries can no longer be written in either
of the two CSCs.

**12. What lies behind the boundaries: the entity** — The entity is introduced, that is what stands behind
one or more boundaries; the guarantee “when the button is pressed, the light switches on” is written in the entity.
An entity is described by stating the boundaries on which it keeps guarantees, those for which it relies on the
guarantees of others (for example of the electrical mains) and the guarantees that bind two of its boundaries.
Where it is located is never stated.

**13. An entity made of parts** — The staircase light is divided into two parts, a button and
a lamp, and the command passes from one to the other; the boundary between the two parts remains internal to the entity. The chapter
also introduces the rule that a boundary used by a part must be provided by another part, or used by the entity
itself towards the outside: `bcdd` checks the rule and reports the cases in which it is not respected.

**14. A channel that loses or delays: the wireless button** — The button becomes wireless, with a
receiver next to the lamp. A channel that can lose a message, delay it or reorder messages is a
boundary in its own right, with its own CSC: the chapter describes how to treat it and how to write an external
boundary of the entity.

**15. Boundary versions** — A new lamp uses version 0.2 of the command, while the
old button provides only 0.1. Starting from this case the chapter describes how to indicate a precise version of
a CSC, in which cases the version used and the version provided match, and how a part can provide two
versions of the same boundary at once.

**16. The number of copies of a part** — With one button per floor, from one to five, the chapter describes how to indicate the
number of copies of a part and what each one guarantees: every copy keeps all the guarantees of the part,
none takes precedence over the others and none performs tasks on behalf of the others.

**17. The size of an entity** — The chapter provides the criterion by which it is established whether an entity
has an adequate size: it does when whoever implements it, a person or a language model, can consider together
its boundaries, its guarantees and the boundaries of the neighbouring parts. This criterion explains why the staircase light
is divided into button and lamp, and no further.

**18. Scenarios across several boundaries** — In the entity the scenario “the button is pressed, and within one second
the light is on” is written. Since a CSC concerns only its own boundary, the order of events on two different
boundaries is written in the entity; each name is preceded by the CSC it comes from.

**19. A part that may be missing** — The twilight sensor is introduced, which indicates whether
it is dark outside. Whoever composes the system chooses whether to fit it, and the choice does not change
afterwards; the chapter describes how to write that the entity must work in both cases. `bcdd` checks the two cases separately and,
when the sensor is absent, lists what is missing without considering it an error.

**20. Several forms of the same thing: variants** — The chapter deals with four different installations in a single
entity: ceiling light or wall light, button or presence sensor. Between ceiling light and wall light only one is
chosen, and this choice combines with the one between button and sensor; the description, however, does not state which one is
chosen. The chapter describes how to write these variants; `bcdd` checks every combination and lists them all.

### Part three — Guarantees that a tool can check

In chapters 1-20 the guarantees are written in words and checked by a person. This part describes how
to write them as formulas, which a program can check without the intervention of a person, and how
to read the results of the check. `bcdd` reads the formulas of chapters 21-23 and checks their form, names and
types; their evaluation on scenarios and the recording verification of chapter 24 are not performed by
any program described in the manual.

**21. The step and the first formulas** — The guarantee “when the button is pressed, the light switches
on” becomes a formula. A formula describes the behaviour of the system step by step; its basic keywords are
“always”, “eventually”, “whenever… then” and “while”, and “in the same step” specifies the consequence of
“whenever… then”. The comparison and arithmetic operators are introduced, together with their precedence. The
guarantee changes form, but keeps its name.

**22. Time in formulas** — The guarantee “the light switches off 90
seconds after the last press” is written as a formula. For this purpose the chapter introduces the forms for expressing “within a certain time”, the time
elapsed since an event, the number of times an event has occurred, the filter on the parameters of an event and the
value that a state had in the previous step; finally, repeating scenarios.

**23. Shorthands** — The guarantee “the light is never on if nobody has pressed” can be written in
short form and in expanded form. Some forms are in fact shorthands: each one has an expanded form, written
with the formulas of chapters 21 and 22, which has the same meaning. The chapter also introduces the closed set of
transitions of a state, computed constants, functions, derived events, named types, records and
indexed states.

**24. The meaning of “verified”** — Starting from the CSC of the light written with formulas, the chapter
shows that verification takes place at two moments: on the text, before construction, and on the recordings of
a built system. The chapter also explains why the judgement of a person is never combined with the result of a
program and why “satisfied on the trace” holds only for what has been observed. Finally it describes what happens
when an assumption is not satisfied and which checks `bcdd` performs.

### Part four — Beyond behaviour

The previous parts describe what the system does. This part describes how the system concretely appears
to the outside, how it is tested, and how to proceed when the keywords of the language are not enough. `bcdd` reads the
blocks of these three chapters and checks them against the names of the CSC they are bound to.

**25. The concrete form of boundaries** — The command that the button sends to the lamp is, in concrete terms, a
contact closed on terminal 3 for at least 50 milliseconds; the relay that switches on the lamp, on the other hand, is not observable
by the person on the stairs. The chapter describes the concrete forms in which a boundary appears, whether
it is a terminal, a text on the screen or a file format, and the single criterion by which it is decided
what to write: “who sees it?”. Concrete forms are written in a `BINDING` block.

**26. The verification plan** — To test the light a verification plan is prepared: a light sensor
in front of the lamp and a camera that films the button and the lamp. The `VERIFICATION` block states
which instruments record a boundary and at what resolution; `bcdd` computes which guarantees each instrument observes and
which remain not executed.

**27. Extensions and profiles** — The aim is to specify that the light does not switch off instantaneously but
dims gradually over two seconds, and the language provides no form to express it. The chapter describes how to add
a new form, with its meaning and the way to verify it. It also describes how to collect the forms of a field of use
in a profile that a CSC imports, and what trial words are, which a revision of the language can move into a
profile.

### Part five — Application to a real system

This part applies the topics of the previous chapters, first to a real case, then by taking up the example again
from beginning to end.

**28. A real case: the audio measurement kit** — The description of a real, larger
system is examined: an audio measurement kit, with two choices for the level sensor and an optional part, the direct
box, which takes the signal from the loudspeaker terminals. The chapter introduces no new topics: the topics of the previous chapters reappear in the description and in
the `bcdd` report.

**29. The complete procedure, from beginning to end** — The staircase light is rewritten from scratch,
using the four `bcdd` commands in sequence. The chapter also states what the program does not do: it does not
judge whether a guarantee is correct, it does not interpret the text in quotation marks and it does not compare two versions of the
same CSC.

### Appendices

**A. Keywords, in the order in which they are introduced** — For each keyword of the language, the
chapter in which it is described.

**B. What `bcdd` checks** — The errors reported by the program, described in words and
accompanied by the code that appears in the report; what `bcdd` does not check.

**C. Glossary** — The terms of the manual with their meaning.

---

## Chapter 1 — The boundary and the guarantee

Consider the staircase light of a block of flats. Whoever enters the entrance hall presses the button and the light
switches on; after a certain time, with no further action, the light switches itself off. If the button is pressed
again while the light is still on, the light stays on longer; this behaviour is dealt with in
chapters 8 and 9.

The consumer of the light does not know how it works inside. Behind the wall there may be a relay, an electronic
timer or a small computer, and knowing it is not necessary. Only two pieces of information are needed: what can
be done, that is pressing, and what is expected as a result, that is that the light stays on for the time needed
to climb the stairs.

The manual describes how to write these two pieces of information precisely.

### The boundary

The lighting installation is a **system**. In the manual the term denotes any element of the
description, small or large: an installation, a program, an appliance are all systems.

Between the consumer of the light and the lighting installation there is an interface, consisting of the button pressed and the
light observed: it is the **boundary**. In general, a boundary is the interface between a system and another
counterpart, a person or another system, at which what passes between the two can be observed. Every boundary
has two **sides**: in the example, on one side there is the person on the stairs, on the other the installation.

The boundary of the staircase light is crossed by two elements:

- from the person on the stairs to the installation, the button pressed;
- from the installation to the person on the stairs, the light, on or off.

For now the button and the light are treated as a single boundary; in chapter 11 the boundary is split
in two.

What happens behind the boundary cannot be observed from outside. For the person on the stairs the installation is a
**black box**: a system of which only what goes in and what comes out is known.

### The guarantee

On a boundary, one of the two sides makes a commitment to the other. The lighting installation, for example,
commits itself as follows: “if the button is pressed, the light switches on”. A sentence of this kind is a **guarantee**:
it states what one side of the boundary guarantees to whoever is on the other side.

A guarantee concerns only what is observed at the boundary. “If the button is pressed, the light switches on” is
admissible, because the button pressed and the light are both at the boundary; “the relay closes” is not,
because the relay is inside the box and the person on the stairs cannot observe it.

### The verification

A guarantee is useful only if it can be verified. “The light works well” cannot: it does not state for whom, nor by
what measure. “The light switches on when the button is pressed”, by contrast, can be verified: one presses and
observes. So can “the light switches off sixty seconds after the last press”, with a stopwatch.

For this reason every guarantee is accompanied by its **verification**: who checks that it is satisfied, and how. A
guarantee without verification is not wrong, but it is incomplete.

### Why write it down

Consider two people: the building manager, who wants the staircase light, and the electrician,
who has to build it. An oral agreement leaves each of the two with a different memory; if instead the guarantees
are written down before work begins, the two have a text on which they agree. When the work is
finished the same text serves for acceptance testing: for each guarantee the corresponding verification is performed.

A guarantee that has just been written is **pending approval**: it becomes an actual commitment only when it is approved by
whoever has the authority to do so, in this case the building manager. How the approval is written is described in
chapter 7.

BCDD is intended above all for systems much larger than a light, in which this agreement is even more
important. A large system is divided into **parts**, that is into smaller systems, and each part is described only
through its own boundaries, like the staircase light. Whoever builds a part receives only the description of its
boundaries. This may be a person or a **language model**, that is a program, trained on large amounts of
text, that generates text and code from instructions written in natural language. The rule is the same for both: the description of the boundaries must be enough to establish what to
do, without any need to know the inside of the other parts.

Building the system that keeps the guarantees is called **implementing** it; the built system, with all its
internal choices, is the **implementation**.

### What is not written

The internal construction of the system is not written: no wires, programs, circuit boards, calculation
formulas or internal sequences of operations between one part and another are written. These are choices of whoever implements the system; if they were written,
whoever implements it could no longer change them, not even on finding a better way to keep the same
guarantees.

For the same reason **where** the system is located is not written: on which wall, in which program, on which
appliance. This too is a choice of whoever implements it.

### The names

The acronym **BCDD** stands for *Behavioural Contract-Driven Design*, that is design driven by
contracts on behaviour. **Behaviour** is what is observed from outside: what goes in, what
comes out and at what moment. A **contract** is the set of approved guarantees on a boundary, that is a commitment
accepted by both sides; from chapter 3 onwards it also includes the approved assumptions.

The written description of a boundary is called a **CSC**, from *Capability State Contract*: a
contract on what can be requested and on what can be observed. The name contains the word “contract”
because a CSC, once approved, is a contract in every respect. The first CSC is presented in
chapter 2.

### Summary

- The **boundary** is the interface between a system and a person or another system, and it has two sides.
- On that boundary, a **guarantee** states what one side guarantees to the other; it concerns only what is
  observed at the boundary.
- A guarantee is complete only with its **verification**: who checks it, and how. Until it is approved,
  the guarantee is “pending approval”.
- The internal construction of the system and its location are not written: they are decided by whoever implements it.
- The written description of a boundary is called a **CSC**.

### Special cases

**Guarantee that cannot be verified.** A guarantee such as “the light is convenient” is a valid text, but it is of no use to
either side: the electrician has no indication of what to build and acceptance testing has nothing to measure. As
chapter 2 shows, `bcdd` reports an error for a guarantee without the verification line; it is up to whoever writes
the CSC, instead, to judge whether the written verification makes sense.

**Internal element: not indicated.** A relay, even if the electrician has to install and wire it, is a
choice of whoever implements the system and is not written in the guarantee. The case is different when someone
outside the box must use a specific terminal: that terminal is then part of what is observed at the boundary,
and the case is dealt with in chapter 25.

**System with more boundaries.** The staircase light has more than one boundary, as shown in chapter 11. In
this chapter only one is considered: the one between the person on the stairs and the installation.

---

## Chapter 2 — The first CSC

In chapter 1 the staircase light is described in words. In this chapter the same description is
written in a file, in a form that a program can read.

### The file

A CSC is a text file with the extension `.csc`, which is opened and edited with any text editor.
The file `UsoLuce.csc` describes the staircase light from the point of view of the person on the stairs:

```
-- The staircase light, as seen by the person on the stairs.

CSC UsoLuce VERSION 0.1
  PURPOSE "The person on the stairs presses a button and has light to go up or down"

  EVENT IN  premuto
  STATE     accesa : Boolean INITIAL false

  GUARANTEE g1: VERBAL "When someone presses the button, the light switches on"
                VERIFY BY JUDGEMENT "a person who presses the button and watches"
  GUARANTEE g2: VERBAL "The light switches off by itself after a while"
                VERIFY BY JUDGEMENT "a person with a watch"
END
```

The file consists of thirteen lines, described below one at a time.

### Line by line

The first line begins with two hyphens, `--`: it is a **comment**, that is a note for the reader, which the
program ignores. A comment can appear anywhere, even at the end of a line.

`CSC UsoLuce VERSION 0.1` opens the description. `CSC` marks the beginning of a CSC; `UsoLuce` is the name
given to the CSC; `VERSION 0.1` is its version number. When the CSC changes, the number changes too
(chapter 10).

The words written in upper case, such as `CSC`, `VERSION` and `PURPOSE`, are the **keywords** of the language:
fixed words, in English, that the program recognises. Everything else is chosen by the writer.

`PURPOSE` introduces the **purpose**, a sentence that states what the boundary is for. It is the first line to
write and also the most important, because the rest of the CSC serves to make this sentence precise.

`EVENT IN premuto` states what **arrives** at the boundary from the other side: someone presses the button. It
is an **input event**. An event is something that happens at an instant and is then over; `premuto`
is the name given to the event.

`STATE accesa : Boolean INITIAL false` states instead what **is observed** at the boundary at every instant: whether the
light is on. A **state**, unlike an event, does not happen and then end: it always has a value.
After the colon its **type** is given, that is the set of values it can take. `Boolean` denotes a logical
value, true or false, written `true` or `false`. `INITIAL false`, finally, is the **initial value**: when the installation starts the
light is off.

The first guarantee is `GUARANTEE g1: VERBAL "…"`. `GUARANTEE` is the keyword for a guarantee. `g1` is its
**short name**, which serves to cite the guarantee in the program's reports and in documents. `VERBAL` indicates
that the guarantee is written in words, in a natural language, as it would be written for a person. The text
is enclosed in quotation marks; a text in quotation marks is called a **string**.

Immediately below, `VERIFY BY JUDGEMENT "…"` is the verification of that guarantee. `JUDGEMENT` means “by
judgement”: a person performs a test and judges. The quotation marks enclose who judges and on what. If
instead it is enough to examine something already written or recorded, `VERIFY BY INSPECTION` is used, “by
inspection”: for example `VERIFY BY INSPECTION "the log of switch-ons"`.

The second guarantee, `g2`, has the same form. The expression “after a while” is vague; for now it is
acceptable, and in chapter 8 it is made precise.

Finally, `END` closes the description.

### Three writing rules

A CSC like this one is written following three rules.

1. Every line, except comments and blank lines, begins with a keyword, in English and in upper case.
   Other keywords (`VERSION`, `INITIAL`, `VERBAL`, `BY`) appear inside the line. Spaces at the
   beginning of a line serve only the reader: the program ignores them.
2. Free text, that is purpose, guarantees and verifications, goes in quotation marks, in the language chosen by the writer. The names
   chosen by the writer, such as `UsoLuce`, `premuto` and `accesa`, can also be in Italian.
3. Every `GUARANTEE` has its `VERIFY`, normally written on the following line.

### This CSC is already valid

A CSC written entirely in words, like this one, is already valid and is sufficient as a starting point: a
person or a language model can already implement the light from it. It remains vague, however, because “after
a while” does not state how long; precision is added in the following chapters. The two guarantees, moreover, are
still pending approval.

From chapter 21 onwards the guarantees are also written in forms that a program can check
on its own. Each new form is added when it is needed, one line at a time.

### The first check

The program is called `bcdd`. It is a command-line program: it is started by typing its name in the
terminal. If it is distributed together with the manual, the executable is the file `bcdd`, and there are two
possibilities. The first is starting it from the folder that contains the `.csc` file, giving the path of the
executable. The second is copying it into a folder included in the program search path (`PATH`) and starting it by
name only, as in the examples of this manual.

The `bcdd check` command reads a `.csc` file and reports whether it is written correctly and what it contains; the file
is never modified. The **option** `--strict`, that is an addition to the command that changes its
behaviour, makes the check stricter, in the way described below.

```
$ bcdd check --strict UsoLuce.csc
bcdd check --strict UsoLuce.csc
lines: 13 (recognised 9, comments 1, blank 3, unrecognised 0)
blocks: 1
  line 3: CSC UsoLuce VERSION 0.1, without STATUS

1. ERRORS: 0

2. DEGREE OF THE CONTRACTUAL LINES
  verbal: 2
  formal: 0
  declared extension: 0
  unrecognised: 0
  line 9: GUARANTEE g1 verbal
  line 11: GUARANTEE g2 verbal

3. UNDECIDED: 0

4. PENDING APPROVAL, NOT CONTRACT: 2
  line 9: GUARANTEE g1
  line 11: GUARANTEE g2

5. UNRECOGNISED LINES: 0

6. UNDECLARED TYPES: 0

7. CSCs NAMED BUT NOT CHECKED: 0

outcome: no errors
```

The report is read from the top.

At the start of the report `bcdd` gives the number of lines of the file (`lines`). Each line belongs to exactly one category (recognised, comment,
blank or unrecognised), so that no line is lost. Next comes the list of **blocks** (`blocks`), that is of the
descriptions contained in the file: here there is only one, the CSC at line 3. The label `without STATUS` indicates that
it has not yet been written whether the CSC is pending approval or approved. In the absence of an indication, “pending
approval” applies; the corresponding syntax is described in chapter 7.

Section 1 lists the **errors** (`ERRORS`), that is the constructs that the program recognises but that are written
incorrectly. In this case there are none.

Section 2 concerns the **contractual lines**, those that enter the contract when they are approved:
for now, the guarantees. For each one the **degree** is given, that is the way in which the guarantee is written: in
words (`verbal`, in the sense of “made of words”) or as a formula that a program can check
(`formal`). The two guarantees of the example are written in words.

Section 4 lists the guarantees **pending approval**, which the report lists under `PENDING APPROVAL, NOT CONTRACT`: a guarantee
pending approval, until it is approved, is not part of the contract. For now this is the
expected situation.

Section 5 lists the lines that the program **has not recognised**. Sections 3, 6 and 7 are described in the
chapters in which they become relevant.

The last line is the **outcome** (`outcome`). The outcome `no errors` means that the file is written correctly, not that
the guarantees are correct: that assessment is up to whoever writes the CSC.

With the `--strict` option a single unrecognised line is enough for the check to have a negative outcome. Its
systematic use is recommended.

### Summary

- A CSC is a `.csc` file: it begins with `CSC Name VERSION number` and ends with `END`.
- It contains the purpose (`PURPOSE`), what arrives (`EVENT IN`), what is observed with its initial value
  (`STATE … INITIAL`) and the guarantees in words (`GUARANTEE … VERBAL`).
- Immediately below each guarantee is its verification: `VERIFY BY JUDGEMENT` or `VERIFY BY INSPECTION`.
- A CSC written entirely in words is already valid, but its guarantees remain pending approval.
- `bcdd check --strict` checks the form of the file without modifying it; `no errors` does not mean that the
  guarantees are correct.

### Special cases

**Missing verification.** If the `VERIFY` line below `g2` is removed, the report shows:

```
1. ERRORS: 1
  line 11: [E13] VERBAL without VERIFY: VERIFY BY JUDGEMENT or INSPECTION and a string are needed
```

This is an error, because a guarantee without verification is incomplete (chapter 1). The code in square
brackets, `E13`, makes it possible to look up the error in appendix B.

**Missing purpose.** The absence of the `PURPOSE` line is also an error:

```
1. ERRORS: 1
  line 3: [E10] PURPOSE missing in CSC UsoLuce
```

**Repeated short name.** If the second guarantee is also called `g1`, the program reports it at the second one,
because a short name serves to cite a single guarantee:

```
1. ERRORS: 1
  line 11: [E01] name already used at line 9: g1
```

**Keyword in lower case.** If `guarantee g2:` is written instead of `GUARANTEE g2:`, the program does not
report an error, because the line does not match any form of the language. The line is classified among the unrecognised
lines, and with it the verification line too, which is left without its guarantee:

```
5. UNRECOGNISED LINES: 2
  line 11: guarantee g2: VERBAL "The light switches off by itself after a while"
  line 12: VERIFY BY JUDGEMENT "a person with a watch"
```

Without `--strict` the report of the line appears in the outcome line: `outcome: no errors; unrecognised lines: 2 (see section 5)`.
An unrecognised line is therefore always reported; with `--strict` the check has a negative outcome.

**State without initial value.** The line `STATE accesa : Boolean`, without `INITIAL false`, is not
recognised:

```
5. UNRECOGNISED LINES: 1
  line 7: STATE     accesa : Boolean
…
outcome: no errors; unrecognised lines: 1 (--strict)
```

A state always has a value, even at the first instant: for this reason the initial value is mandatory.

**Guarantee written as a formula.** A guarantee such as `GUARANTEE g1: WHENEVER premuto THEN accesa AT ONCE`
is not written in words but as a formula: `bcdd` reads it and checks its names. Formulas are described starting
from chapter 21; up to chapter 20 guarantees are written in words.

---

## Chapter 3 — Assumptions

Guarantee `g1` of chapter 2, “when someone presses the button, the light switches on”, presupposes a
behaviour of the person on the stairs: that the button is actually pressed, and not merely brushed. A
contact of a few milliseconds may be indistinguishable from electrical noise, and the installation is not
required to recognise it. The chapter describes how to write what a guarantee presupposes.

### The assumption

An **assumption** is a condition on the behaviour of whoever is on the other side of the boundary, a condition
on which a guarantee depends. For the staircase light the assumption is: whoever presses the button holds it down for at least a tenth
of a second.

The guarantee depends on the assumption. If the button is held down for a tenth of a second or more, the
light must switch on; if it is only brushed, the light may not switch on, and in that case the guarantee is not
violated, because the assumption on which it rests is not satisfied.

An assumption is written only if a guarantee depends on it. A behaviour of the other side on which no
guarantee depends is not an assumption and is not written in this CSC.

### The ASSUME line

The file `UsoLuce.csc` with the assumption:

```
-- The staircase light, as seen by the person on the stairs.

CSC UsoLuce VERSION 0.1
  PURPOSE "The person on the stairs presses a button and has light to go up or down"

  EVENT IN  premuto
  STATE     accesa : Boolean INITIAL false

  GUARANTEE g1: VERBAL "When someone presses the button, the light switches on"
                VERIFY BY JUDGEMENT "a person who presses the button and watches"
  GUARANTEE g2: VERBAL "The light switches off by itself after a while"
                VERIFY BY JUDGEMENT "a person with a watch"
  ASSUME    a1: VERBAL "Whoever presses the button holds it down for at least a tenth of a second"
                VERIFY BY JUDGEMENT "a person who observes how the button is pressed"
END
```

`ASSUME` means “assumes”. The line has the same form as a guarantee: a short name (`a1`), the text in
words introduced by `VERBAL` and, normally on the following line, the verification. The verification of an assumption states who checks
that the other side behaves as expected, and how.

Guarantees and assumptions together are the **contractual lines** of the CSC: they enter the contract when they are
approved. The short names of guarantees and assumptions belong to the same set, so an assumption cannot
have the same name as a guarantee.

The file does not state which guarantee an assumption depends on: the link is derived from the text. In the example,
`a1` concerns the pressing of the button, so `g1` depends on it.

### The report

```
$ bcdd check --strict UsoLuce.csc
bcdd check --strict UsoLuce.csc
lines: 15 (recognised 11, comments 1, blank 3, unrecognised 0)
blocks: 1
  line 3: CSC UsoLuce VERSION 0.1, without STATUS

1. ERRORS: 0

2. DEGREE OF THE CONTRACTUAL LINES
  verbal: 3
  formal: 0
  declared extension: 0
  unrecognised: 0
  line 9: GUARANTEE g1 verbal
  line 11: GUARANTEE g2 verbal
  line 13: ASSUME a1 verbal

3. UNDECIDED: 0

4. PENDING APPROVAL, NOT CONTRACT: 3
  line 9: GUARANTEE g1
  line 11: GUARANTEE g2
  line 13: ASSUME a1

5. UNRECOGNISED LINES: 0

6. UNDECLARED TYPES: 0

7. CSCs NAMED BUT NOT CHECKED: 0

outcome: no errors
```

The assumption appears in sections 2 and 4 next to the guarantees: it is a contractual line written in words and,
like the guarantees, it is still pending approval.

### When an assumption is not satisfied

If an assumption is not satisfied, the guarantee that depends on it is not violated: the outcome indicates that the
other side did not behave as expected. In the verification of a real installation this outcome is called **assumption not
satisfied** and is distinct from a violated guarantee (chapter 24).

For this reason an assumption must be written with the same care as a guarantee. An assumption that is too broad, for
example “whoever presses the button uses it correctly”, in effect cancels the guarantee: any failure of the installation
could be attributed to incorrect use.

### Summary

- An **assumption** (`ASSUME`) is a condition on whoever is on the other side of the boundary, a condition on
  which a guarantee depends.
- It is written only if a guarantee depends on it, with the same form as a guarantee: short name, text and
  verification.
- If the assumption is not satisfied, the guarantee that depends on it is not violated.
- Guarantees and assumptions are the contractual lines of the CSC and share the same set of short names.

### Special cases

**Assumption without verification.** If the `VERIFY` line below `a1` is removed, the report shows the same
error as for a guarantee without verification:

```
1. ERRORS: 1
  line 13: [E13] VERBAL without VERIFY: VERIFY BY JUDGEMENT or INSPECTION and a string are needed
```

**Short name already used by a guarantee.** If the assumption is called `g1`, like the first guarantee:

```
1. ERRORS: 1
  line 13: [E01] name already used at line 9: g1
```

**Obligation of the other side with no guarantee depending on it.** “The person on the stairs switches the light off on leaving” is not
an assumption of this CSC: no guarantee of the light depends on it. `bcdd` cannot
detect this, because it does not interpret the text in quotation marks; the assessment is up to whoever writes the CSC.

---

## Chapter 4 — The two sides of a boundary

A CSC describes a boundary, which has two sides (chapter 1). The chapter states from which side it is written and
how whoever is on the other side reads it. On the basis of this rule an element is added to the light that goes
from the installation to the person on the stairs: a warning shortly before it switches off.

### Provider and consumer

Of the two sides of a boundary, one keeps the guarantees and the other makes use of them:

- the **provider** is the side that keeps the guarantees of the CSC; in the example, the lighting installation;
- the **consumer** is the side that satisfies the assumptions and relies on the guarantees; in the example, the person on the
  stairs.

A CSC is always written from the provider's side. The lines of the file must therefore be read from the point of view
of the installation:

| Line | From the provider's side | From the consumer's side |
|---|---|---|
| `EVENT IN` | what arrives at it | what it sends |
| `EVENT OUT` | what it sends | what arrives at it |
| `STATE` | what it shows | what it observes |
| `GUARANTEE` | what it guarantees | what can be relied on |
| `ASSUME` | what it presupposes | what it must satisfy |

The consumer reads the same lines the other way round. The CSC is not rewritten from the consumer's side: there is only one
description for each boundary, shared by both sides.

### The output event

The warning is something that happens at an instant and goes from the installation to the person on the stairs. From the provider's
side it is therefore an **output event**, written with `EVENT OUT`:

```
-- The staircase light, as seen by the person on the stairs.

CSC UsoLuce VERSION 0.1
  PURPOSE "The person on the stairs presses a button and has light to go up or down"

  EVENT IN  premuto
  EVENT OUT avviso
  STATE     accesa : Boolean INITIAL false

  GUARANTEE g1: VERBAL "When someone presses the button, the light switches on"
                VERIFY BY JUDGEMENT "a person who presses the button and watches"
  GUARANTEE g2: VERBAL "The light switches off by itself after a while"
                VERIFY BY JUDGEMENT "a person with a watch"
  GUARANTEE g3: VERBAL "Shortly before switching off, the light gives a warning to the person on the stairs"
                VERIFY BY JUDGEMENT "a person on the stairs who waits for the light to switch off"
  ASSUME    a1: VERBAL "Whoever presses the button holds it down for at least a tenth of a second"
                VERIFY BY JUDGEMENT "a person who observes how the button is pressed"
END
```

The line `EVENT OUT avviso` declares only that the event exists. The moment at which the installation sends it is
established by guarantee `g3`: without a guarantee, nothing obliges the installation to send it. What the warning concretely consists of,
a short flash or an acoustic signal, is not written here (chapter 25).

The direction of an event indicates who has the obligation. An output event is a commitment of the provider, governed
by its guarantees; an input event is something that the provider receives, and for which it can only formulate
assumptions.

### The report

```
$ bcdd check --strict UsoLuce.csc
bcdd check --strict UsoLuce.csc
lines: 18 (recognised 14, comments 1, blank 3, unrecognised 0)
blocks: 1
  line 3: CSC UsoLuce VERSION 0.1, without STATUS

1. ERRORS: 0

2. DEGREE OF THE CONTRACTUAL LINES
  verbal: 4
  formal: 0
  declared extension: 0
  unrecognised: 0
  line 10: GUARANTEE g1 verbal
  line 12: GUARANTEE g2 verbal
  line 14: GUARANTEE g3 verbal
  line 16: ASSUME a1 verbal

3. UNDECIDED: 0

4. PENDING APPROVAL, NOT CONTRACT: 4
  line 10: GUARANTEE g1
  line 12: GUARANTEE g2
  line 14: GUARANTEE g3
  line 16: ASSUME a1

5. UNRECOGNISED LINES: 0

6. UNDECLARED TYPES: 0

7. CSCs NAMED BUT NOT CHECKED: 0

outcome: no errors
```

### Summary

- A CSC is written from the side of the **provider**, which keeps the guarantees; the **consumer** satisfies the assumptions and
  relies on the guarantees.
- The consumer reads the same lines the other way round: an output event of the provider is, for the consumer, an event
  that arrives.
- The **output event** (`EVENT OUT`) is an event that the provider sends to the other side; the moment of sending is
  established by the guarantees.
- Every boundary has a single CSC, shared by the two sides.

### Special cases

**The same name for input and output.** An event has a single name throughout the CSC. If the warning is also
called `premuto`:

```
1. ERRORS: 1
  line 7: [E01] name already used at line 6: premuto
```

**Event without direction.** The line `EVENT avviso`, without `IN` or `OUT`, is not recognised:

```
5. UNRECOGNISED LINES: 1
  line 7: EVENT avviso
…
outcome: no errors; unrecognised lines: 1 (--strict)
```

**The CSC written from the consumer's side.** A second CSC with `EVENT OUT premuto` and `EVENT IN avviso`, written
from the point of view of the person on the stairs, adds no information: it describes the same boundary with the
directions reversed and requires two descriptions to be kept aligned. A single CSC is written, from the provider's
side.

---

## Chapter 5 — Requests

The caretaker of the block of flats asks that, during cleaning, the light stay on for a set time. This
request is not a simple press of the button: the installation can accept it or reject it and, if it accepts it,
it can conclude it with a successful or a failed outcome. The chapter describes how to write a request.

### The request

A **request** is what the consumer can ask of the provider. It takes place in two successive phases:

1. the **response**: the request is accepted or rejected;
2. the **outcome**: an accepted request concludes with a successful or a failed outcome.

An input event, by contrast, simply happens: it has neither a response nor an outcome.

In the file the request is written with `CAPABILITY`, which indicates a capability of the provider:

```
  CAPABILITY Pulizie(durata: Duration)
```

`Pulizie` is the name of the request. The parentheses enclose its **parameters**, that is the values that
accompany the request: here a single parameter, `durata`, of type `Duration`, that is a length of time. Each
parameter is written as `name : type`; several parameters are separated by a comma. Types are described in
chapter 6.

### The lifecycle

The phases of a request have five fixed names, in English; together they make up the **lifecycle** of the
request:

| Name | Meaning | Produced by |
|---|---|---|
| `requested` | the request has been made | consumer |
| `accepted` | the request has been accepted | provider |
| `rejected` | the request has been rejected | provider |
| `completed` | the accepted request has succeeded | provider |
| `failed` | the accepted request has failed | provider |

These names are used in scenarios (chapter 9).

The lifecycle fixes only the order of the phases and imposes no obligation. The guarantees establish when a
request is accepted or rejected, how long it lasts and when it fails: every obligation must be written as a
guarantee.

### The CSC with the request

```
-- The staircase light, as seen by the person on the stairs and by the caretaker.

CSC UsoLuce VERSION 0.1
  PURPOSE "The person on the stairs presses a button and has light to go up or down"

  CAPABILITY Pulizie(durata: Duration)
  EVENT IN   premuto
  EVENT OUT  avviso
  STATE      accesa : Boolean INITIAL false

  GUARANTEE g1: VERBAL "When someone presses the button, the light switches on"
                VERIFY BY JUDGEMENT "a person who presses the button and watches"
  GUARANTEE g2: VERBAL "The light switches off by itself after a while"
                VERIFY BY JUDGEMENT "a person with a watch"
  GUARANTEE g3: VERBAL "Shortly before switching off, the light gives a warning to the person on the stairs"
                VERIFY BY JUDGEMENT "a person on the stairs who waits for the light to switch off"
  GUARANTEE g4: VERBAL "A cleaning request is rejected if the requested duration exceeds two hours; otherwise it is accepted"
                VERIFY BY JUDGEMENT "the caretaker, who requests cleaning with different durations"
  GUARANTEE g5: VERBAL "After an accepted request the light stays on for the whole requested duration; when it expires the request has succeeded"
                VERIFY BY JUDGEMENT "the caretaker, with a watch"
  GUARANTEE g6: VERBAL "If the light cannot stay on until the duration expires, the request has failed"
                VERIFY BY JUDGEMENT "the caretaker, who removes the lamp during cleaning"
  ASSUME    a1: VERBAL "Whoever presses the button holds it down for at least a tenth of a second"
                VERIFY BY JUDGEMENT "a person who observes how the button is pressed"
END
```

The three new guarantees concern the two phases of the request: `g4` establishes the response, `g5` and `g6`
the outcome. Without `g4` the CSC would allow the installation to reject every request.

The caretaker is on the same side as the person on the stairs and is therefore a consumer too, as the comment
at the top of the file indicates.

### The report

```
$ bcdd check --strict UsoLuce.csc
bcdd check --strict UsoLuce.csc
lines: 25 (recognised 21, comments 1, blank 3, unrecognised 0)
blocks: 1
  line 3: CSC UsoLuce VERSION 0.1, without STATUS

1. ERRORS: 0

2. DEGREE OF THE CONTRACTUAL LINES
  verbal: 7
  formal: 0
  declared extension: 0
  unrecognised: 0
  line 11: GUARANTEE g1 verbal
  line 13: GUARANTEE g2 verbal
  line 15: GUARANTEE g3 verbal
  line 17: GUARANTEE g4 verbal
  line 19: GUARANTEE g5 verbal
  line 21: GUARANTEE g6 verbal
  line 23: ASSUME a1 verbal

3. UNDECIDED: 0

4. PENDING APPROVAL, NOT CONTRACT: 7
  line 11: GUARANTEE g1
  line 13: GUARANTEE g2
  line 15: GUARANTEE g3
  line 17: GUARANTEE g4
  line 19: GUARANTEE g5
  line 21: GUARANTEE g6
  line 23: ASSUME a1

5. UNRECOGNISED LINES: 0

6. UNDECLARED TYPES: 0

7. CSCs NAMED BUT NOT CHECKED: 0

outcome: no errors
```

### Summary

- A **request** (`CAPABILITY`) is what the consumer can ask of the provider; it has a **response**
  (accepted or rejected) and, if accepted, an **outcome** (succeeded or failed).
- **Parameters** are the values that accompany a request or an event, written as `name : type`.
- The five names of the **lifecycle** (`requested`, `accepted`, `rejected`, `completed`, `failed`) fix
  the order of the phases, not the obligations: these are written as guarantees.

### Special cases

**Parameter without the colon.** The line `CAPABILITY Pulizie(durata Duration)` is not recognised:

```
5. UNRECOGNISED LINES: 1
  line 6: CAPABILITY Pulizie(durata Duration)
…
outcome: no errors; unrecognised lines: 1 (--strict)
```

**Two parameters with the same name.** In `CAPABILITY Pulizie(durata: Duration, durata: Duration)` the second
parameter is a name already used:

```
1. ERRORS: 1
  line 6: [E01] name already used at line 6: durata
```

**Behaviour without a request.** The automatic switching off of the light is not a request: nobody requests it and it has
neither a response nor an outcome. It is written as a guarantee (`g2`), not with `CAPABILITY`.

**Request started by the provider.** A request started by the provider, that is without anyone requesting it, is
written by adding `AUTONOMOUS` at the end of the line, for example `CAPABILITY Collaudo AUTONOMOUS`. An
**autonomous request** has neither `requested` nor `rejected`: it begins already accepted and concludes with a
successful or a failed outcome. `bcdd` recognises this line.

---

## Chapter 6 — The types of values

The light now has three operating modes: off, on, and on for cleaning. The state `accesa`, which
can only be true or false, is no longer enough to describe them. The chapter introduces types, which establish
which values the states and parameters observed at the boundary can take.

### The type

The **type** of a state or of a parameter is the set of values it can take (chapter 2). The type is
written after the colon: `accesa : Boolean`, `durata: Duration`. `bcdd` recognises the following types:

| Type | Values | Example value |
|---|---|---|
| `Boolean` | true or false | `true`, `false` |
| `Integer [a .. b]` | integers from `a` to `b` | `3` |
| `Real [a .. b]` | real numbers from `a` to `b` | `0.5` |
| `String` | strings | `"second floor"` |
| `Duration` | durations, in seconds (`s`) or milliseconds (`ms`) | `60 s`, `250 ms` |
| `Sequence of T` | ordered sequences of values of type `T` | — |
| `Optional T` | a value of type `T`, or no value | — |

The **range** in square brackets, `[a .. b]`, is optional for `Integer` and `Real`: it limits the values
admitted. The decimal separator in numbers is the full stop. The units of a duration are only `s` and `ms`, written
after the number on the same line, with or without a space (`250 ms`, `50ms`).

### The list of values

None of the types in the table is suitable for the three modes of the light. A new type is therefore declared, defined
by a **list of values** that is given a name:

```
  TYPE       Modo := {spenta, accesa, in_pulizia}
```

`TYPE` introduces the declaration of a type; `Modo` is the name of the type; the curly braces enclose
its values, separated by commas. A value of this type can only be one of the three names in the list.
The values are names, not strings: they are written without quotation marks.

The state `accesa` is replaced by the state `modo`, of type `Modo`:

```
  STATE      modo : Modo INITIAL spenta
```

The initial value is one of the values of the list.

### The CSC with types

```
-- The staircase light, as seen by the person on the stairs and by the caretaker.

CSC UsoLuce VERSION 0.1
  PURPOSE "The person on the stairs presses a button and has light to go up or down"

  TYPE       Modo := {spenta, accesa, in_pulizia}

  CAPABILITY Pulizie(durata: Duration)
  EVENT IN   premuto
  EVENT OUT  avviso
  STATE      modo : Modo INITIAL spenta

  GUARANTEE g1: VERBAL "When someone presses the button, the light switches on"
                VERIFY BY JUDGEMENT "a person who presses the button and watches"
  GUARANTEE g2: VERBAL "The light switches off by itself after a while"
                VERIFY BY JUDGEMENT "a person with a watch"
  GUARANTEE g3: VERBAL "Shortly before switching off, the light gives a warning to the person on the stairs"
                VERIFY BY JUDGEMENT "a person on the stairs who waits for the light to switch off"
  GUARANTEE g4: VERBAL "A cleaning request is rejected if the requested duration exceeds two hours; otherwise it is accepted"
                VERIFY BY JUDGEMENT "the caretaker, who requests cleaning with different durations"
  GUARANTEE g5: VERBAL "After an accepted request the light stays on for the whole requested duration; when it expires the request has succeeded"
                VERIFY BY JUDGEMENT "the caretaker, with a watch"
  GUARANTEE g6: VERBAL "If the light cannot stay on until the duration expires, the request has failed"
                VERIFY BY JUDGEMENT "the caretaker, who removes the lamp during cleaning"
  GUARANTEE g7: VERBAL "During cleaning the mode is in_pulizia, and a press of the button does not change it"
                VERIFY BY JUDGEMENT "the caretaker, who presses the button during cleaning"
  ASSUME    a1: VERBAL "Whoever presses the button holds it down for at least a tenth of a second"
                VERIFY BY JUDGEMENT "a person who observes how the button is pressed"
END
```

The new guarantee `g7` refers to the mode `in_pulizia`. Guarantees `g1` to `g6` remain unchanged: they describe
the light on or off in words, without using the state `modo`, and their meaning does not change.

```
$ bcdd check --strict UsoLuce.csc
bcdd check --strict UsoLuce.csc
lines: 29 (recognised 24, comments 1, blank 4, unrecognised 0)
blocks: 1
  line 3: CSC UsoLuce VERSION 0.1, without STATUS

1. ERRORS: 0

2. DEGREE OF THE CONTRACTUAL LINES
  verbal: 8
  formal: 0
  declared extension: 0
  unrecognised: 0
  line 13: GUARANTEE g1 verbal
  line 15: GUARANTEE g2 verbal
  line 17: GUARANTEE g3 verbal
  line 19: GUARANTEE g4 verbal
  line 21: GUARANTEE g5 verbal
  line 23: GUARANTEE g6 verbal
  line 25: GUARANTEE g7 verbal
  line 27: ASSUME a1 verbal

3. UNDECIDED: 0

4. PENDING APPROVAL, NOT CONTRACT: 8
  line 13: GUARANTEE g1
  line 15: GUARANTEE g2
  line 17: GUARANTEE g3
  line 19: GUARANTEE g4
  line 21: GUARANTEE g5
  line 23: GUARANTEE g6
  line 25: GUARANTEE g7
  line 27: ASSUME a1

5. UNRECOGNISED LINES: 0

6. UNDECLARED TYPES: 0

7. CSCs NAMED BUT NOT CHECKED: 0

outcome: no errors
```

### Types described in words and undeclared types

A type can also be described in words, when its values cannot be listed:

```
  TYPE       Testo := VERBAL "the text shown by the display next to the button"
```

A **type described in words** has a name and a description in quotation marks; `bcdd` records its name but does not
interpret its description.

A type used in a state or in a parameter without being declared is an **undeclared type**. It is not an
error: `bcdd` lists it in section 6 of the report (`UNDECLARED TYPES`), with the line in which it is used. If
the state `STATE messaggio : Testo INITIAL ""` is added to `UsoLuce.csc` without the line `TYPE Testo`, the
report shows:

```
6. UNDECLARED TYPES: 1
  Testo: line 12
…
outcome: no errors
```

With the line `TYPE Testo := VERBAL "…"` in the same block, section 6 no longer lists anything.

### Summary

- The **type** establishes the values admitted for a state or a parameter; the basic types are `Boolean`,
  `Integer`, `Real`, `String`, `Duration`, `Sequence of`, `Optional`.
- A **list of values** is declared with `TYPE Name := {value, value, …}`; the values are names, without
  quotation marks.
- A type can be described in words with `TYPE Name := VERBAL "…"`.
- An undeclared type is not an error, but it appears in section 6 of the report.

### Special cases

**Value with the name of another element.** The values of a list belong to the same set of names as
states, events, requests and short names: a name cannot be used twice. If, next to the type `Modo`, the state
`STATE accesa : Boolean INITIAL false` is also left in place, the name `accesa` is used twice:

```
1. ERRORS: 1
  line 12: [E01] name already used at line 6: accesa
```

**Value outside the list.** With `INITIAL buia` the value does not belong to any list of the CSC:

```
1. ERRORS: 1
  line 11: [E03] name not declared as a value of TYPE: buia
```

**Value of a different type.** `bcdd` checks that the initial value belongs to the type of the state. In the line
`STATE modo : Modo INITIAL false` the value `false` is not a value of `Modo`:

```
1. ERRORS: 1
  line 11: [E25] value not of type Modo: false
```

The same check applies to the values written in scenarios (chapter 9).

**Range limits reversed.** `bcdd` does not check that the first limit of a range is less than or equal to the
second.

**Unrecognised units.** A duration written in minutes, `1 min`, is not recognised: it is written `60 s`.

**Other forms of types.** The language also provides the type `Record {…}`, which groups several fields, each with
a name, and the named type `TYPE Name := Type`, described in chapter 23. The value `ABSENT` indicates that a value
of type `Optional` is absent: `STATE ultimo : Optional Modo INITIAL ABSENT` is a state that initially has no value.

---

## Chapter 7 — Pending approval and approved

The contractual lines written so far are all pending approval: the report lists them in section 4,
`PENDING APPROVAL, NOT CONTRACT`. The chapter indicates who approves them, how the approval is written in the file and with
which `bcdd` command it is recorded.

### Who approves

A contractual line becomes **approved** only by decision of whoever has the authority to do so:
in the example, the building manager. Neither `bcdd` nor a language model ever approves a line.

The approval decision is recorded elsewhere, for example in the register of decisions of the block of flats, with
an identifier. In the file the **decision reference** is written: the prefix `D-` followed by digits only,
for example `D-7`. Over time, the reference makes it possible to trace who approved and for what
reason.

### The STATUS line

The approval status is recorded in the file with `STATUS`, in two forms:

- `STATUS HYPOTHESIS`: pending approval;
- `STATUS RATIFIED BY D-7`: approved with decision `D-7`.

`HYPOTHESIS` means “hypothesis”, that is pending approval; `RATIFIED BY` means “ratified by”, that is approved. In
the output of `bcdd`, an approved line “is part of the contract”.

`STATUS` is written in two positions. In the header it applies to the whole CSC. The **header** consists of the
`CSC` line and of the lines that follow it before the **body**, that is before the lines that describe the
boundary: `PURPOSE`, any `STATUS` and any `IMPORT PROFILE` (chapter 27), in any order. In the examples of the
manual `STATUS` immediately follows the `CSC` line. After the short name of a contractual line, instead,
`STATUS` applies only to that line:

```
  GUARANTEE g1 STATUS RATIFIED BY D-7: VERBAL "When someone presses the button, the light switches on"
```

If a contractual line has its own `STATUS`, that one applies; otherwise the `STATUS` of the header applies.
In the absence of any `STATUS`, the line is pending approval: nothing becomes approved without a written decision.

### The skeleton of a new file

The `bcdd new` command creates the skeleton of a new CSC in the current folder:

```
$ bcdd new UsoLuce
created UsoLuce.csc
```

The file created is the following:

```
-- CSC created by bcdd new. It is filled in by hand; bcdd check checks the form.
-- Without STATUS RATIFIED no line is part of the contract: it is pending approval until the operator approves it.

CSC UsoLuce VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "to be filled in: in one sentence, what UsoLuce is responsible for"

  -- Inputs and outputs (uncomment and fill in):
  -- CAPABILITY Name(parameter: Type)        what can be requested
  -- EVENT IN   name(parameter: Type)        what arrives from outside
  -- EVENT OUT  name(parameter: Type)        what goes out
  -- STATE      name : Type INITIAL value    what is visible from outside

  -- Guarantees in words:
  -- GUARANTEE g1: VERBAL "what it guarantees"
  --               VERIFY BY JUDGEMENT "who judges, and on what"
END
```

The skeleton contains only the header with `STATUS HYPOTHESIS`, the purpose to be filled in, and `END`; the other
forms are suggested in comments, to be completed and activated by removing the two hyphens. `bcdd new` never
overwrites an existing file.

### The CSC pending approval

With the explicit `STATUS` in the header, the CSC of chapter 6 becomes:

```
-- The staircase light, as seen by the person on the stairs and by the caretaker.

CSC UsoLuce VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "The person on the stairs presses a button and has light to go up or down"

  TYPE       Modo := {spenta, accesa, in_pulizia}

  CAPABILITY Pulizie(durata: Duration)
  EVENT IN   premuto
  EVENT OUT  avviso
  STATE      modo : Modo INITIAL spenta

  GUARANTEE g1: VERBAL "When someone presses the button, the light switches on"
                VERIFY BY JUDGEMENT "a person who presses the button and watches"
  GUARANTEE g2: VERBAL "The light switches off by itself after a while"
                VERIFY BY JUDGEMENT "a person with a watch"
  GUARANTEE g3: VERBAL "Shortly before switching off, the light gives a warning to the person on the stairs"
                VERIFY BY JUDGEMENT "a person on the stairs who waits for the light to switch off"
  GUARANTEE g4: VERBAL "A cleaning request is rejected if the requested duration exceeds two hours; otherwise it is accepted"
                VERIFY BY JUDGEMENT "the caretaker, who requests cleaning with different durations"
  GUARANTEE g5: VERBAL "After an accepted request the light stays on for the whole requested duration; when it expires the request has succeeded"
                VERIFY BY JUDGEMENT "the caretaker, with a watch"
  GUARANTEE g6: VERBAL "If the light cannot stay on until the duration expires, the request has failed"
                VERIFY BY JUDGEMENT "the caretaker, who removes the lamp during cleaning"
  GUARANTEE g7: VERBAL "During cleaning the mode is in_pulizia, and a press of the button does not change it"
                VERIFY BY JUDGEMENT "the caretaker, who presses the button during cleaning"
  ASSUME    a1: VERBAL "Whoever presses the button holds it down for at least a tenth of a second"
                VERIFY BY JUDGEMENT "a person who observes how the button is pressed"
END
```

### Approval with bcdd ratify

The `bcdd ratify` command records in the file an approval decision that has already been taken. It requires as arguments
the file, what is approved and the decision reference. Usually the whole CSC is approved, with the `--all`
option:

```
$ bcdd ratify UsoLuce.csc --all D-7
approved with D-7 in CSC UsoLuce: 1 line
  line 4: CSC UsoLuce
contract: 8
```

Only one line changes in the file, the header:

```
  STATUS RATIFIED BY D-7
```

The command reports `1 line` because it modified only the `STATUS` of the header. The eight contractual
lines do not have a `STATUS` of their own and take that of the header: they are all approved, as indicated by
`contract: 8`. The report confirms it:

```
$ bcdd check --strict UsoLuce.csc
bcdd check --strict UsoLuce.csc
lines: 30 (recognised 25, comments 1, blank 4, unrecognised 0)
blocks: 1
  line 3: CSC UsoLuce VERSION 0.1, STATUS RATIFIED BY D-7

1. ERRORS: 0

2. DEGREE OF THE CONTRACTUAL LINES
  verbal: 8
  formal: 0
  declared extension: 0
  unrecognised: 0
  line 14: GUARANTEE g1 verbal
  line 16: GUARANTEE g2 verbal
  line 18: GUARANTEE g3 verbal
  line 20: GUARANTEE g4 verbal
  line 22: GUARANTEE g5 verbal
  line 24: GUARANTEE g6 verbal
  line 26: GUARANTEE g7 verbal
  line 28: ASSUME a1 verbal

3. UNDECIDED: 0

4. PENDING APPROVAL, NOT CONTRACT: 0

5. UNRECOGNISED LINES: 0

6. UNDECLARED TYPES: 0

7. CSCs NAMED BUT NOT CHECKED: 0

outcome: no errors
```

Section 4 is empty: the CSC of the light is approved in full, and it is now the contract between the building manager and
whoever implements the installation.

A single line can also be approved, by giving its short name. If the CSC is still pending approval:

```
$ bcdd ratify UsoLuce.csc g1 D-7
approved line 14: GUARANTEE g1 with D-7
```

In this case the command writes the `STATUS` in the line of `g1`, as in the example of the section “The STATUS line”;
the other lines remain pending approval.

`bcdd ratify` first performs the same check as `bcdd check --strict` and does not modify a file that does not
pass it. If the file passes, it modifies only the `STATUS` lines: the rest of the file remains identical.

### An approved line is not modified

An approved line is never modified again. To change an approved CSC a new version of it is written, with the
procedure of chapter 10.

Likewise, `STATUS RATIFIED BY` is not written by hand: it is written by `bcdd ratify`, on the basis of a
decision already taken. `bcdd check` does not distinguish a `STATUS RATIFIED BY` written by hand from one
written by the command.

### Summary

- A contractual line becomes **approved** only by decision of whoever has the authority to do so, never of the
  program or of a language model.
- In the file approval is recorded with `STATUS RATIFIED BY D-number`, where `D-number` is the **decision
  reference**; `STATUS HYPOTHESIS` indicates a line pending approval.
- The `STATUS` of the **header** applies to the lines that do not have one of their own; without any `STATUS`, a
  line is pending approval.
- `bcdd new` creates the skeleton of a CSC; `bcdd ratify` records the approval, of one line or of all of them
  (`--all`), modifying only the `STATUS` lines.

### Special cases

**File with errors.** `bcdd ratify` does not record the approval of a file that does not pass the check. If the
file contains `INITIAL buia` (chapter 6):

```
$ bcdd ratify UsoLuce.csc --all D-7
bcdd ratify: the file does not pass bcdd check --strict (errors: 1, unrecognised lines: 0): I am not approving
```

**Line already approved.** A line already approved is not approved again, not even with another decision:

```
$ bcdd ratify UsoLuce.csc g1 D-8
bcdd ratify: g1 is already part of the contract (line 14): I am changing nothing
```

**Invalid reference.** The reference must have the form `D-` followed by digits:

```
$ bcdd ratify UsoLuce.csc --all D7
bcdd ratify: invalid decision: D7 (D-number is needed)
```

The same message appears for a person's name in place of the reference, for example `amministratore`.

**Approval without reference.** A `STATUS RATIFIED` line lacking `BY` and the reference is an error:

```
1. ERRORS: 1
  line 4: [E04] STATUS RATIFIED without a decision: BY D-number is needed
```

**File already existing.** `bcdd new` does not overwrite a file with the same name:

```
$ bcdd new UsoLuce
bcdd new: UsoLuce.csc already exists: I am not overwriting it
```

---

## Chapter 8 — Making a guarantee precise

Guarantee `g2`, “the light switches off by itself after a while”, is approved but vague: it does not state how
long the light must stay on, so whoever implements the installation does not know it and acceptance testing has
no value to measure. The chapter describes how to make a guarantee precise without deleting it and how to submit
the CSC to a language model, which asks questions about the points that are still vague. It then describes how
to give a name to values and how to mark the numbers not yet decided.

### The detail

A **detail** is a contractual line that makes precise a guarantee or an assumption already written. It is
written with `DETAILS` followed by the short name of the line it makes precise:

```
  GUARANTEE g2a DETAILS g2: VERBAL "The light switches off 60 s after the last press, with a tolerance of 5 s"
                            VERIFY BY JUDGEMENT "a person who measures with a stopwatch the time between the last press and switch-off"
```

The line reads: guarantee `g2a`, detail of `g2`. The detail respects three rules:

1. **it adds, it does not replace**: `g2` remains in force, and `g2a` is added to it;
2. **it does not contradict**: there must exist a behaviour of the installation that satisfies both lines;
3. **it is pending approval when created**: a detail without a `STATUS` of its own is pending approval even if
   the guarantee it makes precise is approved. A detail does not follow the `STATUS` of the header.

The third rule makes it possible to add details under the guarantees of an approved CSC without their becoming
approved in the absence of a decision. Assumptions can be made precise in the same way.

A detail can in turn have details. The **level** of a line indicates how many steps of `DETAILS`
separate it from a line without `DETAILS`: `g2` has level 0, `g2a` level 1, a detail of `g2a` level 2.

### The language model's questions

The `bcdd refine` command submits the CSC to a language model, which asks questions about the vague points and, on the basis of
the answers, proposes new lines. A run of `bcdd refine` proceeds as follows:

1. the model asks at most five questions, each with some proposed answers. The reply is the number
   of a proposed answer or an answer of one's own; pressing Enter without typing anything skips the question;
2. on the basis of the answers, the model proposes new details or the replacement of lines pending approval;
3. each proposal is accepted (`y`) or discarded (`n`);
4. at the end the command asks for confirmation before writing the accepted proposals into the file; without
   the final confirmation the file does not change.

For the CSC of the light the run looks like this (the initial lines, which report the check of the file and the
call to the model, are omitted):

```
$ bcdd refine UsoLuce.csc
…
QUESTION 1 of 2
  How long after the last press must the light switch off, and with what tolerance?
  1) 30 seconds, with a tolerance of 5 seconds
  2) 60 seconds, with a tolerance of 5 seconds
  3) 3 minutes, with a tolerance of 10 seconds
answer (1 to 3, or write your own; press Enter alone to skip): 2
  choice 2: 60 seconds, with a tolerance of 5 seconds

QUESTION 2 of 2
  What effect does a press while the light is on have on the on-time?
  1) it restarts the count from the beginning
  2) it changes nothing
answer (1 to 2, or write your own; press Enter alone to skip): 1
  choice 1: it restarts the count from the beginning
…
PROPOSAL 1 of 2, details g2 (line 16)
  GUARANTEE g2a DETAILS g2 STATUS HYPOTHESIS: VERBAL "The light switches off 60 s after the last press, with a tolerance of 5 s"
                                              VERIFY BY JUDGEMENT "a person who measures with a stopwatch the time between the last press and switch-off"
accept? y = yes, n = no, q = quit (discards the rest): y

PROPOSAL 2 of 2, details g2 (line 16)
  GUARANTEE g2b DETAILS g2 STATUS HYPOTHESIS: VERBAL "A press while the light is on restarts the count of 60 s from the beginning"
                                              VERIFY BY JUDGEMENT "a person who presses the button again while the light is on and measures with a stopwatch the time until switch-off"
accept? y = yes, n = no, q = quit (discards the rest): y

summary: accepted 2, discarded by you 0, discarded by the check 0
write 2 proposals (4 lines) in UsoLuce.csc and 2 answers in UsoLuce.csc.dialogo? y = yes, n = no: y
written UsoLuce.csc: 2 proposals (4 lines)
written UsoLuce.csc.dialogo: 2 answers
```

The questions and proposals depend on the language model and vary from one run to another; those
shown are an example.

The questions and the answers given are kept in the file `UsoLuce.csc.dialogo`, next to the CSC; the output
reports the number of answers written. At the next run `bcdd refine` passes the answers already given to the
model, so that it does not ask the same questions again.

The proposals enter the file with an explicit `STATUS HYPOTHESIS`, immediately below the guarantee they make precise.
Lines 14-21 of the file become:

```
  GUARANTEE g1: VERBAL "When someone presses the button, the light switches on"
                VERIFY BY JUDGEMENT "a person who presses the button and watches"
  GUARANTEE g2: VERBAL "The light switches off by itself after a while"
                VERIFY BY JUDGEMENT "a person with a watch"
  GUARANTEE g2a DETAILS g2 STATUS HYPOTHESIS: VERBAL "The light switches off 60 s after the last press, with a tolerance of 5 s"
                                              VERIFY BY JUDGEMENT "a person who measures with a stopwatch the time between the last press and switch-off"
  GUARANTEE g2b DETAILS g2 STATUS HYPOTHESIS: VERBAL "A press while the light is on restarts the count of 60 s from the beginning"
                                              VERIFY BY JUDGEMENT "a person who presses the button again while the light is on and measures with a stopwatch the time until switch-off"
```


`bcdd refine` has four limits:

- everything it writes into the file is pending approval: the command never approves;
- it never replaces an approved line: under an approved guarantee, such as `g2`, it can only add
  details;
- it does not propose details beyond level 2;
- it does not create other CSC files: if it identifies a topic that would deserve a CSC of its own, it reports it with a name and
  a reason.

### The report

```
$ bcdd check --strict UsoLuce.csc
bcdd check --strict UsoLuce.csc
lines: 34 (recognised 29, comments 1, blank 4, unrecognised 0)
blocks: 1
  line 3: CSC UsoLuce VERSION 0.1, STATUS RATIFIED BY D-7

1. ERRORS: 0

2. DEGREE OF THE CONTRACTUAL LINES
  verbal: 10
  formal: 0
  declared extension: 0
  unrecognised: 0
  line 14: GUARANTEE g1 verbal
  line 16: GUARANTEE g2 verbal
  line 18: GUARANTEE g2a verbal
  line 20: GUARANTEE g2b verbal
  line 22: GUARANTEE g3 verbal
  line 24: GUARANTEE g4 verbal
  line 26: GUARANTEE g5 verbal
  line 28: GUARANTEE g6 verbal
  line 30: GUARANTEE g7 verbal
  line 32: ASSUME a1 verbal

3. UNDECIDED: 0

4. PENDING APPROVAL, NOT CONTRACT: 2
  line 18: GUARANTEE g2a
  line 20: GUARANTEE g2b

5. UNRECOGNISED LINES: 0

6. UNDECLARED TYPES: 0

7. CSCs NAMED BUT NOT CHECKED: 0

14. TO BE JUDGED: 2
  line 18: GUARANTEE g2a DETAILS g2: consistency between the line and the line that details it, one of the two in words
  line 20: GUARANTEE g2b DETAILS g2: consistency between the line and the line that details it, one of the two in words

outcome: no errors
```

The CSC remains approved with decision `D-7`; only the two new details appear in section 4.

Section 14, `TO BE JUDGED`, lists what can be established only by judgement. A detail in words must add
precision to the line it makes precise, without contradicting it; but `bcdd` does not interpret the meaning of
the text. Therefore, when the detail or the line it makes precise is written in words, the report states that
the consistency between the two remains to be judged. An entry in section 14 is not an error and does not change
the exit code. The section appears only when it has at least one entry.

The building manager approves the two details with a new decision:

```
$ bcdd ratify UsoLuce.csc --all D-9
approved with D-9 in CSC UsoLuce: 2 lines
  line 18: GUARANTEE g2a
  line 20: GUARANTEE g2b
contract: 10
```

With `--all` the command modifies only the lines still pending approval: the `STATUS` of `g2a` and of `g2b` becomes
`STATUS RATIFIED BY D-9`, while the header, already approved, does not change.

### Named constants

A value that recurs in several lines can be declared once only, with a name, by means of `DEFINE`:

```
  DEFINE     DURATA_LUCE := 60 s
  DEFINE     TOLLERANZA := 5 s
```

A **named constant** is written with `DEFINE`, the name, the sign `:=` and the value: a number, with or without
a unit, a string, `true`, `false` or one of the values of a list. The units admitted are the same as for durations,
`s` and `ms`. The value can also be an expression computed from other values (chapter 23).

`bcdd` does not link the name to the text of the guarantees: in `VERBAL "the light switches off after
DURATA_LUCE"` the name is plain text, and `bcdd` does not check that a corresponding `DEFINE` line exists.

The `DEFINE` line is a **declaration**, like the `TYPE`, `CAPABILITY`, `EVENT` and `STATE` lines: it declares an
element of the CSC. Unlike a contractual line, a declaration does not have a `STATUS` of its own and
always takes that of the header. If it were added to an approved CSC, it would be approved without a decision:
for this reason it is not added to an approved CSC, but written in a CSC still pending approval or in a new
version (chapter 10). In the CSC of the light, approved with `D-7`, the numbers remain written in the text of the
details.

### Numbers not yet decided

A number that has not yet been decided is declared with the value `UNDECIDED`, “not decided”:

```
  DEFINE     ANTICIPO_AVVISO := UNDECIDED
```

An **undecided number** indicates that a decision is missing. `bcdd` lists it in section 3 of the report as long as it
remains so. In a working copy of the CSC of the light still pending approval, with the three `DEFINE` lines of this
chapter at lines 7-9:

```
1. ERRORS: 0
…
3. UNDECIDED: 1
  line 9: ANTICIPO_AVVISO
…
outcome: no errors
```

An undecided number is not an error. When the decision is taken, the value is written by hand in place of
`UNDECIDED`; no command does it.

### Summary

- A **detail** (`DETAILS`) makes a guarantee or an assumption precise: it adds without replacing and without
  contradicting, and it is pending approval when created, even under an approved line.
- `bcdd refine` submits the CSC to a language model, which asks questions about the vague points and proposes lines; only
  what is accepted and confirmed enters the file, and it always remains pending approval.
- A **named constant** is declared with `DEFINE`; an **undecided number** with `UNDECIDED`, and it is listed
  in section 3 of the report.
- `DEFINE` is a **declaration**: it takes the `STATUS` of the header and is not added to an approved CSC.

### Special cases

**Detail of a non-existent guarantee.** If `g2b` has `DETAILS g9` and `g9` does not exist:

```
1. ERRORS: 1
  line 20: [E02] DETAILS names an id that is neither a GUARANTEE nor an ASSUME of this CSC: g9
```

**Circular details.** If `g2a` is a detail of `g2b` and `g2b` is a detail of `g2a`, the two details form a
cycle and neither of them makes a guarantee precise; `bcdd` reports error E05:

```
1. ERRORS: 1
  line 18: [E05] circular DETAILS: g2a -> g2b -> g2a
```

**Unit in minutes.** The line `DEFINE DURATA_LUCE := 1 min` is not recognised:

```
5. UNRECOGNISED LINES: 1
  line 7: DEFINE     DURATA_LUCE := 1 min
```

**No questions.** When the model detects no vague points, `bcdd refine` states it in one line and the file
does not change:

```
the CSC UsoLuce is precise enough: no questions and no proposals, UsoLuce.csc does not change
```

**Details beyond level 2.** `bcdd check` accepts details at any level; the level 2 limit
applies only to the proposals of `bcdd refine`.

---

## Chapter 9 — Examples that fix the intention

Guarantees describe behaviour in general. A concrete case, described instant by instant, makes it possible
to check that the writer and the reader understand them in the same way: two presses 100 seconds
apart are admitted, a switch-off after 30 seconds is not. The chapter introduces scenarios.

### The scenario

A **scenario** is a short sequence of instants that the contract must admit or reject. It is written with
`SCENARIO`:

```
  SCENARIO s1 EXPECT ADMITTED
    @0 s     premuto    modo = accesa
    @55 s    avviso
    @60 s    modo = spenta
    @100 s   premuto    modo = accesa
```

`SCENARIO s1` opens the scenario, with its short name. `EXPECT ADMITTED` means that the scenario must be
**admitted**, that is that it satisfies the contract; `EXPECT REJECTED` means that it must be **rejected**, that is that it
violates it.

Each line that follows begins with `@` and describes an **instant** of the scenario: `@0 s` is the beginning, `@55 s` is
55 seconds later. The instants are written in chronological order, all with a unit (`s` or `ms`) or all
without. In an instant what happens and what is observed are written:

| Element | Meaning | Example |
|---|---|---|
| name of an event | the event happens at that instant | `premuto` |
| state `=` value | at that instant the state has that value | `modo = accesa` |
| lifecycle phase, with the request in parentheses | the request reaches that phase at that instant | `requested(Pulizie)` |
| `VERBAL "…"` | an **assertion in words** about that instant | `VERBAL "the caretaker requests three hours of cleaning"` |

The sequence of instants written in a scenario is its **trace**. In the messages of `bcdd` the instant of a
scenario is called “step” (chapter 21).

Scenario `s1` reads as follows: at instant 0 someone presses the button and the light switches on; at instant 55
the light emits the warning; at instant 60 the light is off; at instant 100 a new press switches it on again.
The contract admits it.

### The starting state

A scenario begins with the states at their initial value. To start from a different situation the
**starting state** is given with `GIVEN`, before `EXPECT`:

```
  SCENARIO s3 GIVEN modo = in_pulizia EXPECT ADMITTED
    @0 s     premuto    modo = in_pulizia
```

The scenario starts with cleaning in progress: a press of the button does not change the mode, as established by `g7`.
States not named in `GIVEN` start from their initial value.

### Where scenarios are written

A scenario is a declaration (chapter 8): it does not have a `STATUS` of its own and takes that of the
header of the CSC.
Like a `DEFINE` line, it is not added to an approved CSC. The scenarios of the light are therefore written in a
new version, 0.2, pending approval: the version number and the `STATUS` of the header change, and a
comment at the top states what changes. The complete procedure for writing a new version is described
in chapter 10.

```
-- The staircase light, as seen by the person on the stairs and by the caretaker.
-- VERSION 0.2: scenarios s1-s4 added. Pending approval.

CSC UsoLuce VERSION 0.2
  STATUS HYPOTHESIS
  PURPOSE "The person on the stairs presses a button and has light to go up or down"

  TYPE       Modo := {spenta, accesa, in_pulizia}

  CAPABILITY Pulizie(durata: Duration)
  EVENT IN   premuto
  EVENT OUT  avviso
  STATE      modo : Modo INITIAL spenta

  GUARANTEE g1: VERBAL "When someone presses the button, the light switches on"
                VERIFY BY JUDGEMENT "a person who presses the button and watches"
  GUARANTEE g2: VERBAL "The light switches off by itself after a while"
                VERIFY BY JUDGEMENT "a person with a watch"
  GUARANTEE g2a DETAILS g2 STATUS RATIFIED BY D-9: VERBAL "The light switches off 60 s after the last press, with a tolerance of 5 s"
                                              VERIFY BY JUDGEMENT "a person who measures with a stopwatch the time between the last press and switch-off"
  GUARANTEE g2b DETAILS g2 STATUS RATIFIED BY D-9: VERBAL "A press while the light is on restarts the count of 60 s from the beginning"
                                              VERIFY BY JUDGEMENT "a person who presses the button again while the light is on and measures with a stopwatch the time until switch-off"
  GUARANTEE g3: VERBAL "Shortly before switching off, the light gives a warning to the person on the stairs"
                VERIFY BY JUDGEMENT "a person on the stairs who waits for the light to switch off"
  GUARANTEE g4: VERBAL "A cleaning request is rejected if the requested duration exceeds two hours; otherwise it is accepted"
                VERIFY BY JUDGEMENT "the caretaker, who requests cleaning with different durations"
  GUARANTEE g5: VERBAL "After an accepted request the light stays on for the whole requested duration; when it expires the request has succeeded"
                VERIFY BY JUDGEMENT "the caretaker, with a watch"
  GUARANTEE g6: VERBAL "If the light cannot stay on until the duration expires, the request has failed"
                VERIFY BY JUDGEMENT "the caretaker, who removes the lamp during cleaning"
  GUARANTEE g7: VERBAL "During cleaning the mode is in_pulizia, and a press of the button does not change it"
                VERIFY BY JUDGEMENT "the caretaker, who presses the button during cleaning"
  ASSUME    a1: VERBAL "Whoever presses the button holds it down for at least a tenth of a second"
                VERIFY BY JUDGEMENT "a person who observes how the button is pressed"

  SCENARIO s1 EXPECT ADMITTED
    @0 s     premuto    modo = accesa
    @55 s    avviso
    @60 s    modo = spenta
    @100 s   premuto    modo = accesa
  SCENARIO s2 EXPECT REJECTED
    @0 s     premuto    modo = accesa
    @30 s    modo = spenta
  SCENARIO s3 GIVEN modo = in_pulizia EXPECT ADMITTED
    @0 s     premuto    modo = in_pulizia
  SCENARIO s4 EXPECT ADMITTED
    @0 s     requested(Pulizie)   VERBAL "the caretaker requests three hours of cleaning"
    @0 s     rejected(Pulizie)
END
```

Scenario `s2` must be rejected: the light switches off 30 seconds after the press, in conflict with detail `g2a`.
Scenario `s4` uses the lifecycle of chapter 5: the caretaker requests three hours of cleaning and the request is
rejected, as established by `g4`. The requested duration, which is a parameter of the request, is indicated with
an assertion in words.

### What bcdd checks

```
$ bcdd check --strict UsoLuce.csc
bcdd check --strict UsoLuce.csc
lines: 49 (recognised 42, comments 2, blank 5, unrecognised 0)
blocks: 1
  line 4: CSC UsoLuce VERSION 0.2, STATUS HYPOTHESIS

1. ERRORS: 0
…
outcome: no errors
```

On scenarios `bcdd` checks the form: that the names used are events, states and requests declared in the CSC,
that the values of the starting state belong to a list of values of the CSC and that the time of the instants does not
decrease. It does not check, on the other hand, that a scenario is really admitted or rejected by the guarantees: with guarantees
written in words this assessment is up to whoever writes the CSC. The verification of outcomes is dealt with in
chapter 24. Section 4 of the report of this version is described in chapter 10.

### The limit of a scenario

A scenario forbids nothing that it does not describe. In `s1` no warning appears between instant 0 and
instant 55: the scenario does not rule out the emission of warnings in that interval. In the same way, an admitted
scenario does not establish that the installation must always behave like this: it shows one possible behaviour.

Scenarios express the intention of the writer and make it possible to discuss it on concrete cases; the obligations remain
in the guarantees.

### Summary

- A **scenario** (`SCENARIO`) is a sequence of instants that the contract must admit (`EXPECT ADMITTED`) or
  reject (`EXPECT REJECTED`).
- Each **instant** (`@`) indicates a time and what happens or is observed: events, values of states, phases of
  a request, assertions in words.
- The **starting state** (`GIVEN`) indicates the initial values of the scenario, when they are not those declared.
- A scenario is a declaration: it takes the `STATUS` of the header and is not added to an approved CSC.
- A scenario does not forbid what it does not describe; `bcdd` checks its form, not its outcome.

### Special cases

**Undeclared event.** If `allarme` is written at instant 55 instead of `avviso`:

```
1. ERRORS: 1
  line 38: [E03] name not declared as EVENT: allarme
```

The same error, with `CAPABILITY` or `STATE` in place of `EVENT`, also appears for a request with a wrong name
in `requested(Pulizia)` and for an undeclared state in `GIVEN accesa = true`.

**Decreasing time.** If the second press is written `@50 s`, after `@60 s`:

```
1. ERRORS: 1
  line 40: [E12] the time of the step decreases: @50 s after @60 s
```

Two instants with the same time, on the other hand, are admitted, as in `s4`.

**Instants with and without unit.** If the instant `@60 s` is written `@60`, without a unit:

```
1. ERRORS: 1
  line 39: [E12] steps with and without a time unit in the same SCENARIO
```

**Scenario declared rejected but admitted by the guarantees.** If in `s2` the switch-off happens at `@60 s`, the
scenario satisfies the contract, although it is declared with `EXPECT REJECTED`. `bcdd check` does not detect
this, because it does not evaluate guarantees written in words.

---

## Chapter 10 — Changing a CSC already approved

The building manager decides that 60 seconds are too few to climb to the top floor: the on-time
goes up to 90 seconds. The CSC of the light is approved, and an approved contract is not modified. The chapter
describes how to write a new version of it and what, in the new version, must be approved again and what
remains approved.

### The new version

To change an approved CSC a **new version** of it is written, in the same file, in place of the
previous one:

1. the number after `VERSION` changes, for example from `0.1` to `0.2`;
2. the `STATUS` of the header goes back to `HYPOTHESIS`;
3. a comment at the top of the file states what changes;
4. every contractual line whose text changes and which has a `STATUS RATIFIED BY` of its own changes to
   `STATUS HYPOTHESIS`;
5. the lines whose text does not change remain as they are.

Until the new version is approved, the contract in force remains the previous approved version, which
can be found in the version history or in the document archive.

### What remains approved

In the new version the state of each contractual line follows the rules of chapter 7:

- a line with a `STATUS RATIFIED BY` of its own, whose text does not change, **remains approved**, with the
  original decision;
- a line without a `STATUS` of its own takes that of the header, which has gone back to `HYPOTHESIS`: it **goes back to pending approval**,
  even if its text does not change;
- a line whose text changes switches to `STATUS HYPOTHESIS` (point 4) and is **pending approval**;
- declarations (types, events, states, named constants, scenarios) take the `STATUS` of the header and
  are pending approval.

Version 0.2 of the light, opened in chapter 9 to add the scenarios, is already an example. Its report
shows, in section 4:

```
4. PENDING APPROVAL, NOT CONTRACT: 8
  line 15: GUARANTEE g1
  line 17: GUARANTEE g2
  line 23: GUARANTEE g3
  line 25: GUARANTEE g4
  line 27: GUARANTEE g5
  line 29: GUARANTEE g6
  line 31: GUARANTEE g7
  line 33: ASSUME a1
```

The eight lines approved in chapter 7 with decision `D-7` do not have a `STATUS` of their own: they took
that of the header, and with the header they have gone back to pending approval. The details `g2a` and `g2b` do not appear, because
they have a `STATUS RATIFIED BY D-9` of their own and their text has not changed: they remain approved.

### The change from 60 to 90 seconds

In the same version 0.2 the new on-time is written. The text of the two details and the
comment at the top change:

```
-- The staircase light, as seen by the person on the stairs and by the caretaker.
-- VERSION 0.2: scenarios s1-s4 added; on-time from 60 s to 90 s. Pending approval.
```

```
  GUARANTEE g2a DETAILS g2 STATUS HYPOTHESIS: VERBAL "The light switches off 90 s after the last press, with a tolerance of 5 s"
                                                VERIFY BY JUDGEMENT "a person who measures with a stopwatch the time between the last press and switch-off"
  GUARANTEE g2b DETAILS g2 STATUS HYPOTHESIS: VERBAL "A press while the light is on restarts the count of 90 s from the beginning"
                                                VERIFY BY JUDGEMENT "a person who presses the button again while the light is on and measures with a stopwatch the time until switch-off"
```

The two lines had a `STATUS RATIFIED BY D-9` of their own; since their text changes, they switch to
`STATUS HYPOTHESIS`.

The change also concerns scenario `s1`, which with 90 seconds would no longer be admitted: the light cannot switch off
at 60 seconds. Its instants are updated:

```
  SCENARIO s1 EXPECT ADMITTED
    @0 s     premuto    modo = accesa
    @85 s    avviso
    @90 s    modo = spenta
    @100 s   premuto    modo = accesa
```

Scenario `s2`, with the switch-off at 30 seconds, remains rejected with the new time as well.

The report of version 0.2 now shows all ten contractual lines pending approval:

```
$ bcdd check --strict UsoLuce.csc
bcdd check --strict UsoLuce.csc
…
blocks: 1
  line 4: CSC UsoLuce VERSION 0.2, STATUS HYPOTHESIS

1. ERRORS: 0
…
4. PENDING APPROVAL, NOT CONTRACT: 10
  line 15: GUARANTEE g1
  line 17: GUARANTEE g2
  line 19: GUARANTEE g2a
  line 21: GUARANTEE g2b
  line 23: GUARANTEE g3
  line 25: GUARANTEE g4
  line 27: GUARANTEE g5
  line 29: GUARANTEE g6
  line 31: GUARANTEE g7
  line 33: ASSUME a1
…
outcome: no errors
```

### Approving the new version

The building manager approves version 0.2 with decision `D-12`:

```
$ bcdd ratify UsoLuce.csc --all D-12
approved with D-12 in CSC UsoLuce: 3 lines
  line 5: CSC UsoLuce
  line 19: GUARANTEE g2a
  line 21: GUARANTEE g2b
contract: 10
```

The command modifies three lines: the header and the two details that had a `STATUS HYPOTHESIS` of their own. The
other eight contractual lines take the `STATUS` of the header and are approved with it. In the report section 4
is empty again:

```
blocks: 1
  line 4: CSC UsoLuce VERSION 0.2, STATUS RATIFIED BY D-12
…
4. PENDING APPROVAL, NOT CONTRACT: 0
```

Version 0.2 is now the contract in force and replaces 0.1.

### What can be modified without a new version

Comments are not part of the contract: they can be corrected at any time, without a new version,
provided that no other line changes.

`bcdd` reads one file at a time and has no access to the previous version: it therefore cannot state what
has changed between two versions. The comparison is made with a version control system, for example
`git diff`, before approving.

### Summary

- An approved CSC is not modified: a **new version** of it is written, with a different number and
  the header `STATUS HYPOTHESIS`, in place of the previous one.
- A line with a `STATUS RATIFIED BY` of its own, whose text does not change, remains approved.
- A line that takes the `STATUS` of the header goes back to pending approval; a line whose text changes switches to
  `STATUS HYPOTHESIS`.
- Until the new version is approved, the previous one applies; `bcdd ratify --all` records the approval of the new version.
- Comments are corrected without a new version.

### Special cases

**Text changed without STATUS HYPOTHESIS.** If the text of `g2a` changes to 90 seconds but the line keeps
`STATUS RATIFIED BY D-9`, the line remains approved with a text that nobody has approved. `bcdd check` does not
detect this: `g2a` does not appear in section 4 of the report.

```
4. PENDING APPROVAL, NOT CONTRACT: 8
  line 15: GUARANTEE g1
  line 17: GUARANTEE g2
  line 23: GUARANTEE g3
  line 25: GUARANTEE g4
  line 27: GUARANTEE g5
  line 29: GUARANTEE g6
  line 31: GUARANTEE g7
  line 33: ASSUME a1
```

This defect can be detected only by comparing the new version with the previous one, before approving it.

**Two versions in the same file.** The new version replaces the previous one in the file. If the two versions
remain one after the other, the second repeats a name already declared:

```
1. ERRORS: 1
  line 34: [E01] name already used at line 3: UsoLuce
```

**Undecided number in an approved CSC.** To replace `UNDECIDED` with a value in an approved CSC a
new version is written, as for any other change; in a CSC pending approval the line is modified
directly.

---

## Chapter 11 — One boundary or separate boundaries

In part one the staircase light has a single boundary, described by the CSC `UsoLuce`, in which the press
of the button and the observed light appear together. This chapter divides that boundary in two, states when the
division is appropriate and highlights the problem that results from it.

### When a boundary is divided

A boundary is the interface at which what passes between a system and its consumer is observed (chapter 1). The
press of the button is observed on the wall of the entrance hall, next to the button; the light is observed on the stairs,
by looking at the lamp. Checking that the light switches off by itself does not require observing the button, and
checking that a press is recognised does not require observing the light.

The criterion is the following: a boundary is divided in two when what passes through it is observed at two
distinct points. The guarantees of each of the two new boundaries must also be checkable without observing
the other. Elements observed
at the same point remain in the same boundary: the cleaning request, the warning and the mode of the light
all concern the light, and remain together.

The division is useful above all when the two boundaries are provided by different systems, implemented
separately: whoever builds the button receives only the description of the button's boundary. This
case is covered in chapter 13.

### The two CSCs

The boundary of the press of the button is described by the CSC `Pressione`:

```
-- The staircase button, as seen by whoever presses it.

CSC Pressione VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "The person on the stairs presses the button to ask for light"

  EVENT IN   premuto

  ASSUME    a1: VERBAL "Whoever presses the button holds it down for at least a tenth of a second"
                VERIFY BY JUDGEMENT "a person who observes how the button is pressed"
END
```

The boundary of the observed light is described by the CSC `Luce`:

```
-- The staircase light, as seen by the person on the stairs and by the caretaker.

CSC Luce VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "The person on the stairs sees the light on for the time needed to go up or down"

  TYPE       Modo := {spenta, accesa, in_pulizia}

  CAPABILITY Pulizie(durata: Duration)
  EVENT OUT  avviso
  STATE      modo : Modo INITIAL spenta

  GUARANTEE g2: VERBAL "The light switches off by itself after a while"
                VERIFY BY JUDGEMENT "a person with a watch"
  GUARANTEE g3: VERBAL "Shortly before switching off, the light gives a warning to the person on the stairs"
                VERIFY BY JUDGEMENT "a person on the stairs who waits for the light to switch off"
  GUARANTEE g4: VERBAL "A cleaning request is rejected if the requested duration exceeds two hours; otherwise it is accepted"
                VERIFY BY JUDGEMENT "the caretaker, who requests cleaning with different durations"
  GUARANTEE g5: VERBAL "After an accepted request the light stays on for the whole requested duration; when it expires the request has succeeded"
                VERIFY BY JUDGEMENT "the caretaker, with a watch"
  GUARANTEE g6: VERBAL "If the light cannot stay on until the duration expires, the request has failed"
                VERIFY BY JUDGEMENT "the caretaker, who removes the lamp during cleaning"

  SCENARIO s4 EXPECT ADMITTED
    @0 s     requested(Pulizie)   VERBAL "the caretaker requests three hours of cleaning"
    @0 s     rejected(Pulizie)
END
```

The lines of `UsoLuce` 0.2 are distributed as follows:

| Lines of `UsoLuce` 0.2 | Where they go |
|---|---|
| `EVENT IN premuto`, the assumption `a1` | `Pressione` |
| `TYPE Modo`, `CAPABILITY Pulizie`, `EVENT OUT avviso`, `STATE modo` | `Luce` |
| the guarantees `g2`, `g3`, `g4`, `g5`, `g6` and the scenario `s4` | `Luce` |
| the guarantees `g1`, `g2a`, `g2b`, `g7` and the scenarios `s1`, `s2`, `s3` | in neither of the two |

The two CSCs are new: they have version 0.1 and the header `STATUS HYPOTHESIS`. The lines copied from
`UsoLuce` do not carry their approval with them, because the division changes the contract and requires a
new decision. Until the two CSCs are approved, `UsoLuce` 0.2, approved with decision `D-12`, remains in
force.

### The report

```
$ bcdd check --strict Pressione.csc
bcdd check --strict Pressione.csc
lines: 11 (recognised 7, comments 1, blank 3, unrecognised 0)
blocks: 1
  line 3: CSC Pressione VERSION 0.1, STATUS HYPOTHESIS

1. ERRORS: 0

2. DEGREE OF THE CONTRACTUAL LINES
  verbal: 1
  formal: 0
  declared extension: 0
  unrecognised: 0
  line 9: ASSUME a1 verbal

3. UNDECIDED: 0

4. PENDING APPROVAL, NOT CONTRACT: 1
  line 9: ASSUME a1

5. UNRECOGNISED LINES: 0

6. UNDECLARED TYPES: 0

7. CSCs NAMED BUT NOT CHECKED: 0

outcome: no errors
```

```
$ bcdd check --strict Luce.csc
bcdd check --strict Luce.csc
lines: 27 (recognised 21, comments 1, blank 5, unrecognised 0)
blocks: 1
  line 3: CSC Luce VERSION 0.1, STATUS HYPOTHESIS

1. ERRORS: 0
…
4. PENDING APPROVAL, NOT CONTRACT: 5
  line 13: GUARANTEE g2
  line 15: GUARANTEE g3
  line 17: GUARANTEE g4
  line 19: GUARANTEE g5
  line 21: GUARANTEE g6
…
outcome: no errors
```

Both CSCs pass the check. The CSC `Pressione`, however, contains an assumption on which no
guarantee depends: the guarantee that depended on `a1` was `g1`, which is no longer found in either of the two
CSCs.

### The problem: the guarantees that bind the two boundaries

The guarantee `g1`, “when someone presses the button, the light switches on”, names an element of each
boundary: the press, which is in `Pressione`, and the light, which is in `Luce`. The same holds for `g2a` and
`g2b`, which concern the time elapsed since the last press, for `g7`, which describes the effect of a press during
cleaning, and for the scenarios `s1`, `s2` and `s3`, in which both `premuto` and `modo` appear.

None of these lines can be written in either of the two CSCs. A CSC describes a single boundary and names only
its own elements: in `Luce` the event `premuto` does not exist, and in `Pressione` the state `modo` does not exist.
Writing `g1` in `Luce` would violate the rule of chapter 1, according to which a guarantee concerns only what is
observed at the boundary.

The guarantees that bind two boundaries are written in what lies behind both, the entity, described in
chapter 12.

### Summary

- A boundary is divided in two when what passes through it is observed at two distinct points and the guarantees of one
  can be checked without observing the other.
- Each boundary has its own CSC; a CSC names only its own elements.
- The CSCs that result from a division are new and pending approval; until they are approved the previous CSC
  remains in force.
- A guarantee that names elements of two boundaries cannot be written in either of the two CSCs.

### Special cases

**Scenario with elements of two boundaries.** If the scenario `s1` of `UsoLuce` is added at the end of the CSC `Luce`,
with the instant `@0 s premuto modo = accesa` at line 28, the report shows:

```
1. ERRORS: 1
  line 28: [E03] name not declared as EVENT: premuto
```

**Name preceded by the name of the CSC.** If `Pressione.premuto` is written in the same line, the report
shows a different error:

```
1. ERRORS: 1
  line 28: [E20] Pressione.premuto: in a CSC, names are not written with the connector in front. The order of two connectors is written in a SCENARIO of the entity
```

In its messages `bcdd` calls a CSC cited by an entity a “connector”; the manual uses “boundary” (chapter 12).
The message refers to the form described in chapter 18.

**Verbal guarantee that names the other boundary.** If the guarantee `g1` is copied into `Luce` unchanged,
`bcdd` reports nothing: it does not interpret the text between quotation marks and does not recognise that the guarantee refers to the
press. The assessment is the responsibility of whoever writes the CSC.

---

## Chapter 12 — What lies behind the boundaries: the entity

The guarantees that bind the button and the light cannot be written in either of the two CSCs of chapter 11. This
chapter introduces what lies behind the two boundaries and keeps those guarantees: the entity.

### The entity

An **entity** is the system that lies behind one or more boundaries. It is described by stating three things:

- the boundaries on which it keeps the guarantees, that is, those of which it is the provider;
- the boundaries on which it relies on the guarantees of others, that is, those of which it is the consumer;
- the guarantees that bind two or more of its boundaries, called **entity guarantees**.

The description of an entity never states where the entity is located: on which wall, in which device, in which program. Its
location is a choice of whoever implements it (chapter 1); an entity may also extend over several devices.

The staircase light is an entity, `LuceScale`, which lies behind the boundaries `Pressione` and `Luce`. The guarantee
“when someone presses the button, the light switches on” is one of its entity guarantees.

### A used boundary: the power supply

The lighting installation is powered by the electrical mains of the block of flats. The mains is another
system, and between the mains and the installation there is a boundary, described by the CSC `Alimentazione`:

```
-- The electrical mains of the block of flats, as seen by the lighting installation.

CSC Alimentazione VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "The electrical mains of the block of flats supplies voltage to the staircase lighting installation"

  STATE      presente : Boolean INITIAL true

  GUARANTEE r1: VERBAL "The voltage is present, except for interruptions of the mains"
                VERIFY BY INSPECTION "the register of interruptions of the block of flats"
  ASSUME    r-a1: VERBAL "The staircase lighting installation draws at most 100 W"
                  VERIFY BY INSPECTION "the rating plate data of the installed lamps"
END
```

The CSC is written from the side of the provider, the mains (chapter 4). On this boundary the staircase light is the
consumer: it relies on the guarantee `r1` and must satisfy the assumption `r-a1`.

### The entity file

```
-- The staircase light: what lies behind the button and the light.

ENTITY LuceScale VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "The person on the stairs presses the button and has light to go up or down"

  OFFERS Pressione
  OFFERS Luce
  USES   Alimentazione

  GUARANTEE ls1: VERBAL "When someone presses the button, the light switches on"
                 VERIFY BY JUDGEMENT "a person who presses the button and watches"
  GUARANTEE ls2: VERBAL "The light switches off 90 s after the last press, with a tolerance of 5 s"
                 VERIFY BY JUDGEMENT "a person who measures with a stopwatch the time between the last press and switch-off"
  GUARANTEE ls3: VERBAL "During cleaning a press of the button does not change the mode"
                 VERIFY BY JUDGEMENT "the caretaker, who presses the button during cleaning"
END
```

`ENTITY LuceScale VERSION 0.1` opens the description of the entity, with its name and its version. `STATUS` and
`PURPOSE` have the same meaning they have in the CSC.

`OFFERS Pressione` states that the entity is the provider on the boundary `Pressione`: it keeps its guarantees and
relies on its assumptions. `USES Alimentazione` states that the entity is the consumer on the boundary `Alimentazione`:
it satisfies its assumptions and relies on its guarantees. After `OFFERS` and `USES` the name of a CSC is written.

The `GUARANTEE` lines are the entity guarantees. They have the same form as the guarantees of a CSC, with the short
name and the verification, but they name elements of several boundaries: `ls1` binds the press and the light. The assumption
`a1` of the CSC `Pressione` now has a guarantee that depends on it: `ls1`.

An entity has no elements of its own: it has no requests, events, states, types, named constants or assumptions. What
is observed is described in the CSCs of its boundaries. What the entity requires of other systems is in the
assumptions of the CSCs it provides, such as `a1`. What other systems require of the entity is in the
assumptions of the CSCs it uses, such as `r-a1`.

A CSC and an entity cannot have the same name: when the two names are in the same file, `bcdd` reports E01.

### The report

```
$ bcdd check --strict LuceScale.csc
bcdd check --strict LuceScale.csc
lines: 17 (recognised 13, comments 1, blank 3, unrecognised 0)
blocks: 1
  line 3: ENTITY LuceScale VERSION 0.1, STATUS HYPOTHESIS
    line 7: OFFERS Pressione in Pressione.csc at line 3: VERSION 0.1, STATUS HYPOTHESIS, no errors
    line 8: OFFERS Luce in Luce.csc at line 3: VERSION 0.1, STATUS HYPOTHESIS, no errors
    line 9: USES Alimentazione in Alimentazione.csc at line 3: VERSION 0.1, STATUS HYPOTHESIS, no errors

1. ERRORS: 0

2. DEGREE OF THE CONTRACTUAL LINES
  verbal: 3
  formal: 0
  declared extension: 0
  unrecognised: 0
  line 11: GUARANTEE ls1 verbal
  line 13: GUARANTEE ls2 verbal
  line 15: GUARANTEE ls3 verbal

3. UNDECIDED: 0

4. PENDING APPROVAL, NOT CONTRACT: 3
  line 11: GUARANTEE ls1
  line 13: GUARANTEE ls2
  line 15: GUARANTEE ls3

5. UNRECOGNISED LINES: 0

6. UNDECLARED TYPES: 0

7. CSCs NAMED BUT NOT CHECKED: 0

8. USES WITHIN ENTITIES: 0

outcome: no errors
```

Below the entity line, indented, the **citations** appear: one line for each CSC cited by `OFFERS` or
by `USES`. For each of them `bcdd` looks for the file of the CSC, checks it and reports its version, its `STATUS` and
the outcome. The first citation reports that the CSC named at line 7 is in the file `Pressione.csc`,
at line 3; the CSC is at version 0.1, is pending approval and has no errors. The check of a cited CSC
concerns its form, not whether its guarantees are compatible with those of the entity: that
assessment is the responsibility of whoever writes.

Section 8 appears when the file contains an entity; it is described in chapter 13.

In the messages of `bcdd` a CSC cited by an entity is called a “connector”; the manual uses “boundary”.

In the header of an entity only `STATUS HYPOTHESIS` is allowed: the entity as a whole is not approved. Its
entity guarantees are approved one by one; the CSCs it cites are approved in their own files.

### Summary

- An **entity** (`ENTITY`) is the system that lies behind one or more boundaries; its description never states where it is located.
- `OFFERS` states a boundary of which the entity is the provider, `USES` a boundary of which the entity is the consumer.
- **Entity guarantees** bind two or more boundaries of the entity and have the form of the guarantees of a CSC.
- An entity has no elements of its own: what is observed is described in the CSCs of its boundaries.
- `bcdd` looks for and checks the cited CSCs and reports their version, `STATUS` and outcome.

### Special cases

**Element of its own in an entity.** If `STATE accesa : Boolean INITIAL false` is written in the entity:

```
1. ERRORS: 1
  line 10: [E18] STATE cannot appear in an entity: write it in the CSC of one of its connectors
…
5. UNRECOGNISED LINES: 1
  line 10: STATE  accesa : Boolean INITIAL false
```

The same error appears for `ASSUME`, `CAPABILITY`, `EVENT`, `DEFINE` and `TYPE`.

**Approved `STATUS` in the header.** The line `STATUS RATIFIED BY D-20` in the header of an entity is not
recognised, and the block turns out to have no `STATUS`:

```
blocks: 1
  line 3: ENTITY LuceScale VERSION 0.1, without STATUS
…
5. UNRECOGNISED LINES: 1
  line 4: STATUS RATIFIED BY D-20
```

**Approval of entity guarantees.** Since the header of the entity cannot be approved, `bcdd ratify` with
`--all` records the approval of the entity guarantees by writing the `STATUS` in each of them:

```
$ bcdd ratify LuceScale.csc --all D-20
approved with D-20 in ENTITY LuceScale: 3 lines
  line 11: GUARANTEE ls1
  line 13: GUARANTEE ls2
  line 15: GUARANTEE ls3
contract: 3
```

**Cited CSC that cannot be found.** If the entity cites with `OFFERS Citofono` a CSC whose file does not exist,
the citation appears in section 7, entitled `CSCs NAMED BUT NOT CHECKED`:

```
7. CSCs NAMED BUT NOT CHECKED: 1
  line 9: Citofono
```

It is not an error: the section reports that the CSC has not been checked. Section 7 also lists the entities
cited as parts and not found (chapter 13).

**Location of the entity.** The fact that the button is in the entrance hall and the lamp on the ceiling is not
written: no form of the language states where an entity is located.

---

## Chapter 13 — An entity made of parts

The staircase light consists of two devices, a button and a lamp, which may be implemented
by different people. This chapter describes how to divide an entity into parts, how to write the boundary between the
parts and how `bcdd` checks that the entity is closed.

### The parts

A **part** is an entity contained in another entity. The parts are listed under the line `COMPOSED OF`, one
per line, in the form `name : Entity`. The line `COMPOSED OF` and the lines that follow it form the **parts
list**. The first name, the **part name**, states the role of the part in the entity that contains it
(`pulsante`); the second is the name of the entity that describes the part (`Pulsante`). The line `COMPOSED OF` is
written only once.

At each press the button commands the lamp to switch on. There is therefore a boundary between the two parts,
described by the CSC `Comando`, written from the side of the provider, that is, the button:

```
-- The command that the button sends to the lamp.

CSC Comando VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "The button commands the lamp to switch on"

  EVENT OUT  accendi

  GUARANTEE c1: VERBAL "At least 0.2 s pass between two accendi"
                VERIFY BY INSPECTION "the recorded commands"
END
```

The two parts are entities, each in its own file. The button provides the press to the person on the stairs and
the command to the lamp:

```
-- The staircase button, one of the two parts of the light.

ENTITY Pulsante VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "The button receives the press and commands the lamp"

  OFFERS Pressione
  OFFERS Comando

  GUARANTEE pu1: VERBAL "Each press is followed by an accendi within 0.1 s"
                 VERIFY BY INSPECTION "the recorded presses and commands"
END
```

The lamp uses the command and the power supply and provides the light:

```
-- The staircase lamp, one of the two parts of the light.

ENTITY Lampada VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "The lamp switches on at the command and switches off by itself"

  USES   Comando
  USES   Alimentazione
  OFFERS Luce

  GUARANTEE la1: VERBAL "After an accendi the light switches on within 0.5 s"
                 VERIFY BY JUDGEMENT "a person who observes the lamp while the command is sent"
  GUARANTEE la2: VERBAL "The light switches off 90 s after the last accendi, with a tolerance of 5 s"
                 VERIFY BY JUDGEMENT "a person with a stopwatch"
END
```

The entity `LuceScale` lists the two parts:

```
-- The staircase light, made of a button and a lamp.

ENTITY LuceScale VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "The person on the stairs presses the button and has light to go up or down"

  OFFERS Pressione
  OFFERS Luce
  USES   Alimentazione

  COMPOSED OF
    pulsante : Pulsante
    lampada  : Lampada

  GUARANTEE ls1: VERBAL "When someone presses the button, the light switches on"
                 VERIFY BY JUDGEMENT "a person who presses the button and watches"
  GUARANTEE ls2: VERBAL "The light switches off 90 s after the last press, with a tolerance of 5 s"
                 VERIFY BY JUDGEMENT "a person who measures with a stopwatch the time between the last press and switch-off"
  GUARANTEE ls3: VERBAL "During cleaning a press of the button does not change the mode"
                 VERIFY BY JUDGEMENT "the caretaker, who presses the button during cleaning"
END
```

The entity guarantees remain those of chapter 12. Since they are not yet approved, the entity remains
at version 0.1 and is modified directly (chapter 10).

`LuceScale` neither provides nor uses `Comando`: the boundary between the two parts is **internal** to the entity and is not
observable from outside. The person on the stairs continues to observe only the press and the light. There is no need to state how the
command reaches the lamp from the button: the two parts cite the same CSC and therefore refer to the same
events. The concrete characteristics of the medium, a wire or a signal, are not written in the CSC (chapter 25).

### Every used boundary is offered

In an entity made of parts the rule **every used boundary is offered** applies: every CSC used by a part is provided
by another part or is used by the entity itself towards the outside (in the report: `from outside`). In the example, the
lamp uses `Comando`, which the button provides, and uses `Alimentazione`, which the entity uses from outside. The
`OFFERS` line of a part does not satisfy the `USES` line of the same part.

The rule has two complements:

- every boundary that the entity provides or uses towards the outside, called a **public boundary**, is entrusted to a part.
  The part provides it, if the entity provides it; it uses it, if the entity uses it. `Pressione`, provided by the entity, is
  also provided by the button;
- every boundary provided by a part is used by another part or provided by the entity: `Comando` is used
  by the lamp, `Luce` is provided by `LuceScale`.

An entity that respects the rule and its two complements is **closed**. `bcdd` reports a missing closure with three
errors: E14 for a CSC used by a part and not provided by any part, E16 for a public boundary not entrusted to
any part, E17 for a CSC provided by a part and not used by any part.

The assumptions of the CSC `Alimentazione` must be satisfied by its consumer: by the entity towards the mains and
by the lamp inside the entity. `bcdd` does not check this, because the assumptions are written in words.

### The report

```
$ bcdd check --strict LuceScale.csc
bcdd check --strict LuceScale.csc
lines: 21 (recognised 16, comments 1, blank 4, unrecognised 0)
blocks: 1
  line 3: ENTITY LuceScale VERSION 0.1, STATUS HYPOTHESIS
    line 7: OFFERS Pressione in Pressione.csc at line 3: VERSION 0.1, STATUS HYPOTHESIS, no errors
    line 8: OFFERS Luce in Luce.csc at line 3: VERSION 0.1, STATUS HYPOTHESIS, no errors
    line 9: USES Alimentazione in Alimentazione.csc at line 3: VERSION 0.1, STATUS HYPOTHESIS, no errors
    line 12: pulsante : Pulsante in Pulsante.csc at line 3: VERSION 0.1, STATUS HYPOTHESIS, no errors
    line 13: lampada : Lampada in Lampada.csc at line 3: VERSION 0.1, STATUS HYPOTHESIS, no errors

1. ERRORS: 0

2. DEGREE OF THE CONTRACTUAL LINES
  verbal: 3
  formal: 0
  declared extension: 0
  unrecognised: 0
  line 15: GUARANTEE ls1 verbal
  line 17: GUARANTEE ls2 verbal
  line 19: GUARANTEE ls3 verbal

3. UNDECIDED: 0

4. PENDING APPROVAL, NOT CONTRACT: 3
  line 15: GUARANTEE ls1
  line 17: GUARANTEE ls2
  line 19: GUARANTEE ls3

5. UNRECOGNISED LINES: 0

6. UNDECLARED TYPES: 0

7. CSCs NAMED BUT NOT CHECKED: 0

8. USES WITHIN ENTITIES: 2
  line 13: lampada uses Comando: it is provided by pulsante (line 12)
  line 13: lampada uses Alimentazione: LuceScale uses it from outside (line 9)

outcome: no errors
```

Below the entity the citations of the parts also appear: `line 12: pulsante : Pulsante in Pulsante.csc at
line 3` states that the entity `Pulsante` was found in the file `Pulsante.csc`.

Section 8, `USES WITHIN ENTITIES`, reports, for each CSC used by a part, who provides it:

- `lampada uses Comando: it is provided by pulsante (line 12)`: the CSC is provided by another part, identified by the name
  it has in the entity and by the line in which it is listed;
- `lampada uses Alimentazione: LuceScale uses it from outside (line 9)`: the CSC is used by the entity towards the outside.

### Where bcdd looks for the cited files

For each cited CSC and for each part `bcdd` looks for the block with that name in this order:

1. in the checked file;
2. in the file with the same name and the extension `.csc`, in the folder of the checked file (`Comando.csc` for the
   CSC `Comando`);
3. in the file with the same name and the extension `.csc`, in the folders indicated with the option `--dir`,
   in the order in which they are written.

Of a part, `bcdd` reads only the `OFFERS` and `USES` lines, not its parts nor the cited CSCs. Each
entity is therefore checked in its own file: `bcdd check Pulsante.csc` checks the button and the CSCs it
cites.

### Summary

- A **part** is an entity contained in another; the parts are listed after `COMPOSED OF`, in the form
  `name : Entity`.
- The boundary between two parts is internal to the entity and is not observable from outside.
- **Every used boundary is offered**: every CSC used by a part is provided by another part or used by the entity towards
  the outside; every public boundary is entrusted to a part; every CSC provided by a part is used by another part or
  provided by the entity.
- `bcdd` reports a missing closure with the errors E14, E16 and E17 and reports the uses in section 8 of the report.

### Special cases

**Part removed from the list.** If the button is removed from the list, no part provides the CSC used by the lamp, and
the public boundary `Pressione` is not entrusted to any part:

```
1. ERRORS: 2
  line 7: [E16] the public connector Pressione of LuceScale (provided) is not assigned to any part
  line 12: [E14] the part lampada uses connector Comando: no other part of LuceScale provides it, nor does LuceScale use it from outside
…
8. USES WITHIN ENTITIES: 2
  line 12: lampada uses Comando: nobody provides it
  line 12: lampada uses Alimentazione: LuceScale uses it from outside (line 9)
```

**Boundary provided by a part and not by the entity.** If the line `OFFERS Luce` is removed from the entity, the light
provided by the lamp is neither used by any part nor provided by the entity:

```
1. ERRORS: 1
  line 12: [E17] the part lampada provides connector Luce: no other part of LuceScale uses it, nor does LuceScale provide it from outside
```

**Part not found.** If the file `Pulsante.csc` does not exist, the part is listed in section 7 with the name
of the entity not found, and the closure check is suspended:

```
1. ERRORS: 0
…
7. CSCs NAMED BUT NOT CHECKED: 1
  line 12: Pulsante

8. USES WITHIN ENTITIES: 2
  line 13: lampada uses Comando: no part found provides it (parts not checked: 1)
  line 13: lampada uses Alimentazione: LuceScale uses it from outside (line 9)

outcome: no errors
```

`bcdd` does not report the errors E14, E16 and E17 until all the parts have been found: a part not
checked might provide the missing CSC. The outcome `no errors`, in this case, must be read together with
section 7.

---

## Chapter 14 — A channel that loses or delays: the wireless button

In the entrance hall a wire cannot be laid; the button is therefore wireless and sends a radio message to
a receiver installed next to the lamp. A radio message may be lost or arrive late. This
chapter describes how to represent a medium of this kind and how to write a boundary external to the entity.

### The channel

A **channel** is a medium that carries messages from one system to another and that may lose them, delay them or
reorder them. Its behaviour is described in a boundary of its own, with its own CSC.

If the wireless button provided `Comando` directly to the lamp, the button's guarantee “each
press is followed by an accendi within 0.1 s” would be violated every time a message is lost, without any
line stating so. Loss and delay are observed on the radio link, between the button and the receiver: the
guarantees that concern them are written in the CSC of that link.

The concrete characteristics of the medium (frequency, radio protocol, message format) are not written here
(chapter 25).

### The CSCs and the entities of the wireless button

The radio channel is described by the CSC `Trasmissione`, written from the side of the provider, that is, the button:

```
-- The wireless channel between the button and the receiver.

CSC Trasmissione VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "The wireless button sends radio messages to the receiver next to the lamp"

  EVENT OUT  messaggio

  GUARANTEE t1: VERBAL "A sent message arrives within 0.3 s or is lost"
                VERIFY BY INSPECTION "the messages recorded on sending and on reception"
  GUARANTEE t2: VERBAL "Two messages may arrive in an order different from the order of sending"
                VERIFY BY INSPECTION "the messages recorded on sending and on reception"
  GUARANTEE t3: VERBAL "A message that has not been sent never arrives"
                VERIFY BY INSPECTION "the messages recorded on sending and on reception"
END
```

The guarantees of `Trasmissione` establish what the consumer of the transmission can count on. A message may
be lost; if it arrives, it arrives within 0.3 s. The order of arrival is not guaranteed. No message arrives that nobody has sent.
They are guarantees that commit the provider to little, but they are precise.

The wireless button provides the press and the transmission, and reduces the effect of losses by sending three messages for
each press:

```
-- The wireless button.

ENTITY PulsanteRadio VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "The wireless button receives the press and transmits it to the receiver"

  OFFERS Pressione
  OFFERS Trasmissione

  GUARANTEE pr1: VERBAL "At each press the button sends three messages, 50 ms apart"
                 VERIFY BY INSPECTION "the recorded presses and messages"
END
```

The receiver uses the transmission and provides the command to the lamp:

```
-- The receiver next to the lamp.

ENTITY Ricevitore VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "The receiver receives the messages of the wireless button and commands the lamp"

  USES   Trasmissione
  USES   Alimentazione
  OFFERS Comando

  GUARANTEE ri1: VERBAL "A received message produces an accendi within 0.05 s; messages received in the following 0.2 s produce no others"
                 VERIFY BY INSPECTION "the received messages and the recorded commands"
END
```

### A boundary external to the entity

The lamp and its receiver form an entity, `LampadaRadio`. The transmission is provided by the button, which is not
part of this entity: it is therefore an **external boundary** and it is declared on the entity with `USES`.
Inside, the `USES` line of the receiver is satisfied by the `USES` line of the entity (`from outside`):

```
-- The lamp with its receiver.

ENTITY LampadaRadio VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "The lamp receives the messages of the wireless button, switches on and switches off by itself"

  USES   Trasmissione
  USES   Alimentazione
  OFFERS Luce

  COMPOSED OF
    ricevitore : Ricevitore
    lampada    : Lampada

  GUARANTEE lr1: VERBAL "After a received message the light switches on within 0.6 s"
                 VERIFY BY JUDGEMENT "a person who observes the lamp while a message is sent"
END
```

```
$ bcdd check --strict LampadaRadio.csc
bcdd check --strict LampadaRadio.csc
lines: 17 (recognised 12, comments 1, blank 4, unrecognised 0)
blocks: 1
  line 3: ENTITY LampadaRadio VERSION 0.1, STATUS HYPOTHESIS
    line 7: USES Trasmissione in Trasmissione.csc at line 3: VERSION 0.1, STATUS HYPOTHESIS, no errors
    line 8: USES Alimentazione in Alimentazione.csc at line 3: VERSION 0.1, STATUS HYPOTHESIS, no errors
    line 9: OFFERS Luce in Luce.csc at line 3: VERSION 0.1, STATUS HYPOTHESIS, no errors
    line 12: ricevitore : Ricevitore in Ricevitore.csc at line 3: VERSION 0.1, STATUS HYPOTHESIS, no errors
    line 13: lampada : Lampada in Lampada.csc at line 3: VERSION 0.1, STATUS HYPOTHESIS, no errors

1. ERRORS: 0

2. DEGREE OF THE CONTRACTUAL LINES
  verbal: 1
  formal: 0
  declared extension: 0
  unrecognised: 0
  line 15: GUARANTEE lr1 verbal

3. UNDECIDED: 0

4. PENDING APPROVAL, NOT CONTRACT: 1
  line 15: GUARANTEE lr1

5. UNRECOGNISED LINES: 0

6. UNDECLARED TYPES: 0

7. CSCs NAMED BUT NOT CHECKED: 0

8. USES WITHIN ENTITIES: 4
  line 12: ricevitore uses Trasmissione: LampadaRadio uses it from outside (line 7)
  line 12: ricevitore uses Alimentazione: LampadaRadio uses it from outside (line 8)
  line 13: lampada uses Comando: it is provided by ricevitore (line 12)
  line 13: lampada uses Alimentazione: LampadaRadio uses it from outside (line 8)

outcome: no errors
```

Section 8 reports `ricevitore uses Trasmissione: LampadaRadio uses it from outside (line 7)`. The boundary
`Comando` is internal to `LampadaRadio`: the `USES Comando` line of the lamp is satisfied by the receiver, which provides it.

The complete entity, `LuceSenzaFili`, contains the wireless button and the lamp with its receiver:

```
-- The staircase light with the wireless button.

ENTITY LuceSenzaFili VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "The person on the stairs presses the wireless button and has light to go up or down"

  OFFERS Pressione
  OFFERS Luce
  USES   Alimentazione

  COMPOSED OF
    pulsante : PulsanteRadio
    lampada  : LampadaRadio

  GUARANTEE lf1: VERBAL "When someone presses the button, the light switches on within 1 s, unless all three messages are lost"
                 VERIFY BY JUDGEMENT "a person who presses the button and watches"
END
```

```
$ bcdd check --strict LuceSenzaFili.csc
…
8. USES WITHIN ENTITIES: 2
  line 13: lampada uses Trasmissione: it is provided by pulsante (line 12)
  line 13: lampada uses Alimentazione: LuceSenzaFili uses it from outside (line 9)

outcome: no errors
```

In `LuceSenzaFili` the boundary `Comando` does not appear: it is internal to `LampadaRadio`, and of a part `bcdd` reads
only the `OFFERS` and `USES` lines (chapter 13).

The entity guarantee `lf1` takes the losses of the channel into account: the light switches on within one second, unless all
three messages are lost. A guarantee that ignored losses would guarantee more than the channel allows.

### Summary

- A **channel** is a medium that may lose, delay or reorder what it carries; its
  behaviour is described in a boundary of its own, with its own CSC, in which the admitted losses and
  delays are written.
- A boundary external to an entity is declared on the entity with `USES`; the `USES` line of the part is satisfied
  by the entity's own `USES` line (“used from outside”).
- The concrete characteristics of the medium are not written in the CSC (chapter 25).

### Special cases

**External boundary not declared.** If the line `USES Trasmissione` is missing in `LampadaRadio`, the receiver uses
a CSC that no part provides:

```
1. ERRORS: 1
  line 11: [E14] the part ricevitore uses connector Trasmissione: no other part of LampadaRadio provides it, nor does LampadaRadio use it from outside
```

The missing line also affects the entity that contains `LampadaRadio`: in `LuceSenzaFili` the transmission provided by the
button is no longer used by any part.

```
1. ERRORS: 1
  line 12: [E17] the part pulsante provides connector Trasmissione: no other part of LuceSenzaFili uses it, nor does LuceSenzaFili provide it from outside
```

**Channel not written.** If the wireless button declares `OFFERS Comando` and the lamp uses `Comando`
directly, without receiver or `Trasmissione`, the report shows no errors. `bcdd` checks the match between
uses and offers, not that the medium is described: establishing that the radio link may lose messages is the responsibility of
whoever writes the CSC.

---

## Chapter 15 — The versions of boundaries

A new lamp keeps the light on longer for those going up to the top floors, and to do so it requires an indication
of the floor from which the command comes. The command changes: the CSC `Comando` moves to version 0.2. The old
button, however, provides only version 0.1. This chapter describes how to indicate a precise version of
a CSC, in which cases two lines that cite the same CSC match, and how a part can provide two versions of the
same boundary.

### The indicated version

After the name of the CSC, in an `OFFERS` or `USES` line, a version can be indicated: `USES Comando VERSION
0.2`. The **indicated version** identifies the version of the CSC to which the line refers. A line without a version does not
fix any: `bcdd` accepts the file of the CSC at any version, and a `USES` line without a version
matches any `OFFERS` line of the same CSC. An `OFFERS` line without a version, on the other hand, does not satisfy
a `USES` line that indicates a version (see the table below).

Version 0.2 of `Comando` adds the parameter `piano` to the event `accendi`:

```
-- The command that the button sends to the lamp.
-- VERSION 0.2: the command indicates the floor of the pressed button. Pending approval.

CSC Comando VERSION 0.2
  STATUS HYPOTHESIS
  PURPOSE "The button commands the lamp to switch on and indicates from which floor"

  EVENT OUT  accendi(piano: Integer [0 .. 5])

  GUARANTEE c1: VERBAL "At least 0.2 s pass between two accendi"
                VERIFY BY INSPECTION "the recorded commands"
  GUARANTEE c2: VERBAL "The parameter piano is the floor of the pressed button"
                VERIFY BY JUDGEMENT "a person who presses the button on each floor and reads the recorded commands"
END
```

A folder can contain only one file `Comando.csc`; version 0.2 is therefore in another folder,
`versioni`, while 0.1 remains in the folder of the other files.

The new lamp indicates version 0.2:

```
-- The new lamp, which keeps the light on longer for those going up to the top floors.

ENTITY LampadaNuova VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "The lamp switches on at the command and stays on longer if the command comes from the top floors"

  USES   Comando VERSION 0.2
  USES   Alimentazione
  OFFERS Luce

  GUARANTEE ln1: VERBAL "After an accendi the light switches on within 0.5 s"
                 VERIFY BY JUDGEMENT "a person who observes the lamp while the command is sent"
  GUARANTEE ln2: VERBAL "The light switches off 90 s after the last accendi, or 120 s after if the last accendi comes from the fourth or fifth floor, with a tolerance of 5 s"
                 VERIFY BY JUDGEMENT "a person with a stopwatch"
END
```

### The match between two lines

A `USES` line of a part is satisfied if there is an `OFFERS` line of another part, or a `USES` line
of the entity, with the same name and a version that **matches**:

| The `USES` line of the part | The other line | Correspondence |
|---|---|---|
| `USES Comando` | `OFFERS Comando`, with or without version | yes |
| `USES Comando VERSION 0.2` | `OFFERS Comando VERSION 0.2` | yes |
| `USES Comando VERSION 0.2` | `OFFERS Comando VERSION 0.1` | no |
| `USES Comando VERSION 0.2` | `OFFERS Comando`, without version | no |

The last row of the table shows that an `OFFERS` line without a version does not satisfy a `USES` line that
indicates a version. Versions are compared as character strings: `0.1` and `0.10` are different versions. `bcdd` does not assess whether two
different versions are compatible in content: a version that only adds a parameter remains a
different version.

### The new lamp with the old button

The button of chapter 13 declares `OFFERS Comando`, without a version: when it was written only
0.1 existed. In an entity with the old button and the new lamp the report shows:

```
1. ERRORS: 2
  line 12: [E17] the part pulsante provides connector Comando: no other part of LuceScale uses it, nor does LuceScale provide it from outside
  line 13: [E14] the part lampada uses connector Comando VERSION 0.2: no other part of LuceScale provides it, nor does LuceScale use it from outside
…
8. USES WITHIN ENTITIES: 2
  line 13: lampada uses Comando VERSION 0.2: nobody provides it
  line 13: lampada uses Alimentazione: LuceScale uses it from outside (line 9)
```

The lamp indicates version 0.2 and no part provides it (E14); the command provided by the button does not match the
`USES` line of the lamp, so no part uses it (E17). The same report is obtained if the button writes `OFFERS
Comando VERSION 0.1`.

### Two versions of the same boundary

In the block of flats the ground-floor lamp remains the old one and the new lamp is installed on the top floor.
The button must then satisfy both lamps and provides the two versions of the command:

```
-- The staircase button, one of the parts of the light.
-- VERSION 0.2: provides the command in versions 0.1 and 0.2. Pending approval.

ENTITY Pulsante VERSION 0.2
  STATUS HYPOTHESIS
  PURPOSE "The button receives the press and commands the lamp"

  OFFERS Pressione
  OFFERS Comando VERSION 0.1
  OFFERS Comando VERSION 0.2

  GUARANTEE pu1: VERBAL "Each press is followed by an accendi within 0.1 s"
                 VERIFY BY INSPECTION "the recorded presses and commands"
END
```

An entity that provides two versions of the same CSC keeps the guarantees of each of them in full: the consumer of 0.1 can count
on the guarantees of 0.1, the consumer of 0.2 on those of 0.2. The way in which the two versions coexist in the
button is not written: it is a choice of whoever implements it.

To check the button, `bcdd` must find both versions of `Comando`. Without the option `--dir` it finds
only the file in the folder of the checked file, which contains version 0.1, and reports it with `expected VERSION
0.2`, that is, with the version indicated in the line:

```
$ bcdd check --strict Pulsante.csc
bcdd check --strict Pulsante.csc
…
    line 9: OFFERS Comando in Comando.csc at line 3: VERSION 0.1, STATUS HYPOTHESIS, no errors
    line 10: OFFERS Comando in Comando.csc at line 3: VERSION 0.1, STATUS HYPOTHESIS, no errors, expected VERSION 0.2
```

The option `--dir` indicates another folder in which to search (chapter 13):

```
$ bcdd check --strict --dir versioni Pulsante.csc
bcdd check --strict --dir versioni Pulsante.csc
lines: 14 (recognised 9, comments 2, blank 3, unrecognised 0)
blocks: 1
  line 4: ENTITY Pulsante VERSION 0.2, STATUS HYPOTHESIS
    line 8: OFFERS Pressione in Pressione.csc at line 3: VERSION 0.1, STATUS HYPOTHESIS, no errors
    line 9: OFFERS Comando in Comando.csc at line 3: VERSION 0.1, STATUS HYPOTHESIS, no errors
    line 10: OFFERS Comando in versioni/Comando.csc at line 4: VERSION 0.2, STATUS HYPOTHESIS, no errors

1. ERRORS: 0

2. DEGREE OF THE CONTRACTUAL LINES
  verbal: 1
  formal: 0
  declared extension: 0
  unrecognised: 0
  line 12: GUARANTEE pu1 verbal

3. UNDECIDED: 0

4. PENDING APPROVAL, NOT CONTRACT: 1
  line 12: GUARANTEE pu1

5. UNRECOGNISED LINES: 0

6. UNDECLARED TYPES: 0

7. CSCs NAMED BUT NOT CHECKED: 0

8. USES WITHIN ENTITIES: 0

outcome: no errors
```

The entity with the two lamps:

```
-- The staircase light, with the old lamp on the ground floor and the new one on the top floor.

ENTITY LuceScale VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "The person on the stairs presses the button and has light to go up or down"

  OFFERS Pressione
  OFFERS Luce
  USES   Alimentazione

  COMPOSED OF
    pulsante      : Pulsante
    lampada       : Lampada
    lampada_alta  : LampadaNuova

  GUARANTEE ls1: VERBAL "When someone presses the button, the light switches on"
                 VERIFY BY JUDGEMENT "a person who presses the button and watches"
END
```

```
$ bcdd check --strict LuceScale.csc
bcdd check --strict LuceScale.csc
lines: 18 (recognised 13, comments 1, blank 4, unrecognised 0)
blocks: 1
  line 3: ENTITY LuceScale VERSION 0.1, STATUS HYPOTHESIS
    line 7: OFFERS Pressione in Pressione.csc at line 3: VERSION 0.1, STATUS HYPOTHESIS, no errors
    line 8: OFFERS Luce in Luce.csc at line 3: VERSION 0.1, STATUS HYPOTHESIS, no errors
    line 9: USES Alimentazione in Alimentazione.csc at line 3: VERSION 0.1, STATUS HYPOTHESIS, no errors
    line 12: pulsante : Pulsante in Pulsante.csc at line 4: VERSION 0.2, STATUS HYPOTHESIS, no errors
    line 13: lampada : Lampada in Lampada.csc at line 3: VERSION 0.1, STATUS HYPOTHESIS, no errors
    line 14: lampada_alta : LampadaNuova in LampadaNuova.csc at line 3: VERSION 0.1, STATUS HYPOTHESIS, no errors

1. ERRORS: 0

2. DEGREE OF THE CONTRACTUAL LINES
  verbal: 1
  formal: 0
  declared extension: 0
  unrecognised: 0
  line 16: GUARANTEE ls1 verbal

3. UNDECIDED: 0

4. PENDING APPROVAL, NOT CONTRACT: 1
  line 16: GUARANTEE ls1

5. UNRECOGNISED LINES: 0

6. UNDECLARED TYPES: 0

7. CSCs NAMED BUT NOT CHECKED: 0

8. USES WITHIN ENTITIES: 4
  line 13: lampada uses Comando: it is provided by pulsante (line 12)
  line 13: lampada uses Alimentazione: LuceScale uses it from outside (line 9)
  line 14: lampada_alta uses Comando VERSION 0.2: it is provided by pulsante (line 12)
  line 14: lampada_alta uses Alimentazione: LuceScale uses it from outside (line 9)

outcome: no errors
```

The old lamp uses `Comando` without a version and the new lamp indicates 0.2: the button satisfies
both lamps. In the line of section 8 for the old lamp the button appears only once, even though it provides two
versions that match the `USES` line of the lamp.

### Summary

- In an `OFFERS` or `USES` line the **version** of the cited CSC can be indicated.
- A `USES` line without a version matches any `OFFERS` line of the same CSC; a `USES` line with a
  version matches only an `OFFERS` line that indicates the same version.
- An entity can provide two versions of the same CSC and keeps the guarantees of each of them in full.
- A version different from the indicated one is not an error of the cited CSC: the report shows it with
  the indication `expected VERSION`.

### Special cases

**Indicated version not found.** If the new lamp is checked without `--dir`, version 0.1 is found:

```
    line 7: USES Comando in Comando.csc at line 3: VERSION 0.1, STATUS HYPOTHESIS, no errors, expected VERSION 0.2
```

It is not an error: `bcdd` reports that the file found does not contain the indicated version.

**Same CSC with and without a version.** Among lines of the same type, a line without a version applies to all
versions: written together with a line with a version of the same name, it is a duplicate of it (E01). The same holds for two lines with the same
version. If line 3 is `OFFERS Comando` and line 4 `OFFERS Comando VERSION 0.2`, and lines 5 and 6 are
both `OFFERS Pressione VERSION 0.1`, the report shows:

```
1. ERRORS: 2
  line 4: [E01] name already used at line 3: Comando
  line 6: [E01] name already used at line 5: Pressione
```

---

## Chapter 16 — The number of copies of a part

The block of flats has five floors, and on each floor there is a button. The buttons are identical: each provides
`Pressione` and `Comando`. This chapter describes how to indicate the number of copies of a part and what each
copy guarantees.

### Multiplicity

In the line of a part, after the name of the entity that describes it (here `Pulsante`), the number of copies
of the part contained in the entity can be indicated between square brackets: `pulsante : Pulsante [1 .. 5]` indicates from one to five copies. This
indication is called **multiplicity**. The two numbers, the minimum and the maximum, are integers, and the minimum does not
exceed the maximum. Without multiplicity a part has exactly one copy.

```
-- The staircase light, with one button per floor.

ENTITY LuceScale VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "The person on the stairs presses the button on their floor and has light to go up or down"

  OFFERS Pressione
  OFFERS Luce
  USES   Alimentazione

  COMPOSED OF
    pulsante : Pulsante [1 .. 5]
    lampada  : Lampada

  GUARANTEE ls1: VERBAL "When someone presses any one of the buttons, the light switches on"
                 VERIFY BY JUDGEMENT "a person who presses the button on each floor and watches"
  GUARANTEE ls2: VERBAL "The light switches off 90 s after the last press on any one of the buttons, with a tolerance of 5 s"
                 VERIFY BY JUDGEMENT "a person who presses buttons on different floors and measures with a stopwatch"
END
```

The entity guarantees now refer to “any one of the buttons”.

### What each copy guarantees

Each copy keeps in full the guarantees of the entity that describes the part: each button provides `Pressione`
and `Comando` and keeps the guarantee `pu1`. Multiplicity establishes nothing else:

- it does not indicate when a copy is present: the copies remain throughout operation;
- it does not distinguish the copies from one another: none has a name that distinguishes it from the others, none has precedence
  over the others;
- it does not indicate where the copies are located: that there is one button per floor is written in the text of the
  purpose, not in the multiplicity.

A copy does not use what another copy of the same part provides: the `OFFERS` line of one copy does not satisfy
the `USES` line of another copy.

### The report

```
$ bcdd check --strict LuceScale.csc
bcdd check --strict LuceScale.csc
lines: 19 (recognised 14, comments 1, blank 4, unrecognised 0)
blocks: 1
  line 3: ENTITY LuceScale VERSION 0.1, STATUS HYPOTHESIS
    line 7: OFFERS Pressione in Pressione.csc at line 3: VERSION 0.1, STATUS HYPOTHESIS, no errors
    line 8: OFFERS Luce in Luce.csc at line 3: VERSION 0.1, STATUS HYPOTHESIS, no errors
    line 9: USES Alimentazione in Alimentazione.csc at line 3: VERSION 0.1, STATUS HYPOTHESIS, no errors
    line 12: pulsante : Pulsante in Pulsante.csc at line 3: VERSION 0.1, STATUS HYPOTHESIS, no errors
    line 13: lampada : Lampada in Lampada.csc at line 3: VERSION 0.1, STATUS HYPOTHESIS, no errors

1. ERRORS: 0

2. DEGREE OF THE CONTRACTUAL LINES
  verbal: 2
  formal: 0
  declared extension: 0
  unrecognised: 0
  line 15: GUARANTEE ls1 verbal
  line 17: GUARANTEE ls2 verbal

3. UNDECIDED: 0

4. PENDING APPROVAL, NOT CONTRACT: 2
  line 15: GUARANTEE ls1
  line 17: GUARANTEE ls2

5. UNRECOGNISED LINES: 0

6. UNDECLARED TYPES: 0

7. CSCs NAMED BUT NOT CHECKED: 0

8. USES WITHIN ENTITIES: 2
  line 13: lampada uses Comando: it is provided by pulsante (line 12)
  line 13: lampada uses Alimentazione: LuceScale uses it from outside (line 9)

outcome: no errors
```

In the report the citation of the part does not show the multiplicity: `line 12: pulsante : Pulsante in
Pulsante.csc`. For the purposes of closure the line counts as a single part, whatever the number of copies.

### Summary

- The **multiplicity** `[m .. n]` indicates that the entity contains from `m` to `n` copies of a part; without
  multiplicity the part has one copy.
- Each copy keeps in full the guarantees of the part; none has precedence and none uses what another copy provides.
- Multiplicity does not indicate when a copy is present, how the copies are distinguished, or where they are located.

### Special cases

**Minimum greater than the maximum.** With `[5 .. 1]`:

```
1. ERRORS: 1
  line 12: [E19] the part pulsante has an invalid number of copies: [5 .. 1]. Write [minimum .. maximum] with two integers: the minimum 0 or more, the maximum at least 1 and not smaller than the minimum
```

The line still counts as a part: closure is checked as if the multiplicity were correct. The same error
appears for a limit with a decimal part, such as `[1.5 .. 5]`. The minimum 0 indicates a part that may be
absent (chapter 19).

**Incomplete multiplicity.** The line `pulsante : Pulsante [1 .. ]` is not recognised and is not a part:
the entity turns out to lack the button, with the errors of chapter 13.

```
1. ERRORS: 2
  line 7: [E16] the public connector Pressione of LuceScale (provided) is not assigned to any part
  line 13: [E14] the part lampada uses connector Comando: no other part of LuceScale provides it, nor does LuceScale use it from outside
…
5. UNRECOGNISED LINES: 1
  line 12: pulsante : Pulsante [1 .. ]
```

**Copies that must each use the command of the others.** A button has an indicator light that flashes at every
command, including those of the other buttons. For this reason it provides and uses `Comando`:

```
-- The button with the indicator light.

ENTITY PulsanteSpia VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "The button receives the press, commands the lamp and lights its indicator at every command"

  OFFERS Pressione
  OFFERS Comando
  USES   Comando

  GUARANTEE ps1: VERBAL "Each press is followed by an accendi within 0.1 s"
                 VERIFY BY INSPECTION "the recorded presses and commands"
  GUARANTEE ps2: VERBAL "At every accendi, sent by this button or by another, the indicator light of the button flashes for 1 s"
                 VERIFY BY JUDGEMENT "a person who presses a button and watches the indicator lights of the others"
END
```

In an entity with `pulsante : PulsanteSpia [1 .. 5]` the copy that sends the command does not satisfy the `USES` lines
of the other copies:

```
1. ERRORS: 1
  line 12: [E14] the part pulsante uses connector Comando: no other part of LuceSpia provides it, nor does LuceSpia use it from outside
```

If each button must use the command of the others, the buttons are written as distinct parts, one per floor
(`piano1 : PulsanteSpia`, `piano2 : PulsanteSpia`, …): each part satisfies the `USES` lines of the others.

---

## Chapter 17 — The size of an entity

The staircase light is divided into a button and a lamp. The lamp could be divided further, into a
relay, a timer and a light bulb. This chapter provides the criterion for establishing when an entity has the
appropriate size and when it should not be divided further.

### The criterion

Whoever implements an entity, a person or a language model, works from its description.
An entity has the appropriate size when whoever implements it is able to consider together:

- the CSCs of the boundaries that the entity provides and uses;
- the entity guarantees;
- the boundaries of the neighbouring parts.

The **neighbouring parts** of a part are the other parts of the same entity that cite one of its CSCs: the
button and the lamp are neighbouring parts, because both cite `Comando`. Of a neighbouring part only
what is observable from outside counts: the CSCs it cites and its entity guarantees, not its parts nor the way it is
implemented.

If an entity is too large to be considered in full, it is divided into parts, each of
which respects the same criterion. The language does not fix a numerical threshold: the criterion indicates an upper
limit, not a lower one.

### Why the light is divided into button and lamp

The button and the lamp are implemented by different people, with different skills, and the command that passes
between them is observable. Each of the two parts is described with few boundaries and few guarantees, and the
division reduces what each implementer must consider.

The lamp, on the other hand, is not divided further. The relay, the timer and the light bulb are choices of whoever
implements the lamp (chapter 1): nothing passes between them that needs to be observable from outside the lamp.
Describing them as parts would fix choices that belong to the implementer, without reducing what the implementer
must consider.

### The sign of excessive division

An entity consisting of a single part, which provides and uses the same boundaries as the part, repeats the part without
adding anything: it is the sign of **excessive division**.

```
-- The lamp divided further: an entity with a single part.

ENTITY Apparecchio VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "The device of the staircase lamp"

  USES   Comando
  USES   Alimentazione
  OFFERS Luce

  COMPOSED OF
    lampada : Lampada
END
```

```
$ bcdd check --strict Apparecchio.csc
…
8. USES WITHIN ENTITIES: 2
  line 12: lampada uses Comando: Apparecchio uses it from outside (line 7)
  line 12: lampada uses Alimentazione: Apparecchio uses it from outside (line 8)

outcome: no errors
```

The report shows no errors: excessive division is not a writing error, and recognising it is the responsibility of whoever
writes. The entity `Apparecchio` is removed, and `Lampada` is used directly in its place.

### Summary

- An entity has the appropriate size when whoever implements it is able to consider together its boundaries,
  its entity guarantees and the boundaries of the neighbouring parts.
- The **neighbouring parts** of a part are the other parts of the same entity that cite the same CSC.
- An entity that is too large is divided into parts; an internal choice of the implementer does not become a part.
- An entity with a single part that provides and uses the same boundaries signals excessive division.

### Special cases

**Entity too large.** `bcdd` does not measure the size of an entity: an entity with many boundaries and many
guarantees is as correctly written as a small one. Applying the criterion is left to the judgement of whoever writes.

**Parts without observable boundaries.** If nothing observable passes between two candidate parts, there
is no CSC to write between them: the two parts are, in fact, a single entity.

---

## Chapter 18 — Scenarios on several boundaries

The scenarios of part one (chapters 1-10) name elements of a single boundary. With the division of chapter 11
the scenarios `s1`, `s2` and `s3`, which name both the press and the light, can no longer be written in either
of the two CSCs. This chapter describes where they are written: in the entity.

### The entity scenario

An **entity scenario** is a scenario written in an entity, in which every name of an event, state or request
is preceded by the name of the CSC it belongs to and by a full stop: `Pressione.premuto`, `Luce.modo`. A name
written in this form is called a **qualified name**.

A CSC describes only its own boundary and cannot establish an order between what happens on two different
boundaries. The entity provides or uses both boundaries, and the entity scenario is the form in which that order is written.

In the entity `LuceScale` of chapter 13 four scenarios are added, after the entity guarantees:

```
  SCENARIO ls-s1 EXPECT ADMITTED
    @0 s     Pressione.premuto
    @1 s     Luce.modo = accesa
  SCENARIO ls-s2 EXPECT ADMITTED
    @0 s     Pressione.premuto    Luce.modo = accesa
    @85 s    Luce.avviso
    @90 s    Luce.modo = spenta
    @100 s   Pressione.premuto    Luce.modo = accesa
  SCENARIO ls-s3 EXPECT REJECTED
    @0 s     Pressione.premuto    Luce.modo = accesa
    @30 s    Luce.modo = spenta
  SCENARIO ls-s4 GIVEN Luce.modo = in_pulizia EXPECT ADMITTED
    @0 s     Pressione.premuto    Luce.modo = in_pulizia
END
```

The scenario `ls-s1` reads: at instant 0 the button is pressed and at instant 1 the light is on. The scenarios `ls-s2`,
`ls-s3` and `ls-s4` are the scenarios `s1`, `s2` and `s3` of `UsoLuce`, rewritten with the qualified names and with the
switch-off time of 90 seconds.

In other respects an entity scenario is written like a CSC scenario (chapter 9): instants in chronological order,
starting state with `GIVEN`, expected outcome with `EXPECT`. An entity scenario is an example, not an obligation: it is not a contractual
line and it does not forbid what it does not describe. It establishes neither an order between the parts nor a
priority, and it does not describe a channel: it reports what is observed on the boundaries of the entity.

### What bcdd checks

```
$ bcdd check --strict LuceScale.csc
bcdd check --strict LuceScale.csc
lines: 35 (recognised 29, comments 1, blank 5, unrecognised 0)
…
1. ERRORS: 0
…
outcome: no errors
```

For each qualified name `X.y` `bcdd` checks two conditions: that `X` is a CSC provided or used by the entity,
and that the CSC `X` contains the element `y` of the expected kind. The expected kind is a state in
`Luce.modo = accesa`, an event in `Pressione.premuto`, a request between the parentheses of a lifecycle phase. It also checks the parameters of the events and
the chronological order of the instants, as in the CSC.

An entity scenario names only the public boundaries of the entity, never the internal boundaries between its parts.

### Summary

- An **entity scenario** is written in the entity and uses the **qualified names** `Csc.nome`.
- It is the place in which the order between what happens on two different boundaries is written.
- It names only the public boundaries of the entity.
- Like every scenario, it is an example: it is not a contractual line and it does not forbid what it does not describe.

### Special cases

**Internal boundary.** If the scenario names `Comando.accendi`, an event of the boundary between the parts:

```
1. ERRORS: 1
  line 23: [E20] Comando.accendi: LuceScale neither provides nor uses connector Comando; a scenario can cite only the connectors of LuceScale
```

**Element not declared in the CSC.** With `Luce.premuto` in place of `Pressione.premuto`:

```
1. ERRORS: 1
  line 23: [E03] name not declared as EVENT: Luce.premuto
```

**Name without the CSC.** With `premuto` in place of `Pressione.premuto`: an entity has no elements of its own, and the
name is not declared.

```
1. ERRORS: 1
  line 23: [E03] name not declared as EVENT: premuto
```

**Value not included in the list of values.** With `Luce.modo = buia` the report shows no errors: in
entity scenarios `bcdd` does not read the lists of values of the cited CSCs and does not check values that are names.
It does, however, check literal values (numbers, strings, `true` and `false`) when the type of the element in
the cited CSC is a base type. Checking a value that is a name is the responsibility of whoever writes.

**Cited CSC not found.** If the file `Luce.csc` is missing, the citation appears in section 7 and the names
`Luce.…` of the scenarios are not checked.

---

## Chapter 19 — A part that may be absent

A twilight sensor can be added to the installation, indicating whether it is dark outside: with the sensor, the
light switches on only when it is dark; without it, it always switches on. Whoever composes the system decides whether to
fit it, and the choice stays fixed for the whole operation. This chapter describes how to write that the entity must work in both cases.

### The optional part

An **optional part** is a part that whoever composes the system may fit or not fit; the choice stays fixed for the
whole operation.
It is written with the minimum 0 in the multiplicity: `crepuscolare : Crepuscolare [0 .. 1]` means “without
twilight sensor, or with one twilight sensor”. In general `[0 .. n]` means “without the part, or with a
number of copies from 1 to `n`”.

The sensor indicates to the button whether it is dark outside, with the CSC `Buio`:

```
-- The twilight sensor, as seen by the button.

CSC Buio VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "The twilight sensor indicates to the button whether it is dark outside"

  STATE      buio : Boolean INITIAL true

  GUARANTEE b1: VERBAL "The state buio becomes true when the outside light falls below 20 lux and false when it exceeds 40 lux"
                VERIFY BY JUDGEMENT "a person with a lux meter next to the sensor, at sunset and at dawn"
END
```

```
-- The twilight sensor, a part that may be absent.

ENTITY Crepuscolare VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "The twilight sensor measures the outside light and indicates it to the button"

  OFFERS Buio
  USES   Alimentazione
END
```

The button now uses `Buio` and moves to version 0.2:

```
-- The staircase button, one of the parts of the light.
-- VERSION 0.2: takes the twilight sensor into account, if present. Pending approval.

ENTITY Pulsante VERSION 0.2
  STATUS HYPOTHESIS
  PURPOSE "The button receives the press and commands the lamp"

  OFFERS Pressione
  OFFERS Comando
  USES   Buio

  GUARANTEE pu1: VERBAL "Each press is followed by an accendi within 0.1 s, if it is dark or if the twilight sensor is not present"
                 VERIFY BY INSPECTION "the recorded presses, sensor state and commands"
END
```

The entity lists the sensor as an optional part:

```
-- The staircase light, with or without the twilight sensor.

ENTITY LuceScale VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "The person on the stairs presses the button and has light to go up or down"

  OFFERS Pressione
  OFFERS Luce
  USES   Alimentazione

  COMPOSED OF
    pulsante     : Pulsante
    lampada      : Lampada
    crepuscolare : Crepuscolare [0 .. 1]

  GUARANTEE ls1: VERBAL "When someone presses the button, the light switches on, if it is dark or if the twilight sensor is not present"
                 VERIFY BY JUDGEMENT "a person who presses the button and watches, by day and by night"
  GUARANTEE ls2: VERBAL "The light switches off 90 s after the last press, with a tolerance of 5 s"
                 VERIFY BY JUDGEMENT "a person who measures with a stopwatch the time between the last press and switch-off"
END
```

### The compositions

A **composition** is each of the complete forms in which an entity can be assembled. With an optional
part there are two compositions: with the part and without it. The entity must hold in each, and `bcdd`
checks them separately.

An entity guarantee holds in every composition. The guarantee “when someone presses the button, the light switches
on” is violated with the twilight sensor and by day. For this reason `ls1` is rewritten: “…if it is dark or if the
twilight sensor is not present”. `bcdd` does not detect this, because the guarantee is written in words.

In the composition without the sensor no part provides `Buio` and no one keeps its guarantees. The guarantee
`b1` is not violated, because the CSC `Buio` is not provided.

### The report

```
$ bcdd check --strict LuceScale.csc
bcdd check --strict LuceScale.csc
lines: 20 (recognised 15, comments 1, blank 4, unrecognised 0)
blocks: 1
  line 3: ENTITY LuceScale VERSION 0.1, STATUS HYPOTHESIS
    line 7: OFFERS Pressione in Pressione.csc at line 3: VERSION 0.1, STATUS HYPOTHESIS, no errors
    line 8: OFFERS Luce in Luce.csc at line 3: VERSION 0.1, STATUS HYPOTHESIS, no errors
    line 9: USES Alimentazione in Alimentazione.csc at line 3: VERSION 0.1, STATUS HYPOTHESIS, no errors
    line 12: pulsante : Pulsante in Pulsante.csc at line 4: VERSION 0.2, STATUS HYPOTHESIS, no errors
    line 13: lampada : Lampada in Lampada.csc at line 3: VERSION 0.1, STATUS HYPOTHESIS, no errors
    line 14: crepuscolare : Crepuscolare in Crepuscolare.csc at line 3: VERSION 0.1, STATUS HYPOTHESIS, no errors

1. ERRORS: 0

2. DEGREE OF THE CONTRACTUAL LINES
  verbal: 2
  formal: 0
  declared extension: 0
  unrecognised: 0
  line 16: GUARANTEE ls1 verbal
  line 18: GUARANTEE ls2 verbal

3. UNDECIDED: 0

4. PENDING APPROVAL, NOT CONTRACT: 2
  line 16: GUARANTEE ls1
  line 18: GUARANTEE ls2

5. UNRECOGNISED LINES: 0

6. UNDECLARED TYPES: 0

7. CSCs NAMED BUT NOT CHECKED: 0

8. USES WITHIN ENTITIES: 5
  line 12: pulsante uses Buio: it is provided by crepuscolare (line 14) (in: with crepuscolare)
  line 12: pulsante uses Buio: nobody provides it (in: without crepuscolare)
  line 13: lampada uses Comando: it is provided by pulsante (line 12)
  line 13: lampada uses Alimentazione: LuceScale uses it from outside (line 9)
  line 14: crepuscolare uses Alimentazione: LuceScale uses it from outside (line 9) (in: with crepuscolare)

9. COMPOSITIONS: 2
  line 3: ENTITY LuceScale: 2
    with crepuscolare
    without crepuscolare

10. DECLARED ABSENCES: 1
  line 12: without crepuscolare: the part pulsante uses connector Buio: no other part of LuceScale provides it, nor does LuceScale use it from outside

outcome: no errors
```

The report has two new sections.

Section 9, `COMPOSITIONS`, lists the compositions of every entity that has more than one: here `with
crepuscolare` and `without crepuscolare`.

Section 10, `DECLARED ABSENCES`, lists what is missing only when the optional part is absent. Without
the sensor, the button uses `Buio` and no part provides it; with the sensor present the gap does not exist. What
is missing only without the part is not an error, but a **declared absence**. It appears in section 10,
preceded by `without` and by the name of the part, and is not included in the count of the `outcome` line.

In section 8 some entries end with `(in: …)`: the **suffix** indicates the compositions in which the entry
holds. `pulsante uses Buio: it is provided by crepuscolare (line 14) (in: with crepuscolare)` holds only when the
sensor is present. An entry without a suffix holds in all compositions. The same suffix accompanies errors.

Sections 9 and 10 appear only if the file contains an entity with more than one composition.

### What an optional part is not

An optional part is present or absent for the whole operation of the installation. It does not describe a part that
appears and disappears while the installation is operating, for example a sensor that is disconnected by day and reconnected
by night, nor a part that operates only in certain operating modes: the language does not provide a
form for these cases.

### Summary

- An **optional part** is written with the multiplicity `[0 .. n]`: the entity has two **compositions**, with the
  part and without it, each fixed for the whole operation.
- Entity guarantees hold in every composition.
- `bcdd` checks every composition; what is missing only without the part is a **declared absence**,
  listed in section 10 and not counted among the errors.
- The **suffix** `(in: …)` indicates the compositions in which an entry or an error holds.

### Special cases

**Error in a single composition.** If the entity contains the button of version 0.1, which does not use `Buio`,
in the composition with the sensor no part uses what the sensor provides:

```
1. ERRORS: 1
  line 14: [E17] the part crepuscolare provides connector Buio: no other part of LuceScale uses it, nor does LuceScale provide it from outside (in: with crepuscolare)
```

The error holds only in the composition with the sensor, as the suffix indicates.

**Optional part without the required `OFFERS` line.** If the sensor does not declare `OFFERS Buio`, no part
provides `Buio` to the button, even when the sensor is present:

```
1. ERRORS: 1
  line 12: [E14] the part pulsante uses connector Buio: no other part of LuceScale provides it, nor does LuceScale use it from outside
…
8. USES WITHIN ENTITIES: 4
  line 12: pulsante uses Buio: nobody provides it
…
10. DECLARED ABSENCES: 0
```

The error appears in both compositions, hence without a suffix. It is not a declared absence, because
the error does not disappear even when the part is present: a declared absence concerns only what is explained by the absence
of the part.

**No copies.** The multiplicity `[0 .. 0]` is an error, because it describes a part that is never present:

```
1. ERRORS: 1
  line 14: [E19] the part crepuscolare has an invalid number of copies: [0 .. 0]. Write [minimum .. maximum] with two integers: the minimum 0 or more, the maximum at least 1 and not smaller than the minimum
```

---

## Chapter 20 — Several forms of the same thing: variants

The staircase light is installed in four forms: the lamp can be a ceiling light or
a wall light, and the command can be a button or a presence sensor. This chapter describes
how to write these forms in a single entity.

### Variants

A **variant** is one of the alternatives of an aspect of the entity, for example the lamp. It is declared
with the line `VARIANT group = choice`: the name to the left of the `=` sign is the **group name**, the one to
the right the **choice**. `VARIANT lampada = soffitto` declares the variant in which the lamp is the ceiling light. The lines that
follow, up to the next `VARIANT` or to `END`, form the **segment** of the variant and hold only with
that choice. The lines that precede the first `VARIANT` are the **common lines** and hold in every
composition.

Variants that have the same group name form a **group** (or **choice group**): among the choices of a
group only one holds. Different groups are independent and combine with one another. With the group `lampada`
(ceiling or wall) and the group `comando` (button or presence) there are four compositions.

Only entity lines are written in a segment: `OFFERS`, `USES`, `COMPOSED OF` with its parts,
entity guarantees and entity scenarios. The purpose, `PURPOSE`, is written among the common lines.

### The files

The presence sensor provides to the person on the stairs a boundary different from the press:

```
-- The presence sensor, as seen by the person on the stairs.

CSC Presenza VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Whoever enters the staircase is detected by the presence sensor without pressing anything"

  EVENT IN   passaggio

  GUARANTEE pz1: VERBAL "A person walking less than 4 m from the sensor is detected as a passaggio"
                 VERIFY BY JUDGEMENT "a person who walks at different distances from the sensor"
END
```

```
-- The presence sensor, one of the two forms of the command.

ENTITY SensorePresenza VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "The sensor detects whoever passes and commands the lamp"

  OFFERS Presenza
  OFFERS Comando
  USES   Alimentazione

  GUARANTEE sp1: VERBAL "Each passaggio is followed by an accendi within 0.2 s"
                 VERIFY BY INSPECTION "the recorded passages and commands"
END
```

The ceiling light and the wall light provide the same boundary, but with different guarantees:

```
-- The ceiling light, one of the two forms of the lamp.

ENTITY Plafoniera VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "The ceiling light switches on at the command and switches off by itself"

  USES   Comando
  USES   Alimentazione
  OFFERS Luce

  GUARANTEE pl1: VERBAL "After an accendi the light is at full brightness within 0.5 s"
                 VERIFY BY JUDGEMENT "a person who observes the ceiling light while the command is sent"
  GUARANTEE pl2: VERBAL "The light switches off 90 s after the last accendi, with a tolerance of 5 s"
                 VERIFY BY JUDGEMENT "a person with a stopwatch"
END
```

```
-- The wall light, one of the two forms of the lamp.

ENTITY Applique VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "The wall light switches on at the command and switches off by itself"

  USES   Comando
  USES   Alimentazione
  OFFERS Luce

  GUARANTEE ap1: VERBAL "After an accendi the light is at full brightness within 0.05 s"
                 VERIFY BY JUDGEMENT "a person who observes the wall light while the command is sent"
  GUARANTEE ap2: VERBAL "The light switches off 90 s after the last accendi, with a tolerance of 5 s"
                 VERIFY BY JUDGEMENT "a person with a stopwatch"
END
```

A single entity describes the four forms:

```
-- The staircase light: ceiling light or wall light, button or presence sensor.

ENTITY LuceScale VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "The person on the stairs has light to go up or down"

  OFFERS Luce
  USES   Alimentazione

  GUARANTEE ls2: VERBAL "The light switches off 90 s after the last command, with a tolerance of 5 s"
                 VERIFY BY JUDGEMENT "a person with a stopwatch"

  VARIANT lampada = soffitto
    COMPOSED OF
      lampada : Plafoniera
  VARIANT lampada = parete
    COMPOSED OF
      lampada : Applique

  VARIANT comando = pulsante
    OFFERS Pressione
    COMPOSED OF
      pulsante : Pulsante
    GUARANTEE ls1: VERBAL "When someone presses the button, the light switches on"
                   VERIFY BY JUDGEMENT "a person who presses the button and watches"
  VARIANT comando = presenza
    OFFERS Presenza
    COMPOSED OF
      presenza : SensorePresenza
    GUARANTEE ls1p: VERBAL "When someone passes in front of the sensor, the light switches on"
                    VERIFY BY JUDGEMENT "a person who enters the staircase and watches"
END
```

The choice of the command changes what the entity provides to the person on the stairs, `Pressione` or `Presenza`: for
this reason the `OFFERS` line is written inside the segment. The part name `lampada` appears in two choices of the same
group: it is the same role, performed by different entities. The short names of guarantees and scenarios, on the other hand, are
unique throughout the entity: `ls1` and `ls1p` have different names.

### Who chooses

No line of the entity indicates which composition is implemented: the entity describes all the admitted
compositions; whoever composes the system implements one of them. The decision is taken when the system is composed and does not
change while the system is operating. No line indicates who decides, when or why; among the choices there is no
preference or order, and none is the default. A condition such as “wall light if there is a wall socket,
otherwise ceiling light” is a decision rule and is not written with variants; if needed, it is written in words
in a guarantee.

### The report

```
$ bcdd check --strict LuceScale.csc
bcdd check --strict LuceScale.csc
lines: 32 (recognised 26, comments 1, blank 5, unrecognised 0)
blocks: 1
  line 3: ENTITY LuceScale VERSION 0.1, STATUS HYPOTHESIS
    line 7: OFFERS Luce in Luce.csc at line 3: VERSION 0.1, STATUS HYPOTHESIS, no errors
    line 8: USES Alimentazione in Alimentazione.csc at line 3: VERSION 0.1, STATUS HYPOTHESIS, no errors
    line 15: lampada : Plafoniera in Plafoniera.csc at line 3: VERSION 0.1, STATUS HYPOTHESIS, no errors
    line 18: lampada : Applique in Applique.csc at line 3: VERSION 0.1, STATUS HYPOTHESIS, no errors
    line 21: OFFERS Pressione in Pressione.csc at line 3: VERSION 0.1, STATUS HYPOTHESIS, no errors
    line 23: pulsante : Pulsante in Pulsante.csc at line 3: VERSION 0.1, STATUS HYPOTHESIS, no errors
    line 27: OFFERS Presenza in Presenza.csc at line 3: VERSION 0.1, STATUS HYPOTHESIS, no errors
    line 29: presenza : SensorePresenza in SensorePresenza.csc at line 3: VERSION 0.1, STATUS HYPOTHESIS, no errors

1. ERRORS: 0

2. DEGREE OF THE CONTRACTUAL LINES
  verbal: 3
  formal: 0
  declared extension: 0
  unrecognised: 0
  line 10: GUARANTEE ls2 verbal
  line 24: GUARANTEE ls1 verbal
  line 30: GUARANTEE ls1p verbal

3. UNDECIDED: 0

4. PENDING APPROVAL, NOT CONTRACT: 3
  line 10: GUARANTEE ls2
  line 24: GUARANTEE ls1
  line 30: GUARANTEE ls1p

5. UNRECOGNISED LINES: 0

6. UNDECLARED TYPES: 0

7. CSCs NAMED BUT NOT CHECKED: 0

8. USES WITHIN ENTITIES: 7
  line 15: lampada uses Comando: it is provided by pulsante (line 23) (in: lampada = soffitto, comando = pulsante)
  line 15: lampada uses Comando: it is provided by presenza (line 29) (in: lampada = soffitto, comando = presenza)
  line 15: lampada uses Alimentazione: LuceScale uses it from outside (line 8) (in: lampada = soffitto)
  line 18: lampada uses Comando: it is provided by pulsante (line 23) (in: lampada = parete, comando = pulsante)
  line 18: lampada uses Comando: it is provided by presenza (line 29) (in: lampada = parete, comando = presenza)
  line 18: lampada uses Alimentazione: LuceScale uses it from outside (line 8) (in: lampada = parete)
  line 29: presenza uses Alimentazione: LuceScale uses it from outside (line 8) (in: comando = presenza)

9. COMPOSITIONS: 4
  line 3: ENTITY LuceScale: 4
    lampada = soffitto, comando = pulsante
    lampada = soffitto, comando = presenza
    lampada = parete, comando = pulsante
    lampada = parete, comando = presenza

10. DECLARED ABSENCES: 0

outcome: no errors
```

Section 9 lists the four compositions. The name of a composition is the sequence of its choices,
in the order in which the groups appear in the file. The entries of section 8 have the suffix described in chapter 19:
`lampada uses Alimentazione: LuceScale uses it from outside (line 8) (in: lampada = soffitto)` holds in both
compositions with the ceiling light.

### A part with variants

If an entity that has variants is in turn a part of another entity, its choices appear in the
compositions of the entity that contains it. In the entity `Condominio`, which contains `scale : LuceScale`, there are
four compositions, and their names are preceded by the name of the part:

```
9. COMPOSITIONS: 4
  line 3: ENTITY Condominio: 4
    scale.lampada = soffitto, scale.comando = pulsante
    scale.lampada = soffitto, scale.comando = presenza
    scale.lampada = parete, scale.comando = pulsante
    scale.lampada = parete, scale.comando = presenza
```

The entity that contains the part must hold in every composition of the part. If `Condominio` provides only
`Luce`, the boundaries `Pressione` and `Presenza` provided by the staircase light are used by no part:

```
1. ERRORS: 2
  line 11: [E17] the part scale provides connector Pressione: no other part of Condominio uses it, nor does Condominio provide it from outside (in: scale.comando = pulsante)
  line 11: [E17] the part scale provides connector Presenza: no other part of Condominio uses it, nor does Condominio provide it from outside (in: scale.comando = presenza)
```

A single choice of a part cannot be fixed from the entity that contains it: the language does not provide a
form for doing so.

Only the choice groups of a part enter the compositions of the entity that contains it, not its optional parts.
From outside a part counts for what it provides and uses, and an optional part of it does not change that: a `Condominio` that contains the staircase
light of chapter 19, with the optional twilight sensor, has a single composition, and its report
does not have sections 9 and 10.

### The limit on compositions

Compositions multiply: every group of two choices and every optional part doubles their number. `bcdd`
checks at most 64 compositions per entity. Beyond this number it does not check the closure of the entity and
reports an error; for example, with seven groups of two choices each:

```
1. ERRORS: 1
  line 1: [E23] entity Troppe has more than 64 compositions: bcdd does not check them one by one. Remove a choice, or divide the entity into smaller entities
…
9. COMPOSITIONS: 0
  line 1: ENTITY Troppe: more than 64, not checked
```

### Summary

- A **variant** (`VARIANT group = choice`) opens a **segment** of lines that hold only with that choice;
  the **common lines** precede the first `VARIANT` and always hold.
- The choices of the same **group** exclude one another; different groups combine, and every combination is a
  composition.
- No line indicates who chooses; the choice does not change while the system is operating.
- The choices of a part appear in the compositions of the entity that contains it; its optional parts do not.
- `bcdd` checks every composition, up to 64, and lists them in section 9.

### Special cases

**Incomplete choice.** If the presence sensor does not declare `OFFERS Comando`, in the compositions with the
sensor no part provides the command to the lamp:

```
1. ERRORS: 2
  line 15: [E14] the part lampada uses connector Comando: no other part of LuceScale provides it, nor does LuceScale use it from outside (in: lampada = soffitto, comando = presenza)
  line 18: [E14] the part lampada uses connector Comando: no other part of LuceScale provides it, nor does LuceScale use it from outside (in: lampada = parete, comando = presenza)
```

The error appears twice, once for each lamp, and each time in a single composition. It is not
a declared absence: there is no optional part in the entity to explain it.

**Group with a single choice.** If the group `lampada` has only the choice `soffitto`:

```
1. ERRORS: 1
  line 13: [E22] choice group lampada has a single choice (soffitto): at least two are needed; a part that may be missing is written with [0 .. 1]
```

A group has at least two choices. A part that
may be present or not is written as an optional part (chapter 19), not with a variant without lines.

**Purpose in a segment.** A `PURPOSE` written immediately after `VARIANT lampada = parete`:

```
1. ERRORS: 1
  line 17: [E21] PURPOSE cannot appear in a VARIANT segment: write it before the first VARIANT
```

**Variant in a CSC.** Variants are written only in entities. A `VARIANT` line in the CSC `Luce`:

```
1. ERRORS: 1
  line 11: [E21] VARIANT cannot appear in a CSC: variants are written in an entity
```

**Common scenario that names a boundary of a single choice.** A scenario among the common lines holds in all
compositions. If it names `Pressione.premuto`, in the compositions with the presence sensor the boundary
`Pressione` is not present:

```
1. ERRORS: 1
  line 13: [E20] Pressione.premuto: LuceScale neither provides nor uses connector Pressione; a scenario can cite only the connectors of LuceScale (in: comando = presenza)
```

The scenario is moved into the segment `comando = pulsante`, where it holds only with the button.

---
## Chapter 21 — The step and the first formulas

The guarantees of the staircase light CSC are written in words: they are checked by judgement. A guarantee
written as a formula, by contrast, has a meaning that a program can check. This chapter introduces the step,
that is the unit with which a formula observes the system. It then introduces the first keywords of formulas and
the operators with which conditions are combined.

`bcdd` recognises the formulas of this chapter and of the two that follow: it checks their form, names and types, and
reports their degree. It does not evaluate them on the scenarios: chapter 24 describes what remains to be checked.

### The step

A **step** is the unit of observation of the system: an instant, with the set of events that occur in it and the
value of the states immediately after those events. Every instant of a scenario (chapter 9), that is every line that
begins with `@`, is a step, and the trace of a scenario is a sequence of steps. A step respects three
rules:

1. the instant of a step does not precede that of the previous step; two consecutive steps may have the
   same instant, like the two instants `@0 s` of scenario `s4`;
2. in a step the same event appears at most once;
3. the value of a state in a step is the value the state takes after the events of the step.

In scenario `s1` the first step is `@0 s premuto modo = accesa`: the event `premuto` occurs at instant 0 and,
after the press, the mode is `accesa`.

The step is a model of observation, not a description of the implementation: it does not imply that the
implementation does everything at the same instant.

### The formula

A **formula** is a guarantee written in a form that a program can check step by step.
It is written after the colon of the line, in place of `VERBAL` and `VERIFY`:

```
  GUARANTEE g1: WHENEVER premuto THEN modo <> spenta AT ONCE
```

A formula has no `VERIFY` line: the way to check it is established by the language, not by whoever
writes the CSC.

Inside a formula appear **conditions on the step**, that is expressions that in every step are true or
false. When a condition is true in a step it is said to **hold** in that step; for an event it is said
instead to **occur**.

| Condition | Holds in the step in which |
|---|---|
| `premuto` | the event `premuto` occurs |
| `modo = accesa` | the state `modo` has the value `accesa` |
| `modo <> spenta` | the state `modo` has a value other than `spenta` |
| `modo IN {accesa, in_pulizia}` | the state `modo` has the value `accesa` or `in_pulizia` |
| `NOT p` | `p` does not hold |
| `p AND q` | `p` and `q` both hold |
| `p OR q` | at least one of `p` and `q` holds |
| `p IMPLIES q` | `p` does not hold, or `q` holds |

In the forms of this chapter and of the two that follow, the lower-case letters `p`, `q` and `c` denote conditions
on the step and the upper-case `P` a formula; from chapter 22 onwards `e` denotes an event, `x` a state, `X` a
request and `d` a duration.

The phases of the lifecycle of a request (chapter 5) are conditions too: `requested(Pulizie)` holds
in the step in which the request `Pulizie` reaches the phase `requested`.

A formula cites only elements declared in the CSC (events, states, values of lists of values,
requests, named constants), numbers and durations.

### Operators and precedence

Besides the logical operators, a condition uses the comparison and calculation operators:

| Operator | Meaning |
|---|---|
| `=`, `<>` | equal, not equal |
| `<`, `<=`, `>`, `>=` | less than, less than or equal, greater than, greater than or equal; between numbers or between durations |
| `+`, `-`, `*`, `/` | sum, difference, product, quotient |
| `^` | power |
| `- x` | the opposite of `x` |
| `x IN {v1, v2, …}` | `x` has one of the listed values |
| `(IF c THEN x ELSE y)` | `x` in the steps in which `c` holds, `y` in the others; always written in parentheses |

The mathematical functions `ABS`, `MIN`, `MAX`, `LOG10`, `ROUND`, `FLOOR` and `CEIL` have their
mathematical meaning. The minus sign between two values is written separated from both: `a - b`. Written without spaces, `a-b` is a
single name, because a name may contain a hyphen between two letters.

Without parentheses the operators apply according to this precedence, from the highest to the lowest:

| Precedence | Operators | Consecutive identical operators |
|---|---|---|
| 1 | `x[i]`, `x.campo` (chapter 23) | left-associative |
| 2 | `^` | not admitted: `a ^ b ^ c` is an error |
| 3 | `-` before a value | right-associative |
| 4 | `*`, `/` | left-associative |
| 5 | `+`, `-` | left-associative |
| 6 | `=`, `<>`, `<`, `<=`, `>`, `>=`, `IN` | not admitted: `a <= b <= c` is an error |
| 7 | `NOT` | right-associative |
| 8 | `AND`, `OR` | the same operator repeats freely; `AND` and `OR` mixed are an error |
| 9 | `IMPLIES` | not admitted: `a IMPLIES b IMPLIES c` is an error |

Thus `NOT a AND b` is `(NOT a) AND b`, `a AND b IMPLIES c` is `(a AND b) IMPLIES c` and `x + y * 2` is `x + (y * 2)`.
For the combinations that the table excludes `bcdd` reports error **E26**; the message indicates how to write
them with parentheses. `a AND b OR c` is written `(a AND b) OR c` or `a AND (b OR c)`, depending on the intended meaning. The examples in the
manual use parentheses whenever a condition combines more than two conditions.

### The first keywords of formulas

A formula is built with four keywords, which establish in which steps a condition must hold. A fifth,
`AT ONCE`, specifies the step of the consequence of `WHENEVER`.

**“Always”: `ALWAYS p`.** In every step `p` holds. `ALWAYS modo <> in_pulizia` states that the light never enters
the cleaning mode.

**“Sooner or later”: `EVENTUALLY p`.** In at least one step `p` holds. `EVENTUALLY avviso` states that in some
step a warning occurs. Written as a guarantee on its own, it would require a warning in every trace. The light, however,
issues a warning only after a press and is not required to issue one if nobody presses.

**“Whenever… then”: `WHENEVER p THEN q`.** In every step in which `p` holds, the condition `q` must hold
in the same step or in a later step. The condition `p` is the **trigger**, the condition `q` is the
**consequence**. With `AT ONCE` the consequence must hold **in the same step** as the trigger, and not later:
`WHENEVER p THEN q AT ONCE`.

**“While”: `WHILE c: P`.** The formula `P` must hold in the steps in which the condition `c` holds, called the
**scope**; the other steps are not considered. `WHILE modo = spenta: ALWAYS NOT avviso` states that in no step in which the
light is off does a warning occur. A formula without `WHILE` concerns all the steps of the trace.

These keywords do not nest: after `ALWAYS`, `EVENTUALLY`, `WHENEVER` and `THEN` a condition on the
step is written, not another formula. A formula has at most one scope, written at the beginning. For a nested
keyword or a second scope `bcdd` reports error **E27**.

### A formula on several lines

A long formula can be split over several lines. A line continues on the next line when it has been left
**open**: it has an unclosed parenthesis, or it ends with an operator or a keyword that requires a continuation,
such as `THEN`, `AND`, `OR`, `IMPLIES`, `WITHIN`, a comma, a comparison or calculation operator. For example:

```
  GUARANTEE g1: WHENEVER premuto THEN
                  modo <> spenta AT ONCE
```

The two lines are a single declaration. A line that begins with a keyword that opens a declaration
(`GUARANTEE`, `SCENARIO`, `END`, …) or with `@` never continues the previous one: a forgotten parenthesis does not
absorb the `END` line of the block into the declaration.

### The staircase light CSC with the first formulas

Guarantee `g1`, “when someone presses the button, the light switches on”, becomes:

```
  GUARANTEE g1: WHENEVER premuto THEN modo <> spenta AT ONCE
```

It reads: whenever `premuto` occurs, in the same step the mode is other than `spenta`. The consequence
is not `modo = accesa`: during cleaning a press leaves the mode `in_pulizia` (guarantee `g7`), and the
light is on all the same. The same consequence can also be written `modo IN {accesa, in_pulizia}`.

Guarantee `g2`, “the light switches off by itself after a while”, becomes:

```
  GUARANTEE g2: WHENEVER modo = accesa THEN modo = spenta
```

In every step in which the light is on, in a later step the light must be off. The time remains indeterminate,
as in the text in words; the time limit is in the detail `g2a` (chapter 22).

A new guarantee, `g8`, which uses `WHILE`, is also added:

```
  GUARANTEE g8: WHILE modo = spenta: ALWAYS NOT avviso
```

A guarantee written as a formula **changes form, but keeps its name**: `g1` remains `g1`, and the
details `g2a` and `g2b` remain details of `g2`. The change of form modifies the text of the approved
CSC, so it requires a new version (chapter 10): 0.3, pending approval. The text in words can be
kept in a comment above the formula. Lines 1-2 and 15-18 of version 0.3 are:

```
-- The staircase light, as seen by the person on the stairs and by the caretaker.
-- VERSION 0.3: g1 and g2 written as formulas; g8 added. Pending approval.
```

```
  -- g1: «When someone presses the button, the light switches on»
  GUARANTEE g1: WHENEVER premuto THEN modo <> spenta AT ONCE
  -- g2: «The light switches off by itself after a while»
  GUARANTEE g2: WHENEVER modo = accesa THEN modo = spenta
```

The line of `g8` is line 33, immediately before the assumption `a1`.

### The degree of formulas and the report

The **degree** of a guarantee (chapter 2) is derived from the form of the line: no line declares it. A
guarantee written as a formula, which `bcdd` recognises in full, has **formal** degree:

```
$ bcdd check UsoLuce.csc
bcdd check UsoLuce.csc
lines: 50 (recognised 41, comments 4, blank 5, unrecognised 0)
blocks: 1
  line 4: CSC UsoLuce VERSION 0.3, STATUS HYPOTHESIS

1. ERRORS: 0

2. DEGREE OF THE CONTRACTUAL LINES
  verbal: 8
  formal: 3
  declared extension: 0
  unrecognised: 0
  line 16: GUARANTEE g1 formal
  line 18: GUARANTEE g2 formal
  line 19: GUARANTEE g2a verbal
  line 21: GUARANTEE g2b verbal
  line 23: GUARANTEE g3 verbal
  line 25: GUARANTEE g4 verbal
  line 27: GUARANTEE g5 verbal
  line 29: GUARANTEE g6 verbal
  line 31: GUARANTEE g7 verbal
  line 33: GUARANTEE g8 formal
  line 34: ASSUME a1 verbal

3. UNDECIDED: 0

4. PENDING APPROVAL, NOT CONTRACT: 9
  line 16: GUARANTEE g1
  line 18: GUARANTEE g2
  line 23: GUARANTEE g3
  line 25: GUARANTEE g4
  line 27: GUARANTEE g5
  line 29: GUARANTEE g6
  line 31: GUARANTEE g7
  line 33: GUARANTEE g8
  line 34: ASSUME a1

5. UNRECOGNISED LINES: 0

6. UNDECLARED TYPES: 0

7. CSCs NAMED BUT NOT CHECKED: 0

14. TO BE JUDGED: 2
  line 19: GUARANTEE g2a DETAILS g2: consistency between the line and the line that details it, one of the two in words
  line 21: GUARANTEE g2b DETAILS g2: consistency between the line and the line that details it, one of the two in words

15. CHECKS NOT EXECUTED: 3
  scenarios: lines 37, 42, 45, 47
  coverage of the triggers: lines 16, 18, 33
  consistency of assumptions and guarantees: lines 16, 18, 33

outcome: no errors
```

The three formulas have formal degree. In section 4 they appear as lines pending approval, because version 0.3 is
pending approval; the details `g2a` and `g2b`, by contrast, have their own `STATUS RATIFIED BY D-12`.

Section 14, `TO BE JUDGED` (chapter 8), lists the two details: they are written in words and make a formula
precise, and their consistency with `g2` has to be judged by a person.

Section 15, `CHECKS NOT EXECUTED`, lists the checks on formulas that `bcdd` does not execute, with the lines to
which they would apply:

- `scenarios`: whether the scenarios really have the outcome they declare with `EXPECT`; the entry lists the scenarios of a
  block that contains at least one formula;
- `coverage of the triggers`: whether the trigger of every formal guarantee occurs in at least one scenario;
- `consistency of assumptions and guarantees`: whether the formal guarantees and assumptions can hold together.

A line of section 15 is neither satisfied nor violated: the check has not been executed. The report shows it so
that no formula appears to have undergone checks that were not executed. Chapter 24 describes these checks.
The section appears only when it has at least one entry.

### Summary

- A **step** is an instant, with the events that occur in it and the value of the states immediately after; two
  consecutive steps may have the same instant, and every instant of a scenario is a step.
- A **formula** is a guarantee that a program can check step by step; it has no `VERIFY`.
- The first keywords of formulas are `ALWAYS` (always), `EVENTUALLY` (sooner or later), `WHENEVER … THEN`
  (whenever… then) and `WHILE` (while); `AT ONCE` (in the same step) specifies the consequence of
  `WHENEVER`. Conditions are combined with `NOT`, `AND`, `OR`, `IMPLIES`, with the comparison and calculation
  operators, with `IN {…}` and with `(IF … THEN … ELSE …)`.
- `AND` and `OR` mixed require parentheses; so do two consecutive comparisons, two `IMPLIES` or two `^` (E26).
  The keywords of formulas do not nest (E27).
- A formula is split over several lines by leaving open the line that continues.
- A guarantee written as a formula keeps its name; the change of form requires a new
  version.
- The degree of a formula is **formal**. `bcdd` checks its form, names and types, and reports in section 15 the
  checks it does not execute.

### Special cases

**A line that begins with `THEN`.** If `g1` breaks the line before `THEN`, the first line does not require a
continuation, and the line that begins with `THEN` is a declaration on its own. Neither of the two lines is recognised, and `g1` has
the degree `unrecognised`:

```
5. UNRECOGNISED LINES: 2
  line 16: GUARANTEE g1: WHENEVER premuto
  line 17: THEN modo <> spenta AT ONCE
…
outcome: no errors; unrecognised lines: 2 (see section 5)
```

The line must be broken after `THEN`, as in the example of the section “A formula on several lines”.

**Undeclared name in a formula.** With `premuta` in place of `premuto`, `bcdd` reports error **E24**, undeclared
name:

```
1. ERRORS: 1
  line 16: [E24] name not declared: premuta
```

The line remains recognised and formal: the form is correct, the name is not. Each position in a formula requires
an element of a certain kind (an event, a state, a request, a value). For a name of a different kind, too, `bcdd`
reports error E24.

**`AND` and `OR` without parentheses.** The consequence `modo = accesa OR modo = in_pulizia AND NOT avviso` mixes `AND`
and `OR`:

```
1. ERRORS: 1
  line 16: [E26] AND and OR together without parentheses: write (a AND b) OR c, or a AND (b OR c)
```

**A formula inside another.** `ALWAYS (modo = spenta IMPLIES ALWAYS NOT avviso)` contains a formula in place
of a condition:

```
1. ERRORS: 1
  line 33: [E27] ALWAYS inside another form: the language does not nest ALWAYS, EVENTUALLY, WHENEVER and their shorthands
```

The correct form is that of `g8`, with the scope `WHILE`.

**Approval of a CSC with formulas.** The file passes `bcdd check --strict`, and `bcdd ratify` records its
approval as for a CSC with guarantees in words only. On a copy of version 0.3:

```
$ bcdd ratify UsoLuce.csc --all D-15
approved with D-15 in CSC UsoLuce: 1 line
  line 5: CSC UsoLuce
contract: 11
```

In this chapter version 0.3 remains pending approval, because chapters 22 and 23 add further formulas to it.

**The formula as a detail.** As an alternative to replacement, the guarantee in words remains and the formula is
added as its detail (chapter 8):

```
  GUARANTEE g1: VERBAL "When someone presses the button, the light switches on"
                VERIFY BY JUDGEMENT "a person who presses the button and watches"
  GUARANTEE g1a DETAILS g1: WHENEVER premuto THEN modo <> spenta AT ONCE
```

Both forms are admitted. With the detail the contract contains both lines, and the detail is pending
approval. In the report `g1a` is formal, and section 14 lists its consistency with `g1` among the lines to be
judged:

```
14. TO BE JUDGED: 3
  line 17: GUARANTEE g1a DETAILS g1: consistency between the line and the line that details it, one of the two in words
  line 20: GUARANTEE g2a DETAILS g2: consistency between the line and the line that details it, one of the two in words
  line 22: GUARANTEE g2b DETAILS g2: consistency between the line and the line that details it, one of the two in words
```

**Formula in an entity.** An entity guarantee can be written as a formula. The elements are named with the
qualified name `Csc.elemento`, as in entity scenarios (chapter 18). For example, in the entity `LuceScale` the
following guarantee

```
  GUARANTEE ls1: WHENEVER Pressione.premuto THEN Luce.modo <> spenta WITHIN 1 s
```

has formal degree:

```
2. DEGREE OF THE CONTRACTUAL LINES
  verbal: 2
  formal: 1
  declared extension: 0
  unrecognised: 0
  line 15: GUARANTEE ls1 formal
  line 16: GUARANTEE ls2 verbal
  line 18: GUARANTEE ls3 verbal
```

`Pressione` and `Luce` must be CSCs that the entity provides or uses (otherwise: error E20), and the element must
be declared in that CSC (otherwise: error E24). For a simple name, without the CSC in front, `bcdd` also reports
error E24. In
this version `bcdd` does not check the type of the elements in entity formulas, but only the name and the
kind.

---

## Chapter 22 — Time in formulas

The detail `g2a` states that the light switches off 90 seconds after the last press, with a 5-second
tolerance. The keywords of chapter 21 are not enough to express it: they establish in which steps a condition
holds, but do not measure the time that passes between two steps. This chapter introduces the time limit, which
measures the time that follows a step. It then introduces the forms that concern what has already occurred in the
trace: the elapsed time, the count and the previous value. Finally it introduces repeating scenarios.

### Within a certain time: WITHIN

The **time limit** is written with `WITHIN` followed by a duration, and is added to `EVENTUALLY` or to
`WHENEVER`:

| Form | Meaning |
|---|---|
| `EVENTUALLY p WITHIN d` | `p` holds in some step within `d` of the start of the scope |
| `WHENEVER p THEN q WITHIN d` | in every step in which `p` holds, `q` must hold within `d` of the trigger step, the step itself included |

The duration always has a unit, `s` or `ms`. With `WITHIN` the guarantee has a deadline: if the consequence does not hold
within the duration, the guarantee is violated. `WITHIN` and `AT ONCE` do not go in the same guarantee (error E27).

For a formula without `WHILE` the start of the scope is the first step of the trace. With `WHILE` the scope may
consist of several separate stretches of the trace: each stretch is a scope of its own, and the duration runs
from the start of each stretch. `WHILE modo = in_pulizia: EVENTUALLY avviso WITHIN 5 s` therefore requires a
warning in every cleaning stretch, within 5 s of its start. A stretch that ends without a warning before
5 s have elapsed violates the guarantee.

In the staircase light CSC a detail of guarantee `g4` is added: a cleaning request receives a
response within one second.

```
  GUARANTEE g4a DETAILS g4: WHENEVER requested(Pulizie) THEN accepted(Pulizie) OR rejected(Pulizie) WITHIN 1 s
```

### The elapsed time: TIME SINCE

`TIME SINCE e` measures the **elapsed time** since the last step in which the event `e` occurred.
`TIME SINCE premuto <= 95 s` holds in the steps in which the last press dates back no more than 95 seconds.

In the very step in which `e` occurs, `TIME SINCE e` is 0. Before `e` has occurred at least once its
value is infinite: `TIME SINCE premuto > 90 s` is true even if nobody has ever pressed, and
`TIME SINCE premuto <= 95 s` is false. Infinity is used only in comparisons, not in calculations. To exclude the
case in which the event has never occurred, a condition such as `TIME SINCE premuto >= 85 s` is combined with the
count `COUNT(premuto) > 0`, which holds only if the event has already occurred.

### The count: COUNT

The **count** `COUNT(e)` is the number of steps in which the event `e` has occurred, from the start of the trace
up to and including the step considered. `COUNT(premuto) > 0` holds from the step of the first press onwards.

`COUNT(e SINCE f)` counts only the steps with `e` that follow the last step in which the event `f` occurred.
`COUNT(premuto SINCE avviso) = 0` holds in the steps in which nobody has pressed since the last warning.

`COUNT(e) IN LAST d` counts only the steps in which `e` occurred in the interval of duration `d` that ends with
the step considered. The step considered is included; the step exactly `d` away is not. In the CSC
`Comando` of chapter 13 the button provides the command `accendi`. Its guarantee `c1` establishes that at least
0.2 seconds pass between two commands. Written as a formula, the guarantee establishes that in every interval of
0.2 seconds no more than one command is issued:

```
  GUARANTEE c1a DETAILS c1: ALWAYS COUNT(accendi) IN LAST 0.2 s <= 1
```

In formulas decimal numbers are written with a point. Two commands exactly 0.2 seconds apart
satisfy the guarantee: when the second arrives, the first is already outside the interval.

The duration of `IN LAST` consists only of the first value that follows the keyword: a number with a unit, a name,
a call or an expression in parentheses. No operator of the table in chapter 21 extends it. The formula `c1a`
therefore reads `(COUNT(accendi) IN LAST 0.2 s) <= 1`. A calculated duration is written in parentheses:
`COUNT(e) IN LAST (2 * d)`.

In the report the line `c1a` is formal:

```
1. ERRORS: 0

2. DEGREE OF THE CONTRACTUAL LINES
…
  line 11: GUARANTEE c1a formal
```

### The filter on events: WITH

An event with parameters can be filtered on the value of its parameters: `e WITH c` occurs in the steps in which `e` occurs
and its parameters satisfy the condition `c`. The same applies to the phases of a request, with the parameters
of the request. Guarantee `g4` states that a cleaning request longer than two hours is rejected; the requested
duration is the parameter `durata` of the request `Pulizie`:

```
  GUARANTEE g4b DETAILS g4: WHENEVER (requested(Pulizie) WITH durata > 7200 s) THEN rejected(Pulizie) WITHIN 1 s
```

Two hours are written `7200 s`, because the only units are `s` and `ms`. The condition of `WITH` extends to
the end of the expression: for this reason the filtered event is written in parentheses when something else follows it, as
in `TIME SINCE (premuto WITH dove = primo) > 5 s`.

### The previous value: PREV

The **previous value** `PREV(x)` is the value of the state `x` in the previous step. In the first step it is the
initial value declared with `INITIAL`.

`PREV` is needed because in a step a state has the value it takes after the events of the step (chapter 21). Guarantee
`g7` states that during cleaning a press does not change the mode. The condition “during cleaning”
concerns the mode **before** the press:

```
  GUARANTEE g7a DETAILS g7: WHENEVER premuto AND PREV(modo) = in_pulizia THEN modo = in_pulizia AT ONCE
```

Whenever `premuto` occurs and in the previous step the mode was `in_pulizia`, in the same step the mode
is still `in_pulizia`.

`PREV` also identifies the step in which a state changes value: `PREV(modo) = accesa AND modo = spenta`
holds in the step in which the light switches off.

### The switch-off and the warning as formulas

The detail `g2a` becomes:

```
  GUARANTEE g2a DETAILS g2 STATUS HYPOTHESIS: ALWAYS ((PREV(modo) = accesa AND modo = spenta) IMPLIES (COUNT(premuto) > 0 AND TIME SINCE premuto >= 85 s AND TIME SINCE premuto <= 95 s))
```

It reads: in every step in which the light passes from on to off, there has been at least one press and since the last one
between 85 and 95 seconds have elapsed. The 5-second tolerance is expressed by the two limits.

Three observations on the formula:

- **reset of the time**: `TIME SINCE premuto` measures the time since the **last** press, so the
  formula also expresses the content of `g2b`, namely that a new press restarts the time from the beginning.
  `g2b` remains in the CSC, approved, and does not change. Its approved text keeps the word “count”, which
  refers to the measured time and not to `COUNT`;
- **cleaning**: the switch-off at the end of cleaning is a passage from `in_pulizia` to `spenta`, not from
  `accesa` to `spenta`, and the formula does not concern it;
- **approval status**: `g2a` had its own `STATUS RATIFIED BY D-12`; since the text changes, the
  guarantee returns to pending approval, with `STATUS HYPOTHESIS` (chapter 10).

In scenario `s2` the light switches off at instant 30: in step `@30 s` the formula requires at least 85 seconds
since the last press, and 30 have elapsed. The scenario violates `g2a`, and is therefore rejected, as its
line `EXPECT REJECTED` declares.

Guarantee `g3`, “shortly before switching off, the light gives a warning”, receives a formal detail:

```
  GUARANTEE g3a DETAILS g3: ALWAYS ((PREV(modo) = accesa AND modo = spenta) IMPLIES (COUNT(avviso) > 0 AND COUNT(premuto SINCE avviso) = 0))
```

In every step in which the light switches off there has been at least one warning, and nobody has pressed after the last warning.
A press after the warning, therefore, prevents the announced switch-off. How long before the switch-off the warning
must arrive is not expressed by the detail and remains in the text in words of `g3`.

### Repeating scenarios: REPEAT

A scenario can end with steps that repeat. The `REPEAT` line stands among the steps and applies until the end of the
scenario: the steps that follow it repeat at intervals of duration `d`.

| Form | Meaning |
|---|---|
| `REPEAT m..n EVERY d` | the steps that follow repeat from `m` to `n` times |
| `REPEAT FOREVER EVERY d` | the steps that follow repeat without end |

Each repetition begins `d` after the previous one, and the times `@t` of the repeated steps are measured from the
start of the repetition. In the following scenario someone climbing slowly presses the button every 60 seconds,
from one to five times, and the light is on after every press:

```
  SCENARIO s5 EXPECT ADMITTED
    REPEAT 1..5 EVERY 60 s
    @0 s     premuto    modo = accesa
```

The scenario is equivalent to five scenarios, with one, two, three, four and five presses 60 seconds apart. `bcdd`
checks the form of the repetition and reports error **E30** in the following cases:

- the scenario has two `REPEAT` lines;
- the limits are not valid: the maximum must be at least 1 and not smaller than the minimum;
- after `REPEAT` there is no step;
- the times of the steps of the scenario are written without units;
- a repeated step has a time equal to or greater than the period.

The order of the times (error E12, chapter 9) is checked among the repeated steps, with the times measured from the
start of the repetition.

### The CSC and the report

The header comment becomes:

```
-- VERSION 0.3: g1, g2 and g2a written as formulas; g3a, g4a, g4b, g7a and g8 added. Pending approval.
```

The report shows eight formal lines:

```
$ bcdd check UsoLuce.csc
bcdd check UsoLuce.csc
lines: 57 (recognised 47, comments 5, blank 5, unrecognised 0)
blocks: 1
  line 4: CSC UsoLuce VERSION 0.3, STATUS HYPOTHESIS

1. ERRORS: 0

2. DEGREE OF THE CONTRACTUAL LINES
  verbal: 7
  formal: 8
  declared extension: 0
  unrecognised: 0
  line 16: GUARANTEE g1 formal
  line 18: GUARANTEE g2 formal
  line 20: GUARANTEE g2a formal
  line 21: GUARANTEE g2b verbal
  line 23: GUARANTEE g3 verbal
  line 25: GUARANTEE g3a formal
  line 26: GUARANTEE g4 verbal
  line 28: GUARANTEE g4a formal
  line 29: GUARANTEE g4b formal
  line 30: GUARANTEE g5 verbal
  line 32: GUARANTEE g6 verbal
  line 34: GUARANTEE g7 verbal
  line 36: GUARANTEE g7a formal
  line 37: GUARANTEE g8 formal
  line 38: ASSUME a1 verbal
…
14. TO BE JUDGED: 5
  line 21: GUARANTEE g2b DETAILS g2: consistency between the line and the line that details it, one of the two in words
  line 25: GUARANTEE g3a DETAILS g3: consistency between the line and the line that details it, one of the two in words
  line 28: GUARANTEE g4a DETAILS g4: consistency between the line and the line that details it, one of the two in words
  line 29: GUARANTEE g4b DETAILS g4: consistency between the line and the line that details it, one of the two in words
  line 36: GUARANTEE g7a DETAILS g7: consistency between the line and the line that details it, one of the two in words

15. CHECKS NOT EXECUTED: 4
  scenarios: lines 41, 46, 49, 51, 54
  coverage of the triggers: lines 16, 18, 20, 25, 28, 29, 36, 37
  consistency of assumptions and guarantees: lines 16, 18, 20, 25, 28, 29, 36, 37
  consistency of the details: line 20

outcome: no errors
```

Section 15 now lists five scenarios, including `s5`, and eight formal lines for trigger coverage and for
consistency. The entry `consistency of the details` concerns `g2a`, which is a formal detail of a formula, `g2`. The consistency
between the two lines is a check that `bcdd` does not execute. The formal details of a guarantee in words, such as `g3a`,
`g4a`, `g4b` and `g7a`, are instead in section 14, because consistency with a line in words is judged.

### Summary

- `WITHIN d` adds a **time limit** to `EVENTUALLY` and to `WHENEVER`.
- `TIME SINCE e` is the **elapsed time** since the last `e`; it is 0 in the step of `e` and infinite before the
  first `e`, so a comparison such as `>= d` is written together with `COUNT(e) > 0`.
- `COUNT(e)` is the **count** of the steps with `e`; `COUNT(e SINCE f)` counts only those after the last `f`;
  `COUNT(e) IN LAST d` counts only those of the interval of duration `d` that ends with the step considered,
  included, without the step exactly `d` away.
- `e WITH c` filters an event, or a phase of a request, on the value of its parameters.
- `PREV(x)` is the **previous value** of a state; in the first step it is the initial value.
- `REPEAT m..n EVERY d` and `REPEAT FOREVER EVERY d` repeat the steps that follow the `REPEAT` line, up to the
  end of the scenario; every repeated step has a time smaller than the period.

### Special cases

**The value after the press.** If in `g7a` `modo = in_pulizia` is written in place of
`PREV(modo) = in_pulizia`, the formula becomes: whenever there is a press and, after the press, the mode is
`in_pulizia`, the mode is `in_pulizia`. The formula is always satisfied and expresses no guarantee. Even a press
that takes the mode from `in_pulizia` to `accesa`, forbidden by `g7`, satisfies the formula. The form, names and
types are correct, and `bcdd`, which does not evaluate formulas,
does not detect the defect:

```
1. ERRORS: 0

2. DEGREE OF THE CONTRACTUAL LINES
…
  line 36: GUARANTEE g7a formal
…
```

**Light that never switches off.** `g2a` is evaluated in the step of the switch-off. If in a trace the light
stays on until the end, `g2a` has no step in which to apply. That the switch-off does not happen is a
case covered by `g2`: “in a later step the light is off”.

**Previous value in the first step.** In the first step `PREV(modo)` is `spenta`, the value declared with
`INITIAL`. A press in the first step therefore has `PREV(modo) = spenta`, and `g7a` does not concern it.

**Minutes and durations without a unit.** The units of durations are only `s` and `ms`, as in scenarios and in
named constants: 90 seconds are written `90 s`, and not `1.5 min`. A number without a unit after `WITHIN` is not a
duration, and `bcdd` reports error **E25**, inconsistent type:

```
1. ERRORS: 1
  line 28: [E25] inconsistent type: Duration needed, Integer found
```

**A repeated step as long as the period.** In scenario `s5`, a second repeated step `@60 s` would fall
at the same instant as the next repetition:

```
1. ERRORS: 1
  line 57: [E30] the step @60 s is not shorter than the period of REPEAT: every repeated step has a time smaller than EVERY 60 s
```

---

## Chapter 23 — Shorthands

The guarantee “the light is never on if nobody has pressed” is written with the keywords of chapters 21 and 22,
but in the expanded form. The language provides short forms for frequent cases. This chapter describes these
forms, called shorthands, and the rules on their meaning. It then describes how a name is given to an
expression, to a function and to a derived event, and introduces named types, records and indexed states.

### The shorthand

A **shorthand** is a **short form** that expands into an equivalent formula, written with the keywords
of chapters 21 and 22 and called the **expanded form**. The meaning of a shorthand is only that of its
expanded form: the English words that compose it serve as a reminder and do not define it.

Three rules follow:

1. a line written with a shorthand has formal degree, like its expanded form;
2. writing a shorthand or its expanded form does not change the contract;
3. a program that evaluates formulas evaluates a shorthand through its expanded form.

`bcdd` recognises each shorthand as a form of its own, checks its names and types, and does not produce the
expanded form.

### The guarantee in short form and in expanded form

The expanded form of the guarantee is:

```
  GUARANTEE g9: ALWAYS (modo = accesa IMPLIES COUNT(premuto) > 0)
```

In every step in which the light is on there has been at least one press. The short form uses `PRECEDES`:

```
  GUARANTEE g9: premuto PRECEDES modo = accesa
```

`e PRECEDES q` expands into `ALWAYS (q IMPLIES COUNT(e) > 0)`: the expanded form of
`premuto PRECEDES modo = accesa` is the formula written above. The first element, `e`, is an event, because the
expanded form counts its steps.

The same guarantee can also be written with two other shorthands:

```
  GUARANTEE g9: NEVER (modo = accesa AND COUNT(premuto) = 0)
  GUARANTEE g9: BEFORE premuto: NEVER modo = accesa
```

`NEVER p` expands into `ALWAYS NOT p`. `BEFORE e: P` expands into `WHILE COUNT(e) = 0: P`, that is “in the steps
that precede the first `e`”. The three short forms therefore have three expanded forms, equivalent to one another:

| Short form | Expanded form |
|---|---|
| `premuto PRECEDES modo = accesa` | `ALWAYS (modo = accesa IMPLIES COUNT(premuto) > 0)` |
| `NEVER (modo = accesa AND COUNT(premuto) = 0)` | `ALWAYS NOT (modo = accesa AND COUNT(premuto) = 0)` |
| `BEFORE premuto: NEVER modo = accesa` | `WHILE COUNT(premuto) = 0: ALWAYS NOT modo = accesa` |

In the staircase light CSC `g9` is written in short form, with `PRECEDES`, at line 39, after `g8`.

### The response to a request, in short form

The detail `g4a` of chapter 22 also has a short form:

```
  GUARANTEE g4a DETAILS g4: RESOLVES Pulizie WITHIN 1 s
```

`RESOLVES X WITHIN d` expands into `WHENEVER requested(X) THEN accepted(X) OR rejected(X) WITHIN d`, which is the
line written in chapter 22. The two lines are the same guarantee.

### The shorthands of the language

The table shows the shorthands used in the guarantees of a CSC, with the expanded form of each.

| Short form | Expanded form | Reads |
|---|---|---|
| `NEVER p` | `ALWAYS NOT p` | never `p` |
| `ONCE e` | `COUNT(e) > 0` | `e` has occurred at least once |
| `CHANGED(x)` | `x <> PREV(x)` | the state `x` has changed value in this step |
| `e PRECEDES q` | `ALWAYS (q IMPLIES COUNT(e) > 0)` | `q` does not hold before the first `e` |
| `BEFORE e: P` | `WHILE COUNT(e) = 0: P` | `P` holds before the first `e` |
| `AFTER e: P` | `WHILE COUNT(e) > 0: P` | `P` holds from the first `e` onwards, the step of `e` included |
| `ACCEPTS X ONLY WHILE c` | `ALWAYS (accepted(X) IMPLIES c)` | the request `X` is accepted only if `c` holds |
| `X ENSURES p` | `WHENEVER completed(X) THEN p AT ONCE` | when `X` succeeds, `p` holds |
| `RESOLVES X WITHIN d` | `WHENEVER requested(X) THEN accepted(X) OR rejected(X) WITHIN d` | `X` has a response within `d` |
| `X REQUIRES c` | `ALWAYS (requested(X) IMPLIES c)` | `X` may be requested only if `c` holds; written only in an assumption |
| `TRANSITION x: A -> B ON e WHEN c, …` | `ALWAYS (CHANGED(x) IMPLIES ((PREV(x) = A AND x = B AND e AND c) OR …))` | `x` changes value only in the listed ways |

`ONCE` and `CHANGED` are written inside a condition: `ALWAYS (CHANGED(modo) IMPLIES ONCE premuto)`.
`X REQUIRES c` describes an obligation of the consumer and is written only in an assumption (`ASSUME` line).

### A closed set of transitions: TRANSITION

`TRANSITION` lists all the ways in which a state changes value. Each entry `A -> B ON e` indicates that the state passes
from the value `A` to the value `B` in a step in which the event `e` occurs; with `WHEN c` the condition `c` must also
hold. The list is **closed**: a change that does not appear in it violates the guarantee. The type of the state is a list of
values; `A` and `B` are values of that list.

The mode of the light passes from `accesa` to `spenta` without an event of the boundary: the light switches off when the time runs out.
To name that step as an event a **derived event** is written, with `DEFINE EVENT`:

```
  DEFINE     EVENT scadenza := TIME SINCE premuto >= 85 s
```

`scadenza` occurs in the steps in which at least 85 seconds have elapsed since the last press. A derived event is
used in a formula in place of an event; it is not written in the steps of scenarios, which contain only events
declared with `EVENT`. Guarantee `g10` lists the changes of the mode:

```
  GUARANTEE g10: TRANSITION modo: spenta -> accesa ON premuto,
                                  accesa -> spenta ON scadenza,
                                  spenta -> in_pulizia ON accepted(Pulizie),
                                  accesa -> in_pulizia ON accepted(Pulizie),
                                  in_pulizia -> spenta ON completed(Pulizie),
                                  in_pulizia -> spenta ON failed(Pulizie)
```

The lines, except the last, end with a comma and therefore continue on the next line (chapter 21): the guarantee is a single
declaration. A press during cleaning does not appear in the list, so it does not change the mode, as
`g7` guarantees.

The header comment becomes:

```
-- VERSION 0.3: g1, g2 and g2a written as formulas; g3a, g4a, g4b, g7a, g8, g9 and g10 added. Pending approval.
```

In the report the two new lines are formal:

```
$ bcdd check UsoLuce.csc
bcdd check UsoLuce.csc
lines: 65 (recognised 55, comments 5, blank 5, unrecognised 0)
blocks: 1
  line 4: CSC UsoLuce VERSION 0.3, STATUS HYPOTHESIS

1. ERRORS: 0

2. DEGREE OF THE CONTRACTUAL LINES
…
  line 38: GUARANTEE g8 formal
  line 39: GUARANTEE g9 formal
  line 40: GUARANTEE g10 formal
…
```

### Giving a name to an expression

The value of a named constant (chapter 8) can be an expression:
`DEFINE DURATA_AVVISO := DURATA_LUCE - 5 s` gives a name to a calculated duration. A `DEFINE` can also have
**parameters**, each with its type: it is then a **function**, which is used with the arguments written by name,
like the arguments of events in scenarios. With the following three new lines

```
  DEFINE     DURATA_LUCE := 90 s
  DEFINE     TOLLERANZA := 5 s
  DEFINE     vicino(t: Duration, valore: Duration) := ABS(t - valore) <= TOLLERANZA
```

the detail `g2a` is written:

```
  GUARANTEE g2a DETAILS g2 STATUS HYPOTHESIS: ALWAYS ((PREV(modo) = accesa AND modo = spenta) IMPLIES (ONCE premuto AND vicino(t: TIME SINCE premuto, valore: DURATA_LUCE)))
```

`vicino(t: …, valore: …)` holds when the two durations differ by no more than `TOLLERANZA`. The line is formal:

```
1. ERRORS: 0

2. DEGREE OF THE CONTRACTUAL LINES
…
  line 24: GUARANTEE g2a formal
…
```

`bcdd` checks that every argument is a parameter of the function and that none is missing, and checks its type.
For a call without `valore` `bcdd` reports error E24:

```
1. ERRORS: 1
  line 24: [E24] the argument valore is missing in the call to vicino
```

`DEFINE`s must not refer to one another circularly: for `DEFINE A := B + 1` with `DEFINE B := A - 1` `bcdd`
reports error E28. A `DEFINE` that details another `DEFINE` (`DEFINE nome DETAILS padre := …`) is pending approval like every detail, and is approved with
`bcdd ratify` like a contractual line.

### Named types, records and indexed states

In a three-storey building the staircase light has a button and a lamp per floor. The CSC `LucePiani` uses three
new forms:

```
-- The staircase light of a three-storey building: one button and one lamp per floor.

CSC LucePiani VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "The person on the stairs presses the button on their own floor and has light on that floor"

  TYPE       Piano := {terra, primo, secondo}
  TYPE       Percentuale := Integer [0 .. 100]
  TYPE       Tocco := Record {piano: Piano, lungo: Boolean}

  EVENT IN   premuto(dove: Piano)
  EVENT IN   toccato(t: Tocco)
  STATE      accesa[Piano] : Boolean INITIAL false
  STATE      ultimo : Piano INITIAL terra FOLLOWS premuto.dove
  STATE      intensita : Percentuale INITIAL 0

  GUARANTEE p1: FOR ALL p IN Piano: WHENEVER (premuto WITH dove = p) THEN accesa[p] AT ONCE
  GUARANTEE p2: ALWAYS (toccato IMPLIES accesa[LAST(toccato).t.piano])
  GUARANTEE p3: ALWAYS (intensita > 0 IMPLIES accesa[ultimo])

  SCENARIO q1 EXPECT ADMITTED
    @0 s     premuto(dove: primo)    accesa[primo] = true
    @1 s     toccato(t: _)
END
```

- **a named type**: `TYPE Percentuale := Integer [0 .. 100]` gives a name to a type; the name stands for the type
  it names, throughout the block. A limit of the interval can be omitted: `Integer [0 ..]` is a non-negative
  integer without maximum;
- **a record**: `TYPE Tocco := Record {piano: Piano, lungo: Boolean}` is a type with fields; `x.campo` names one of its
  fields, and `LAST(e).p` the value of the parameter `p` in the last step in which `e` occurred. In a scenario the value
  of a parameter of record type is written `_`;
- **an indexed state**: `STATE accesa[Piano] : Boolean INITIAL false` is equivalent to one state per floor:
  `accesa[terra]`, `accesa[primo]`, `accesa[secondo]`. The type of the index is **finite**: a list of values,
  `Boolean`, or a named type defined as one of these or as an `Integer` with both limits.

`FOR ALL p IN Piano: P` holds for every value of the type, with `p` taking each value in turn: guarantee `p1` is
the same guarantee written three times, once per floor. `STATE ultimo : Piano INITIAL terra FOLLOWS premuto.dove`
declares a state that follows the parameter `dove` of the last `premuto`. Its expanded form is the pair of formulas
`ALWAYS (premuto IMPLIES ultimo = LAST(premuto).dove)` and `ALWAYS (CHANGED(ultimo) IMPLIES premuto)`. `FOR ALL`, indexes and `FOLLOWS` are
shorthands.

The report has no errors:

```
1. ERRORS: 0

2. DEGREE OF THE CONTRACTUAL LINES
  verbal: 0
  formal: 3
  declared extension: 0
  unrecognised: 0
  line 17: GUARANTEE p1 formal
  line 18: GUARANTEE p2 formal
  line 19: GUARANTEE p3 formal
```

`bcdd` checks the fields, the indexes and the literal values. Four defects are introduced: a guarantee names a
field `stanza` that the record does not have, `ALWAYS accesa` is written without an index, a step presses the
button at floor `quarto`, and the same step brings the intensity to 120. The report shows four errors:

```
1. ERRORS: 4
  line 20: [E24] name not declared as a field of Tocco: stanza
  line 21: [E29] accesa has an index: write accesa[value of Piano]
  line 26: [E03] name not declared as a value of TYPE: quarto
  line 26: [E25] value not of type Percentuale: 120
```

The value 120 is outside the interval of the type `Percentuale`: `bcdd` compares the literal
values of the `INITIAL` clause, of the `GIVEN` clause, of assignments and of the arguments of steps with the
declared type (error E25).

### Summary

- A **shorthand** is a **short form** that expands into an equivalent formula, the **expanded form**;
  its meaning is only that of the expanded form.
- A line written with a shorthand has formal degree.
- Several shorthands can express the same guarantee: `PRECEDES`, `NEVER` and `BEFORE` in the example of
  `g9`.
- `RESOLVES` expresses in short form the response to a request within a time; `TRANSITION` lists the closed set
  of transitions of a state.
- `DEFINE` gives a name to an expression, to a function with parameters, or, with `DEFINE EVENT`, to a derived
  event.
- `TYPE Name := Type` gives a name to a type; `Record {…}` is a type with fields; `STATE x[T]` is a state indexed
  on a finite type; `FOR ALL` and `FOLLOWS` are shorthands.

### Special cases

**Short forms with an incomplete expanded form.** The language also provides the forms `AFTER e UNTIL f: P`,
`BETWEEN e AND f: P` and `p FOR AT LEAST d`. The first two delimit an interval between two events; the third requires
that a condition hold for a minimum duration. The expanded form of `AFTER e UNTIL f: P` is a `WHILE` scope on a
`DEFINE`. The `DEFINE` holds from an `e` to the first following `f` and is computed with `PREV` on the steps of the
trace that have already elapsed. For `BETWEEN` and `FOR AT LEAST` the expanded form is not yet fully defined. `bcdd` recognises the three
forms and checks their names and types; the manual does not
use them.

**`REQUIRES` in a guarantee.** `X REQUIRES c` describes what the consumer must satisfy before making the request.
If the form is written in a guarantee (`GUARANTEE` line), `bcdd` reports error **E27**, and the message indicates
the form to write:

```
1. ERRORS: 1
  line 39: [E27] REQUIRES is used only in an ASSUME: in a GUARANTEE write ALWAYS (requested(X) IMPLIES c)
```

**Variants.** `VARIANT` (chapter 20), too, reduces to other forms: an entity with variants is equivalent to the
set of its compositions, each written as an entity without variants. `VARIANT` does not expand into a formula, so it is not a shorthand in the sense of this
chapter.

**The short form in the text in words.** In `VERBAL "the light never switches on BEFORE a press"` the
words in quotation marks are text, not a shorthand: the line remains verbal.

```
2. DEGREE OF THE CONTRACTUAL LINES
…
  line 39: GUARANTEE g9 verbal
…
```

---

## Chapter 24 — The meaning of “verified”

With the formulas of chapters 21-23 the staircase light CSC contains guarantees of two degrees: verbal and formal. This
chapter describes the two moments of verification, the outcomes that each degree can have, the rules by which
those outcomes are reported and the part of verification that `bcdd` executes.

### The two moments of verification

The verification of a CSC takes place in two moments:

1. **text verification** examines the CSC before the system is built;
2. **recording verification** examines the recordings of a built system. A
   **recording** is a trace, that is a sequence of steps, observed at the boundaries of a built
   system.

The two verifications answer different questions. The first establishes whether the description is correctly formulated and whether it is
possible to satisfy it; the second, whether a built system has satisfied it in the situations observed.

### Text verification

Text verification comprises the following checks:

| Check | What is checked |
|---|---|
| form | names and types are consistent, every guarantee has a name, every detail makes an existing line precise |
| consistency | there exists at least one trace that satisfies all the assumptions and all the guarantees together |
| scenarios | every scenario is admitted or rejected by the guarantees, as its `EXPECT` line declares |
| coverage | for every guarantee with a trigger there exists an admitted scenario in which the trigger holds |
| every used boundary is offered | in an entity with parts, every boundary used by a part is provided by another part or is an external boundary |
| entity guarantees | the guarantees of the entity are compatible with those of the parts and of the boundaries |
| details | every detail is compatible with the line it makes precise |

The trigger of a guarantee written with `WHENEVER` is its first condition (chapter 21). For the other forms:

- in `ALWAYS (p IMPLIES q)` the trigger is `p`: for `g2a` it is the passage of the light from on to off;
- in `WHILE c: P` the trigger is `c`, and if `P` in turn has a trigger both must hold in the same step;
- `ALWAYS p` without `IMPLIES` and `EVENTUALLY p` have no trigger;
- a shorthand has the trigger of its expanded form (chapter 23): `premuto PRECEDES modo = accesa`
  has the trigger `modo = accesa`.

Coverage thus reports the guarantees that are satisfied only because their trigger does not arise in any
scenario.

On formal lines these checks can be executed by a program. In the staircase light CSC a program
could establish that scenario `s2` violates `g2a` and is therefore rejected, as its `EXPECT` line declares: this is a check
that in chapter 9 was left to the writer. On verbal lines consistency, scenarios and details remain entrusted
to the judgement of a person.

Consistency does not guarantee that the system can be built: it indicates only that there exists a trace that
satisfies the CSC. The specification does not provide a check of **realisability**, that is of the existence of a
system that satisfies the guarantees whatever the behaviour of the other side.

### The checks executed by bcdd

`bcdd` executes two checks of the table: **form**, including the names and types of formulas, and the rule
**every used boundary is offered** (chapters 13, 19 and 20). The other checks are not executed, and the report shows this.
Section 15 lists the lines to which the checks of scenarios, coverage, consistency and formal
details would apply. Section 14 lists the details whose consistency is judged because one of the two lines is in words.
Entity guarantees remain entrusted to judgement (chapter 12). On version 0.3 of the light:

```
$ bcdd check --strict UsoLuce.csc
bcdd check --strict UsoLuce.csc
lines: 65 (recognised 55, comments 5, blank 5, unrecognised 0)
blocks: 1
  line 4: CSC UsoLuce VERSION 0.3, STATUS HYPOTHESIS

1. ERRORS: 0
…
14. TO BE JUDGED: 5
  line 22: GUARANTEE g2b DETAILS g2: consistency between the line and the line that details it, one of the two in words
  line 26: GUARANTEE g3a DETAILS g3: consistency between the line and the line that details it, one of the two in words
  line 29: GUARANTEE g4a DETAILS g4: consistency between the line and the line that details it, one of the two in words
  line 30: GUARANTEE g4b DETAILS g4: consistency between the line and the line that details it, one of the two in words
  line 37: GUARANTEE g7a DETAILS g7: consistency between the line and the line that details it, one of the two in words

15. CHECKS NOT EXECUTED: 4
  scenarios: lines 49, 54, 57, 59, 62
  coverage of the triggers: lines 17, 19, 21, 26, 29, 30, 37, 38, 39, 40
  consistency of assumptions and guarantees: lines 17, 19, 21, 26, 29, 30, 37, 38, 39, 40
  consistency of the details: line 21

outcome: no errors
```

The outcome `no errors` concerns form: ten lines are formal, and for each of them section 15 reports what has not
been checked. An outcome is never worth more than what has actually been checked.

| Check | In `bcdd` |
|---|---|
| form | executed: errors in section 1 |
| every used boundary is offered | executed: errors E14, E16, E17 |
| scenarios | not executed: entry `scenarios` of section 15 |
| coverage | not executed: entry `coverage of the triggers` of section 15 |
| consistency | not executed: entry `consistency of assumptions and guarantees` of section 15 |
| details | formal: entry `consistency of the details` of section 15; with a line in words: section 14 |
| entity guarantees | by judgement |

### The outcomes on recordings

On recordings every guarantee receives an outcome. The possible outcomes depend on the degree:

| Degree | Outcomes |
|---|---|
| formal | satisfied on the trace, violated (with the step), inconclusive, assumption not satisfied, not executed |
| verbal | conforming by judgement, non-conforming by judgement, not assessed; each with who judged and on what |

The formal outcomes have this meaning:

- **satisfied on the trace**: in the recorded trace the formula is never violated. In the specification
  the outcome is called `SODDISFATTA SULLA TRACCIA`;
- **violated**: in a step of the trace the formula does not hold; the outcome indicates the step;
- **inconclusive**: the trace ends before the outcome can be established. This happens, for example, when a
  consequence without a time limit does not hold in any step up to the end of the trace, or when the trace ends
  before the time limit has elapsed. The outcome lists the trigger steps left without a response. A
  consequence without a time limit that has not occurred by the end of the recording never makes the guarantee
  violated: the response might arrive after the end;
- **assumption not satisfied**: the other side has not satisfied an assumption on which the guarantee depends;
- **not executed**: the recording instrument (chapter 26) does not observe what the guarantee refers to.

The verbal outcomes record a judgement: who judged, on what, and with what conclusion. A
verbal guarantee that nobody has yet judged is **not assessed**.

No program described in this manual executes recording verification: the outcomes of this section
are those established by the specification.

### “Satisfied on the trace” applies to what has been observed

A recording of the light, written as a scenario, is the following:

```
    @0 s     premuto    modo = accesa
    @40 s    premuto    modo = accesa
    @125 s   avviso
    @130 s   modo = spenta
```

On this trace the formulas of the staircase light CSC have the following outcomes:

| Guarantee | Outcome | Reason |
|---|---|---|
| `g1` | satisfied on the trace | after each of the two presses the mode is `accesa` |
| `g2` | satisfied on the trace | after switching on, the light switches off, at instant 130 |
| `g2a` | satisfied on the trace | at the switch-off 90 seconds have elapsed since the last press |
| `g3a` | satisfied on the trace | before the switch-off there is a warning, and after the warning nobody has pressed |
| `g4a` | satisfied on the trace | in the trace there is no cleaning request |
| `g4b` | satisfied on the trace | in the trace there is no cleaning request |
| `g7a` | satisfied on the trace | in the trace there is no press during cleaning |
| `g8` | satisfied on the trace | with the light off no warning arrives |
| `g9` | satisfied on the trace | the light comes on only after a press |
| `g10` | satisfied on the trace | the mode changes twice: at instant 0 with a press, at instant 130 at 90 seconds from the last press |

In version 0.3 these lines are pending approval, and their outcome is reported as described in the special
case “A guarantee pending approval”.

`g4a`, `g4b` and `g7a` are satisfied on the trace because their trigger never holds: the trace provides no
information about how the light responds to a cleaning request or to a press during cleaning. “Satisfied on the
trace” applies only to the recorded trace and to the resolution with which it was recorded (chapter 26): it does not
imply anything about situations that have not been observed.

On a recording that ends at instant 60, with the light still on, `g2` is **inconclusive**: the
switch-off has not happened by the end of the recording, and nothing allows it to be established whether it would have
happened. The outcome indicates the switch-on step left without a response. On a recording with a single
press at instant 0 and the switch-off at instant 60, `g2a` is **violated** in step `@60 s`.

### The judgement of a person and the result of a program

The report of a recording verification shows the outcomes **by degree**, in separate sections: one for
formal guarantees, one for verbal ones and, for guarantees written with an extension, one for the degree
declared extension (chapter 27). Lines pending approval appear in a separate section, as
in section 4 of the report of `bcdd check`: their outcome is not an outcome of the contract.

An outcome given by judgement is never added to an outcome given by a program. Consider an approved
version of the staircase light CSC, in which the ten formulas are satisfied on the trace and a person with a
stopwatch judges the verbal guarantee `g3` conforming by judgement. The report shows ten formal guarantees
satisfied on the trace and one verbal guarantee conforming by judgement, in two distinct sections; it does not show
eleven satisfied guarantees. The two results have a different value: the first derives
from applying the formula to every step of the trace, the second from the observation and
assessment of a person.

### The assumption not satisfied

A guarantee holds as long as the other side satisfies the assumptions on which it depends (chapter 3). If a
recording shows that a formal assumption has not been satisfied, the verification reports it with the outcome
**assumption not satisfied**, and not as a violated guarantee: the guarantee holds only if the assumption is
satisfied.

The assumption `a1` of the light, “whoever presses the button holds it down for at least a tenth of a second”, is
verbal: no program can establish whether it has been satisfied. A person establishes it, and their judgement
appears in the verbal section, distinct from the outcome of `g1`. The outcome of `g1` remains the one calculated by the
program, because a judgement never changes a formal outcome. If `a1` is judged not satisfied, the
section of formal guarantees contains a note that lists the verbal assumptions judged not satisfied and who
judged them: in this way the note reports that an outcome such as “violated” may depend on whoever pressed the
button and not on the light. Since a guarantee does not declare on which assumptions it depends, the note applies to
all the formal guarantees of the CSC.

The specification does not yet establish what remains guaranteed after an assumption has not been satisfied,
nor whether this concerns all guarantees or only those that depend on that assumption.

### Summary

- Verification takes place in two moments: **on the text**, before construction, and **on the recordings** of a
  built system.
- On the text, form, consistency, scenarios, coverage, the rule “every used boundary is offered”, entity
  guarantees and details are checked; consistency does not guarantee realisability.
- `bcdd` executes the form check and the rule “every used boundary is offered”; it lists in section 15 the checks on
  formulas that it does not execute and in section 14 what remains to be judged.
- A formal guarantee can be **satisfied on the trace**, **violated**, **inconclusive**, with
  **assumption not satisfied** or **not executed**; a verbal guarantee **conforming by judgement**, **non-conforming
  by judgement** or **not assessed**.
- “Satisfied on the trace” applies only to the observed trace.
- Outcomes are reported by degree, and a judgement is never added to the result of a program.

### Special cases

**A formula with an undecided number.** With the constant `ANTICIPO_AVVISO := UNDECIDED` and the detail
`g3a DETAILS g3: ALWAYS ((PREV(modo) = accesa AND modo = spenta) IMPLIES (COUNT(avviso) > 0 AND COUNT(premuto SINCE avviso) = 0 AND TIME SINCE avviso <= ANTICIPO_AVVISO))`
the guarantee cannot be verified, either on the text or on the recordings, until the number is decided. `bcdd`
lists the undecided number, but does not indicate which formulas use it; the line remains formal, and the undecided value
is used without a type check:

```
1. ERRORS: 0

2. DEGREE OF THE CONTRACTUAL LINES
…
  line 27: GUARANTEE g3a formal
…

3. UNDECIDED: 1
  line 14: ANTICIPO_AVVISO
```

**A guarantee that the recording instrument does not observe.** If the recording instrument detects the press and the
state of the light but not the warning, `g8` is **not executed**: the outcome indicates neither satisfaction nor violation.
Chapter 26 describes how to declare what each instrument observes.

**A scenario declared rejected but admitted.** In chapter 9 a scenario declared rejected, but admitted
by the guarantees, could not be detected, because the guarantees were in words. With `g2a` written as a formula, in a
scenario like `s2` but with the switch-off at `@90 s` the scenario check can establish that the scenario is
admitted and that the declaration `EXPECT REJECTED` is wrong. `bcdd check` does not execute this check: the
scenario appears in the entry `scenarios` of section 15.

**A guarantee pending approval.** The outcome of a guarantee with `STATUS HYPOTHESIS` is reported in the section of
lines pending approval: a violation indicates that the guarantee, as written, does not describe the recorded system,
and not that the system fails to satisfy a contract.

---

## Chapter 25 — The concrete form of boundaries

The CSCs of the previous chapters indicate what happens at a boundary with names chosen by the writer: `premuto`,
`accendi`, `modo = accesa`, `avviso`. This chapter introduces concrete forms, that is the way in which each of
these elements appears at the boundary, and the criterion by which what to write is established, “who sees it?”.
Finally it introduces the `BINDING` block, which contains the concrete forms.

### Concrete forms

A **concrete form** is what someone at the boundary observes or uses of an element of a CSC: a terminal, a
text on the screen, a colour, a file format, a command-line option, a message on a
network. The CSC establishes that an element exists and what the provider guarantees; the concrete forms
establish how that element appears at the boundary. In chapter 4, for example, the line `EVENT OUT avviso` declares that
the warning exists, whereas its appearance, a brief flash or an acoustic signal, is a concrete form. In the
same way, in a program with a window the CSC can declare a state `allarme : Boolean`, and the concrete
forms establish that the alarm appears as the word “ALARM” in red.

The concrete forms of a boundary are written in a `BINDING … END` block, distinct from the `CSC` block of the
boundary. The concrete forms concern:

- what a person observes and uses: positions, texts, colours, gestures, the format of numbers;
- the wire between two systems: the transmission medium, the structure of messages, the encoding of numbers;
- what a program reads or writes: a settings file, the command line, an audio system;
- a third-party system, when an effect is observed only in that system.

Concrete forms add no guarantees: they indicate how the elements the guarantees refer to appear at the
boundary.

### The criterion “who sees it?”

To decide where an element is written, the specification asks a single question: who sees it, and how.

| Situation | Where it is written |
|---|---|
| nobody at the boundary sees it | it is not written: it is implementation |
| someone sees it, and its form can change without changing the meaning of the guarantees | in the concrete forms |
| someone sees it, and changing it changes the meaning of the guarantees | in the CSC |
| the number that makes a guarantee checkable is derived only from an existing implementation | in the CSC, as an undecided number (`UNDECIDED`), with a question to the approver |
| an existing implementation produces a visible effect, but nothing indicates that it is intended | neither in the CSC nor in the concrete forms: the question is put to the approver |

A concrete form is **binding** when someone who is not part of the same implementation observes or uses it: a
person, another program, a third-party system.

### The concrete forms of the light

The table applies the criterion to the elements of the CSC `UsoLuce` (chapters 21-23) and of the CSC `Comando`, the
boundary between the button and the lamp (chapter 13).

| CSC | Element | Who sees it | Concrete form |
|---|---|---|---|
| `UsoLuce` | `premuto` | the person on the stairs | press of the key of the wall button |
| `UsoLuce` | `modo = spenta` | the person on the stairs | lamp off |
| `UsoLuce` | `modo = accesa`, `modo = in_pulizia` | the person on the stairs | lamp on |
| `UsoLuce` | `avviso` | the person on the stairs | the lamp switches off for 0.3 s and switches on again |
| `Comando` | `accendi` | whoever implements the lamp | contact closed between terminal 3 and the common terminal for at least 50 ms |

`accesa` and `in_pulizia` have the same concrete form: the person on the stairs does not tell them apart by sight, and
observes the difference only in the behaviour, because during cleaning a press does not change the mode
(chapter 6).

**The warning.** With a flash or with an acoustic signal the guarantees keep their meaning: for
this reason the appearance of the warning is a concrete form. The advance with which the warning precedes the switch-off, by contrast,
changes what the person on the stairs can expect, and is written in the CSC: it is the named constant
`ANTICIPO_AVVISO` of chapter 8.

**Terminal 3.** `Comando` is a boundary internal to the entity `LuceScale` (chapter 13). If the button and the
lamp are implemented by two different manufacturers, whoever implements the lamp must
know which contact represents an `accendi`: terminal 3 and the minimum duration of 50 ms are binding
concrete forms. If instead the button and the lamp are implemented together, nobody outside that
implementation uses the terminal, which remains an internal choice. The minimum duration establishes which contact counts
as `accendi`; modifying it changes neither guarantee `c1` of `Comando` nor the assumption `a1` of `UsoLuce`.

**The relay.** The relay that closes the lamp circuit is not visible to the person on the stairs (chapter 1): it is
implementation and is not written. The sentence “`accesa` means relay closed” would exclude a lamp that keeps
the same guarantees without a relay.

**A number taken from an implementation.** If the advance of the warning is derived only from an already
installed module, which emits the warning 5 seconds before the switch-off, the number has not been decided by anyone: in the
CSC `ANTICIPO_AVVISO := UNDECIDED` remains, and the approver is asked which value to establish.

**A behaviour that nobody requested.** When switching on, the relay of the installed module produces an audible
click. The person on the stairs hears it, but nobody requested it: it is not written in the CSC, and the approver is
asked whether it should be kept. If so, the click becomes an element of the CSC with its concrete form;
otherwise it remains a characteristic of the implementation, which another lamp may not have.

### The BINDING block

The concrete forms of the light are written in a file of their own, `FormeLuce.csc`:

```
-- The concrete forms of the staircase light, as seen by the person on the stairs.

BINDING UsoLuce VERSION 0.3
  STATUS HYPOTHESIS
  BIND premuto: VERBAL "press of the key of the wall button"
  BIND modo:    VERBAL "spenta: lamp off; accesa and in_pulizia: lamp on"
  BIND avviso:  VERBAL "the lamp switches off for 0.3 s and switches on again"
END
```

The header `BINDING UsoLuce VERSION 0.3` names the **bound CSC**, with its version. Each line
`BIND element: VERBAL "…"` describes in words the concrete form of an element of the bound CSC: a state, an
event, a request or a named constant, or the parameter of an event or of a request, written
`event.parameter`. Several `BIND` lines for the same element describe different aspects of the same form.
A `BIND` line is not a guarantee: it has neither `VERIFY` nor `DETAILS`. The block has no `PURPOSE`; its
header holds `STATUS` and the `IMPORT PROFILE` lines.

```
$ bcdd check FormeLuce.csc
bcdd check FormeLuce.csc
lines: 8 (recognised 6, comments 1, blank 1, unrecognised 0)
blocks: 1
  line 3: BINDING UsoLuce VERSION 0.3, STATUS HYPOTHESIS
    line 3: CSC UsoLuce in UsoLuce.csc at line 4: VERSION 0.3, STATUS HYPOTHESIS, no errors

1. ERRORS: 0

2. DEGREE OF THE CONTRACTUAL LINES
  verbal: 0
  formal: 0
  declared extension: 0
  unrecognised: 0

3. UNDECIDED: 0

4. PENDING APPROVAL, NOT CONTRACT: 3
  line 5: BIND premuto
  line 6: BIND modo
  line 7: BIND avviso

5. UNRECOGNISED LINES: 0

6. UNDECLARED TYPES: 0

7. CSCs NAMED BUT NOT CHECKED: 0

12. MISSING CONCRETE FORMS: 1
  line 3: BINDING UsoLuce VERSION 0.3: CAPABILITY Pulizie

outcome: no errors
```

`bcdd` looks for the bound CSC as it looks for a CSC cited by an entity (chapter 15): in the same file, in the file
`UsoLuce.csc` of the same folder, then in the folders indicated with `--dir`. The CSC found appears under the line
of the block. For a `BIND` line that names an element that the bound CSC does not declare, `bcdd` reports error E31.

Section 12, `MISSING CONCRETE FORMS`, lists the states, events and requests of the bound CSC that
no `BIND` line of the block names: here the request `Pulizie`, whose concrete form, for example the caretaker's
panel, is not yet written. An entry of section 12 is not an error. The section appears only when the
file contains at least one `BINDING` block.

A `BINDING` has a status, like a CSC: its `BIND` lines are pending approval and appear in section 4.

### Several concrete forms for the same boundary

A boundary can have several blocks of concrete forms. The CSC `Comando` has two: one for the wired button and one
for the wireless button of chapter 14. The CSC remains a single one, and each block has a **distinguishing name**, written
after `AS`, which the verification plan uses to cite it (chapter 26):

```
-- The command that the button sends to the lamp, with the concrete forms of the wired button and of the wireless one.

CSC Comando VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "The button commands the lamp to switch on"

  EVENT OUT  accendi

  GUARANTEE c1: VERBAL "At least 0.2 s pass between two accendi"
                VERIFY BY INSPECTION "the recorded commands"
END

BINDING Comando VERSION 0.1 AS filo
  STATUS HYPOTHESIS
  BIND accendi: VERBAL "closed contact between terminal 3 and the common terminal for at least 50 ms"
END

BINDING Comando VERSION 0.1 AS radio
  STATUS HYPOTHESIS
  BIND accendi: VERBAL "a radio message ACCENDI with the code of the button, repeated three times in 30 ms"
END
```

```
$ bcdd check ComandoForme.csc
bcdd check ComandoForme.csc
lines: 21 (recognised 15, comments 1, blank 5, unrecognised 0)
blocks: 3
  line 3: CSC Comando VERSION 0.1, STATUS HYPOTHESIS
  line 13: BINDING Comando VERSION 0.1 AS filo, STATUS HYPOTHESIS
    line 13: CSC Comando in this file at line 3
  line 18: BINDING Comando VERSION 0.1 AS radio, STATUS HYPOTHESIS
    line 18: CSC Comando in this file at line 3

1. ERRORS: 0
…
4. PENDING APPROVAL, NOT CONTRACT: 3
  line 9: GUARANTEE c1
  line 15: BIND accendi
  line 20: BIND accendi
…
12. MISSING CONCRETE FORMS: 0
  line 13: BINDING Comando VERSION 0.1 AS filo: none
  line 18: BINDING Comando VERSION 0.1 AS radio: none

outcome: no errors
```

In the checked file, for two `BINDING` blocks of the same CSC and the same version without a distinguishing name, or with the
same distinguishing name, `bcdd` reports error E40.

### The approval of concrete forms

`bcdd ratify` approves a `BINDING` like a CSC: the header or, with `--all`, the header and the `BIND` lines
that have their own `STATUS HYPOTHESIS` (`BIND element STATUS HYPOTHESIS: VERBAL "…"`). `BIND` lines have no short
name, so they are not approved one by one. The block to approve is chosen with `--csc NAME`, where `NAME` is the
distinguishing name of the `BINDING`. Without `--csc`, in
a file that contains a CSC, `ratify` chooses the CSC:

```
$ bcdd ratify ComandoForme.csc --all D-21
approved with D-21 in CSC Comando: 1 line
  line 4: CSC Comando
contract: 1
```

```
$ bcdd ratify ComandoForme.csc --csc filo --all D-21
approved with D-21 in BINDING Comando VERSION 0.1 AS filo: 1 line
  line 14: BINDING Comando VERSION 0.1 AS filo
contract: 1
```

```
$ bcdd ratify ComandoForme.csc --csc radio accendi D-21
bcdd ratify: in a BINDING the header or --all is approved, not a line
```

A `BINDING` without a distinguishing name, in the same file as its CSC, is not chosen with the name of the CSC: that
name designates the CSC. To approve it with `ratify` it is given a name with `AS`, or it is written in a file of its
own, where it is the only block to approve and `ratify` chooses it without `--csc`.

The approval concerns the concrete forms of the block, not the guarantees of the bound CSC, which are approved separately.

### Summary

- A **concrete form** is what someone at the boundary observes or uses of an element of a CSC: a terminal, a
  text, a colour, a file format. The concrete forms of a boundary are in a
  `BINDING … END` block, distinct from the CSC.
- The CSC establishes that an element exists; the concrete forms establish how it appears at the boundary.
- The criterion is “who sees it?”: what nobody observes at the boundary is implementation; what is observed in a form
  that can be modified without changing the meaning is concrete form; what changes the meaning is in the CSC.
- A concrete form is binding when someone external to the implementation observes or uses it.
- Each line `BIND element: VERBAL "…"` describes the form of an element of the bound CSC; `bcdd` checks that
  the element exists (E31) and lists in section 12 the elements without a concrete form.
- Several blocks for the same boundary have a distinguishing name, `AS name` (otherwise: error E40); the block to
  approve is chosen with `--csc name`.

### Special cases

**The same relay on another boundary.** If the lamp is a module sold with the relay contacts brought out to the
output terminals, to which the installer connects the bulbs, the installer observes and uses those contacts. That
boundary, between the module and whoever installs it, is described by another CSC, and on it the relay contact is a
concrete form. The criterion applies boundary by boundary: the same object can be implementation for the person on
the stairs and concrete form for the installer.

**An element that the CSC does not declare.** A line `BIND spia: VERBAL "the green indicator light of the button"` names an element
that `UsoLuce` does not declare:

```
1. ERRORS: 1
  line 7: [E31] spia is not an element of CSC UsoLuce VERSION 0.3
```

If the bound CSC is not found, or is found only in another version, the check of the elements is suspended: the
CSC appears in section 7.

**A `VERIFY` line after a `BIND` line.** A concrete form is not verified like a guarantee. A `VERIFY` line
written under a `BIND` line is a line on its own, unrecognised:

```
5. UNRECOGNISED LINES: 1
  line 8: VERIFY BY INSPECTION "the recording of the lamp"
…
outcome: no errors; unrecognised lines: 1 (--strict)
```

**A concrete form written as a guarantee.** The concrete form of `accendi` can be written in the CSC as a
guarantee in words, and `bcdd` recognises it:

```
  GUARANTEE c2: VERBAL "Every accendi is a closed contact between terminal 3 and the common terminal for at least 50 ms"
                VERIFY BY INSPECTION "the contact recorded on terminal 3"
```

```
2. DEGREE OF THE CONTRACTUAL LINES
  verbal: 2
  formal: 0
  declared extension: 0
  unrecognised: 0
  line 9: GUARANTEE c1 verbal
  line 11: GUARANTEE c2 verbal
```

The line is not to be written in the CSC. A button that sent the `accendi` by radio would keep guarantee `c1`
but not `c2`: changing the form would require a new version of the CSC and a new approval, even though the
behaviour remains the same.

**The block inside the CSC.** A `BINDING` stands outside every other block. Written before the `END` line
of the CSC, it interrupts the CSC, which remains without `END`; the `END` line of the CSC no longer has an open block
to close:

```
  BINDING Comando VERSION 0.1
  END
END
```

```
1. ERRORS: 2
  line 3: [E07] unclosed block: END of CSC Comando is missing
  line 14: [E08] END without an open block
```

**Two blocks without a distinguishing name.** Without `AS filo` and `AS radio` the two blocks of `Comando` cannot be told apart:

```
1. ERRORS: 1
  line 18: [E40] second BINDING without a name for CSC Comando VERSION 0.1: the first is at line 13. With two or more BINDINGs, each has a name: AS name
```

**Concrete forms and implementation.** Concrete forms describe only what is observed at a boundary. The
routing of the wires inside the box, the type of relay or the program of an electronic timer are
implementation and do not appear in any block, not even when the electrician needs to know them to build
the installation.

---

## Chapter 26 — The verification plan

Chapter 24 described the outcomes of recording verification, chapter 25 the way in which
each element of a boundary appears. The verification plan relates them: it indicates with which instruments a
boundary is recorded, with what resolution, and which guarantees each instrument observes.

`bcdd` reads the verification plan, checks its names and calculates which guarantees each instrument observes. No
program described in this manual executes a verification plan or recording verification.

### The verification plan

A **recording instrument** is a tool that records what happens at a boundary through the concrete forms
of the boundary: a recorder connected to a terminal, a sensor, a camera, a program that
records the messages of a network. A test tool built into the system, such as a test option
of a program, is also a recording instrument; the way to activate it is a concrete form. An instrument **observes**
what it records: an element that no instrument records is not observed.

The **resolution** of an instrument is the smallest time interval that the instrument distinguishes.

The **verification plan** of a boundary is written in a `VERIFICATION … END` block, whose header names the bound CSC
with its version. It contains:

1. the recording instruments, each with the elements of the CSC that it observes and its resolution;
2. the scenarios written in concrete forms, each with the scenario of the CSC that it translates.

`bcdd` calculates the guarantees that each instrument observes and those that no instrument observes, which remain not executed. The verification plan does not
contain guarantees and does not contain outcomes: it establishes how the recordings on which the guarantees are
verified are collected.

### The recording instruments of the light

For the staircase light two instruments are used: a light sensor in front of the lamp, with a resolution of one
millisecond, and a camera that films the button and the lamp together at 25 frames per second, with a
resolution of 40 ms. A recorder connected between terminal 3 and the common terminal observes instead the boundary
`Comando`, which has its own verification plan. The verification plan is in a file of its own, `PianoLuce.csc`:

```
-- The verification plan of the staircase light.

VERIFICATION UsoLuce VERSION 0.3
  MEANS sensore    OBSERVES modo, avviso RESOLUTION 1 ms
  MEANS telecamera OBSERVES premuto, modo RESOLUTION 40 ms
  SCENARIO s1-scale TRANSLATES s1
    @0 s     VERBAL "a finger presses the key of the wall button; the lamp switches on"
    @85 s    VERBAL "the lamp switches off for 0.3 s and switches on again"
    @90 s    VERBAL "the lamp switches off"
    @100 s   VERBAL "a finger presses the key again; the lamp switches on"
END

VERIFICATION Comando VERSION 0.1
  MEANS registratore OBSERVES accendi RESOLUTION 1 ms USING filo
END
```

A `MEANS` line declares an instrument: the name, the elements of the bound CSC that it observes (`OBSERVES`) and the
resolution (`RESOLUTION`), a duration with a unit. With `USING` the instrument names the `BINDING` through which it observes:
the recorder reads the `accendi` events in the form of the wired button, the block `AS filo` of chapter 25. The sensor
records whether the lamp is on or off, and the concrete forms of chapter 25 establish how to read the
recording: a lamp off for 0.3 s and then on again is an `avviso`, a lamp off is
`modo = spenta`. The specification leaves to whoever implements the system the way of obtaining traces from recordings.

### The guarantees observed by each instrument

A formal guarantee that cites an element that is not recorded has the outcome **not executed** (chapter 24). `bcdd` calculates,
for each instrument, the formal guarantees and assumptions that the instrument observes in full: a line is observed by an
instrument if every state, event and request it names is among its `OBSERVES` elements. The lines that no instrument
observes in full are **not executed**. Verbal lines do not take part in this calculation: they are verified by judgement or by inspection.

```
$ bcdd check PianoLuce.csc
bcdd check PianoLuce.csc
lines: 15 (recognised 12, comments 1, blank 2, unrecognised 0)
blocks: 2
  line 3: VERIFICATION UsoLuce VERSION 0.3
    line 3: CSC UsoLuce in UsoLuce.csc at line 4: VERSION 0.3, STATUS HYPOTHESIS, no errors
  line 13: VERIFICATION Comando VERSION 0.1
    line 13: CSC Comando in Comando.csc at line 3: VERSION 0.1, STATUS HYPOTHESIS, no errors
    line 14: USING filo in Comando.csc at line 13

1. ERRORS: 0

2. DEGREE OF THE CONTRACTUAL LINES
  verbal: 0
  formal: 0
  declared extension: 0
  unrecognised: 0

3. UNDECIDED: 0

4. PENDING APPROVAL, NOT CONTRACT: 0

5. UNRECOGNISED LINES: 0

6. UNDECLARED TYPES: 0

7. CSCs NAMED BUT NOT CHECKED: 0

13. VERIFICATION PLAN COVERAGE: 4
  line 3: VERIFICATION UsoLuce VERSION 0.3
    sensore (line 4): g2, g8
    telecamera (line 5): g1, g2, g2a, g7a, g9
    not executed: g3a, g4a, g4b, g10
  line 13: VERIFICATION Comando VERSION 0.1
    registratore (line 14): none
    not executed: none

outcome: no errors
```

Section 13, `VERIFICATION PLAN COVERAGE`, shows the calculation:

- the sensor observes `g2` and `g8`, which concern only the mode and the warning;
- the camera observes `g1`, `g2`, `g2a`, `g7a` and `g9`, which concern the press and the mode;
- `g3a` concerns the press, the mode and the warning, and no instrument observes all three by itself; `g4a`, `g4b` and
  `g10` concern cleaning requests, which no instrument records. These guarantees are not executed.

The count of the section is the number of guarantees not executed. The section appears only when the file
contains at least one `VERIFICATION` block, and it is not an error. The list of observed guarantees is not written in the file: `bcdd` derives it
each time from the `OBSERVES` lines.

Section 13 also lists the guarantees not executed. A verification report that omitted them
would suggest that they have been verified.

With the sensor alone, without the camera, the press is not recorded by any instrument:

```
13. VERIFICATION PLAN COVERAGE: 8
  line 3: VERIFICATION UsoLuce VERSION 0.3
    sensore (line 4): g2, g8
    not executed: g1, g2a, g3a, g4a, g4b, g7a, g9, g10
  line 12: VERIFICATION Comando VERSION 0.1
    registratore (line 13): none
    not executed: none
```

The recorder detects the `accendi` events, which follow the presses, but not the presses. Deriving a press from
an `accendi` would require guarantee `pu1` of the button (chapter 13), and a guarantee does not replace
an observation: for this reason `g1` remains not executed as long as no instrument records `premuto`.

### The resolution

The resolution limits the scope of an outcome. “Satisfied on the trace” applies with the declared resolution
of the instrument (chapter 24): for `g2a`, which admits a switch-off between 85 and 95 seconds after the last press,
a resolution of 40 ms is sufficient. For `g1`, which requires the light on in the same step as the press,
the outcome depends on the criterion by which, starting from the recording, it is established that the two facts fall in
the same step. Two
facts recorded by different instruments are considered to be in distinct steps only if their distance exceeds the
coarser resolution of the two instruments. Otherwise the temporal relation is indeterminate: it is not established
whether the facts are in the same step or in distinct steps. If an instrument with a resolution of 40 ms records the
press at 10.000 s and another records the light on at 10.015 s, the two facts are not distinguished and `g1` is inconclusive in
that step; if the light comes on at 10.200 s, `g1` is violated.

An instrument that distinguishes only intervals longer than the duration of a concrete form does not observe it. A
light sensor that detects the state of the lamp once per second may fail to detect a 0.3 s flash:
in the verification plan `avviso` does not figure among the elements that sensor observes, and `g8` has the outcome “not
executed”. Declaring `avviso` among the observed elements would give `g8` the outcome “satisfied on the
trace” even on a recording in which a warning slipped between two readings. `bcdd` does not compare the
resolution with the concrete forms: the choice of the `OBSERVES` elements remains with whoever writes the plan.

### Scenarios in concrete forms

A **translated scenario** rewrites a scenario of the CSC in the concrete forms: `SCENARIO s1-scale TRANSLATES s1`
translates scenario `s1` of `UsoLuce`. Its steps have the times of the scenario it translates and contain assertions in
words (`VERBAL`). It has neither `GIVEN` nor `EXPECT`: its expected outcome is that of the scenario it translates. If the bound
CSC does not have the named scenario, `bcdd` reports error E31.

Some facts that arise in the concrete forms do not appear in the scenario of the CSC, and on them an
implementation can behave incorrectly. A 30 ms contact on terminal 3, for example, is not an `accendi` (chapter
25), and it does not appear in the scenario of the CSC `Comando`. The verification plan of `Comando` can then contain a translated
scenario: “contact closed for 30 ms at instant 0 s, contact closed for 80 ms at instant 1 s”. This scenario translates a
scenario of `Comando` with a single `accendi`, that of the second contact. A lamp that comes on already at the first
contact treats as `accendi` a contact that is not one: the translated scenario allows this to be detected, whereas the scenario
of the CSC `Comando`, on its own, does not contain the 30 ms contact.

### Summary

- The **verification plan** (`VERIFICATION Csc VERSION v … END`) indicates the recording instruments of a boundary and the
  scenarios in concrete forms. It contains neither guarantees nor outcomes, and it is not approved.
- A **recording instrument** (`MEANS name OBSERVES elements RESOLUTION duration [USING forms]`) observes a boundary
  through the concrete forms of the boundary; its **resolution** is the smallest time interval that it
  distinguishes.
- `bcdd` calculates in section 13 the formal guarantees that each instrument observes in full and those not
  executed; a guarantee does not replace an observation.
- “Satisfied on the trace” applies with the resolution of the instrument; an instrument that distinguishes only intervals
  longer than the duration of a concrete form does not observe it.
- A translated scenario (`SCENARIO id TRANSLATES scenario`) rewrites a scenario of the CSC in the concrete forms.

### Special cases

**A verification plan is not approved.** For a `STATUS` line in a `VERIFICATION` block `bcdd` reports error E39; in the same
file, for a translated scenario that names a scenario absent from the CSC it reports error E31:

```
1. ERRORS: 2
  line 4: [E39] STATUS cannot appear in a VERIFICATION: a verification plan is not approved
  line 7: [E31] TRANSLATES names a scenario that CSC UsoLuce VERSION 0.3 does not have: s9
```

`bcdd ratify` refuses a file that contains only verification plans:

```
$ bcdd ratify PianoLuce.csc --all D-22
bcdd ratify: the file contains no block to approve: a VERIFICATION is not approved
```

**An instrument connected inside a part.** A recorder connected to the terminals that supply the
bulb, inside the lamp, records the implementation and not a boundary: no guarantee can be verified on
that recording. The verification plan associates each instrument with a boundary, through the concrete forms of the
boundary.

**A verbal guarantee and the recorder.** Guarantee `c1` of `Comando`, “at least 0.2 s pass between two accendi”,
is checked by inspection on the “recorded commands”: the recording of the recorder is the material
of the inspection. The outcome remains a judgement, “conforming by judgement” or “non-conforming by judgement”, with who
judged, and is reported separately from the outcomes of formulas (chapter 24). For this reason the recorder observes
no formal guarantee of `Comando`, and section 13 shows it with `none`.

**Several recordings of the same guarantee.** A guarantee satisfied on ten recordings remains satisfied
on those ten traces, with the resolution of the instruments used: the number of recordings does not turn the outcome
into a certainty about the situations not observed.

---

## Chapter 27 — Extensions and profiles

The aim is to specify that the light, at switch-off, does not go off instantaneously but dims over two seconds. The
keywords of chapters 21-23 are not enough. This chapter describes how a new form, the extension, is declared,
with its meaning and the way to verify it. It then describes how the extensions of a field of use are
collected in a profile, how a CSC imports it, and what trial words are.

### A guarantee that keywords do not express

The states of a CSC have a value in every step, and the formula examines them one step at a time (chapter 21).
“Within 2 seconds the light is off” is written with the keywords of chapter 22. “It dims without jumps”, by contrast,
also concerns the values between one step and the next, which a formula does not examine: the brightness varies
continuously over time.

A guarantee of this kind can be written in three ways.

**In words.** This is always possible:

```
  GUARANTEE g11: VERBAL "At switch-off the light does not go out abruptly: it dims over two seconds"
                 VERIFY BY JUDGEMENT "a person on the stairs who observes the switch-off"
```

**With an extension already written**, if a suitable one exists in a profile.

**With a new extension**, if none exists.

### The extension

An **extension** is a new form of the language, declared in an `EXTENSION Name … END` block together with its
meaning and the way to verify it; the term is not to be confused with the extension `.csc` of a file name.
It has eight fields, one per line, in any order:

| Field | Mandatory | Content |
|---|---|---|
| `KIND` | yes | where the form is used (following table) |
| `LEVEL` | yes | in which type of block the form is used, with the word that opens the block: CSC (`CSC`), entity (`ENTITY`), concrete forms (`BINDING`), verification plan (`VERIFICATION`); the field does not indicate the level of a detail (chapter 8) |
| `PARAMS` | yes, even if empty | the parameters of the form, in parentheses, each with a type or a category |
| `FORM` | yes | the form of use, in quotation marks: it begins with the name of the extension and contains each parameter once |
| `MEANING` | yes | the meaning, in words; if `REDUCES TO` is missing, it is the meaning that applies |
| `REDUCES TO` | no | the expanded form, written with the forms of the language |
| `VERIFY` | yes | the way of verification |
| `SOURCE` | yes | where the form comes from: the guarantee, the test or the decision that required it |

The `KIND` field admits six values, written in upper case:

| `KIND` | The form is used |
|---|---|
| `PATTERN` | as the form of a whole guarantee, in place of `ALWAYS` or of `WHENEVER … THEN` |
| `SCOPE` | as a scope, in place of `WHILE` |
| `FUNCTION` | inside a condition, like `COUNT` or `PREV`; after `PARAMS` the type of the result is written, `PARAMS (…) : Type` |
| `DECLARATION` | as a line that declares an element, like `STATE` |
| `RELATION` | as a relation, for example between the CSCs cited by an entity |
| `SCENARIO-FORM` | inside a scenario |

A parameter has a type, like the parameters of events, or a **category**, which indicates what is written in its
place: `Name` (a declared name), `Type` (a type), `Event` (an event), `Condition` (a condition), `Expression`
(an expression), `Duration` (a duration with a unit), `Property` (a whole property). In the `FORM` a word equal to the
name of a parameter is the place of that parameter; every other element is fixed and is written as it is.

In the `VERIFY` field two codes are written. `V1` indicates text verification and is followed by the codes of the
checks that apply, from `C1` to `C8`. `C1` is the form check, `C2` consistency, `C3` scenarios, `C4`
coverage, `C5` the rule “every used boundary is offered”, `C6` entity guarantees, `C7` realisability, which the
specification does not provide (chapter 24), `C8` details. `V2`, after a semicolon, indicates recording verification and is followed, in quotation marks,
by what counts as observation. Alternatively the field contains `BY JUDGEMENT` or `BY INSPECTION`, like a
verbal guarantee.

An extension respects the following rules:

- its name is unique in the profile and different from every keyword of the language;
- it does not change the meaning of any keyword of the language, and it does not give a second name to a form that the
  language already has: every term has a single meaning, and every meaning a single term;
- `REDUCES TO` uses only keywords of the language, parameters or extensions of the same profile, without circular
  references; if `MEANING` and `REDUCES TO` do not coincide, `REDUCES TO` applies;
- the `MEANING` does not describe the implementation and does not give one part authority or precedence over another.

`bcdd` checks the rules that concern the form:

- a missing or repeated field, or one with a value that is not admitted, and a non-conforming `FORM` (E33);
- a repeated or reserved name (E34);
- a `REDUCES TO` that names what it cannot name or that refers to itself circularly (E35);
- a `REDUCES TO` that repeats a single form of the language or another extension (E36).

The rules that concern the meaning are judged: the report lists them in section 14.

### The profile

A **profile** is a collection of extensions for a field of use, with a name and a version:

```
PROFILE Name VERSION v
  PURPOSE "the field of use"
  STATUS HYPOTHESIS
  EXTENSION …
  END
  EXTENSION …
  END
END
```

The profile has a `PURPOSE` and a `STATUS`, in any order, and contains only extensions. For an extension written
outside a profile `bcdd` reports error E32. A CSC uses a profile with the line `IMPORT PROFILE Name VERSION v`, in its
header. For a CSC that does not import the profile, the extensions of the profile are not available, even if the profile is in the
same file. A profile does not import other profiles. Whoever owns a profile maintains its versions, and an extension applies
in the version of the profile that declares it: a CSC that imports another version of the profile uses another
extension, even if the name is the same. An entity, a `BINDING` and a verification plan also import profiles,
each independently.

The specification describes two profiles: `Protocollo`, for network protocols, and `Segnale`, for quantities that
vary continuously. `Segnale` contains, among others, the extension `SIGNAL`, which declares a **continuous
quantity**, that is a quantity defined at every instant and not only in the steps.

`bcdd` looks for the imported profile as it looks for a cited CSC (chapter 15): in the checked file, then in the file
`Segnale.csc` of the same folder, then in the folders indicated with `--dir`. The profile is found only if it has the version
written in the `IMPORT PROFILE` line.

### The gradual dimming of the light

The profile `Segnale` does not contain a form for the dimming of the light. The new form is added to `Segnale`
itself, in a new version, 0.3, by whoever owns the profile:

```
-- The profile Segnale: quantities that vary continuously.
-- VERSION 0.3: extension FADE added.

PROFILE Segnale VERSION 0.3
  PURPOSE "Quantities that vary continuously, measurements on samples, response over time"
  STATUS HYPOTHESIS

  EXTENSION SIGNAL
    KIND     DECLARATION
    LEVEL    CSC
    PARAMS   (nome: Name, T: Type)
    FORM     "SIGNAL nome : T"
    MEANING  "nome is a quantity of type T, defined at every instant and not only at the steps"
    VERIFY   V1 C1 ; V2 "continuous recording of the quantity"
    SOURCE   "the profile Segnale, version 0.1"
  END

  EXTENSION FADE
    KIND     PATTERN
    LEVEL    CSC
    PARAMS   (s: Expression, d: Duration)
    FORM     "FADE s WITHIN d"
    MEANING  "In every stretch of consecutive steps of the scope, s does not rise and does not jump, and is 0
              within d of the first step of the stretch; if s is greater than 0 at that step, it is not 0
              before 0.9 d"
    VERIFY   V1 C1 ; V2 "recording of s over time; the report declares the resolution of the recording instrument"
    SOURCE   "UsoLuce 0.4, guarantee g11"
  END
END
```

`FADE` is a guarantee form (`KIND PATTERN`) used in a CSC (`LEVEL CSC`). The parameter `s` is
an expression, `d` a duration. The meaning is written in words and has no expanded form, because “does not jump” concerns
the values between one step and the next.

The profile, checked on its own, has no errors:

```
$ bcdd check Segnale.csc
bcdd check Segnale.csc
lines: 29 (recognised 24, comments 2, blank 3, unrecognised 0)
blocks: 1
  line 4: PROFILE Segnale VERSION 0.3, STATUS HYPOTHESIS

1. ERRORS: 0

2. DEGREE OF THE CONTRACTUAL LINES
  verbal: 0
  formal: 0
  declared extension: 0
  unrecognised: 0

3. UNDECIDED: 0

4. PENDING APPROVAL, NOT CONTRACT: 2
  line 8: EXTENSION SIGNAL
  line 18: EXTENSION FADE

5. UNRECOGNISED LINES: 0

6. UNDECLARED TYPES: 0

7. CSCs NAMED BUT NOT CHECKED: 0

14. TO BE JUDGED: 4
  line 8: EXTENSION SIGNAL: the MEANING neither describes the implementation nor gives authority or precedence between parts
  line 8: EXTENSION SIGNAL: does not repeat a form that the language already has
  line 18: EXTENSION FADE: the MEANING neither describes the implementation nor gives authority or precedence between parts
  line 18: EXTENSION FADE: does not repeat a form that the language already has

outcome: no errors
```

The two extensions are pending approval, like the profile, and appear in section 4. Section 14 lists for
each the rules to be judged: that the meaning does not describe the implementation, and that an extension without
`REDUCES TO` does not repeat a form that the language already has.

The CSC `UsoLuce` moves to version 0.4, pending approval. It imports the profile, declares the brightness and adds
guarantee `g11`:

```
CSC UsoLuce VERSION 0.4
  STATUS HYPOTHESIS
  IMPORT PROFILE Segnale VERSION 0.3
…
  STATE      modo : Modo INITIAL spenta
  STATE      luminosita : Real [0.0 .. 1.0] INITIAL 0.0
…
  -- g11: «At switch-off the light does not go out abruptly: it dims over two seconds»
  GUARANTEE g11: WHILE modo = spenta: FADE luminosita WITHIN 2 s
```

It reads: in every stretch in which the light is off, from the first step of the stretch the brightness falls without jumps and
without rising again, and reaches 0 between 1.8 and 2 seconds later; if at the start of the stretch it is already 0, it remains 0. With
the dimming the concrete forms of chapter 25 also change: `modo = spenta` holds from the moment the
light begins to dim, and the brightness is the level of the light emitted by the lamp, from 0 (off) to 1
(full). The brightness is declared as a state; the special case “A quantity declared with `SIGNAL`”
shows the declaration as a continuous quantity.

In the report the profile found appears under the line of the CSC, and `g11` has a new degree:

```
$ bcdd check UsoLuce.csc
bcdd check UsoLuce.csc
lines: 69 (recognised 58, comments 6, blank 5, unrecognised 0)
blocks: 1
  line 4: CSC UsoLuce VERSION 0.4, STATUS HYPOTHESIS
    line 6: IMPORT PROFILE Segnale in Segnale.csc at line 4: VERSION 0.3, STATUS HYPOTHESIS, no errors

1. ERRORS: 0

2. DEGREE OF THE CONTRACTUAL LINES
…
  line 42: GUARANTEE g10 formal
  line 49: GUARANTEE g11 declared extension
  line 50: ASSUME a1 verbal
```

`bcdd` recognises the use of `FADE` from its position, that of a guarantee form, and compares it with the `FORM`:
`luminosita` occupies the place of `s`, `2 s` that of `d`. For a use that does not respect the `FORM`, or that is in a
position or in a block different from those declared by `KIND` and `LEVEL`, `bcdd` reports error E37.

### The degree of a guarantee written with an extension

The degree of a guarantee written with an extension depends on the extension:

- if the extension has `REDUCES TO`, it is a shorthand (chapter 23): the guarantee has **formal** degree, and its
  meaning is the expanded form;
- if the extension does not have `REDUCES TO`, the guarantee has the degree **declared extension**: its meaning is the
  `MEANING`, and it is verified as the `VERIFY` field declares.

If the `VERIFY` declares an observation (`V2`), a guarantee of degree declared extension has, on
recordings, outcomes of the same kind as those of formal guarantees, and the outcomes also show the name
of the extension. If the `VERIFY` declares a judgement or an inspection, it has instead the outcomes of verbal
guarantees. In the report of a verification the three degrees are in separate sections, and their outcomes are not added
(chapter 24).

`g11` has the degree declared extension, and the `VERIFY` of `FADE` declares an observation: the recording of the
brightness over time. To observe it, the verification plan of chapter 26 must include an instrument that records
the brightness, and not only whether the lamp is on or off.

### Approval with a profile pending approval

A guarantee that uses an extension of a profile pending approval is pending approval, even in an approved CSC: the
meaning of the extension has not yet been approved. `bcdd ratify --all` approves the CSC and leaves `g11` pending
approval, and reports it:

```
$ bcdd ratify UsoLuce.csc --all D-23
approved with D-23 in CSC UsoLuce: 6 lines
  line 5: CSC UsoLuce
  line 23: GUARANTEE g2a
  line 28: GUARANTEE g3a
  line 31: GUARANTEE g4a
  line 32: GUARANTEE g4b
  line 39: GUARANTEE g7a
contract: 17
lines still pending approval: 1
  line 49: GUARANTEE g11
```

The profile is approved as a whole, with its extensions, which have no status of their own:

```
$ bcdd ratify Segnale.csc D-24
approved PROFILE Segnale VERSION 0.3 (line 4) with D-24
extensions: 2
```

Once the profile is approved, `g11` follows the status of the CSC, which is approved:

```
bcdd check UsoLuce.csc
lines: 69 (recognised 58, comments 6, blank 5, unrecognised 0)
blocks: 1
  line 4: CSC UsoLuce VERSION 0.4, STATUS RATIFIED BY D-23
    line 6: IMPORT PROFILE Segnale in Segnale.csc at line 4: VERSION 0.3, STATUS RATIFIED BY D-24, no errors
…
4. PENDING APPROVAL, NOT CONTRACT: 0
```

If the profile is in the same file as the CSC, the profile is chosen with `--csc Segnale`; without `--csc`,
`ratify` chooses the CSC.

### Trial words

Some keywords of the language are **on trial**: they are used like the others, but a future revision of the language
may move them into a profile, as extensions with the same name, the same form and the same meaning. Among
those described in this manual, the words on trial are `TYPE` (chapter 6), `GIVEN` (chapter 9), `VARIANT`
(chapter 20), `PREV` (chapter 22) and `CHANGED` (chapter 23).

If a trial word moves into a profile, a CSC that uses it remains valid with the addition of the
`IMPORT PROFILE` line of that profile. In an approved CSC the addition is a modification like the others and requires a
new version (chapter 10). The word remains reserved even in the CSCs that do not import the profile: it cannot
become the name of an element.

Conversely, a form used with the same meaning in several independent fields of use can enter the
keywords of the language. The decision rests with whoever maintains the language.

### Summary

- An **extension** declares a new form with eight fields, all mandatory except `REDUCES TO`: among these
  the form (`FORM`), the meaning (`MEANING`), the way of verification (`VERIFY`) and the origin (`SOURCE`).
- An extension does not change the meaning of any keyword of the language, and its meaning does not describe the
  implementation; `bcdd` checks the form of the fields (E33-E36) and lists in section 14 the rules to be judged.
- A **profile** collects the extensions of a field of use, with a version; a CSC uses it with
  `IMPORT PROFILE`, and `bcdd` looks for it with the written version.
- `bcdd` recognises the use of an extension from its position and compares it with the `FORM` (E37).
- With `REDUCES TO` a guarantee written with the extension is formal; without it, it has the degree **declared extension**,
  and is verified as the `VERIFY` declares.
- A guarantee that uses a profile pending approval remains pending approval until the profile is approved.
- Some keywords are **on trial**: a revision may move them into a profile, and a CSC that uses them remains valid
  with `IMPORT PROFILE`.

### Special cases

**A quantity declared with `SIGNAL`.** An extension of `KIND DECLARATION` is used as the first word of a
line that declares a name. With the extension `SIGNAL` of the profile the brightness is declared as a continuous quantity:

```
  SIGNAL     luminosita : Real [0.0 .. 1.0]
```

The line declares the name `luminosita`, which enters the list of names of the CSC and is used in formulas like a
state, without a type check. With this line in place of the `STATE` line, the report of version 0.4 is the following:

```
1. ERRORS: 0
…
5. UNRECOGNISED LINES: 0
```

Uses of extensions of `KIND RELATION` and `KIND SCENARIO-FORM` are not read by `bcdd` 1.0-beta: the line that
contains them is unrecognised and appears in section 5; with `--strict` `bcdd` exits with code 3.

**The profile in another version.** If the folder contains only version 0.2 of `Segnale`, the imported profile
is not found. Section 7 reports it, with the version found, and the guarantee that uses `FADE` is
not recognised; the report gives the reason:

```
5. UNRECOGNISED LINES: 1
  line 49: GUARANTEE g11: WHILE modo = spenta: FADE luminosita WITHIN 2 s (profile Segnale VERSION 0.3 not found)
…
7. CSCs NAMED BUT NOT CHECKED: 1
  line 6: PROFILE Segnale (only VERSION 0.2 found in Segnale.csc)
…
outcome: no errors; unrecognised lines: 1 (see section 5)
```

It is not an error: the name `FADE` might be defined precisely in the missing version. With `--strict` `bcdd` exits with
code 3.

**The extension inside the CSC.** An extension is declared in a profile. If it is written inside the CSC,
`bcdd` reports error E32. Its lines, including the `END` line, are not recognised; that `END` line closes the
extension and not the CSC. Without the
`IMPORT PROFILE` line the guarantee that uses `FADE` is also unrecognised:

```
1. ERRORS: 1
  line 49: [E32] EXTENSION outside a PROFILE: an extension is declared in a profile
…
5. UNRECOGNISED LINES: 10
  line 48: GUARANTEE g11: WHILE modo = spenta: FADE luminosita WITHIN 2 s
  line 49: EXTENSION FADE
  line 50: KIND     PATTERN
  line 51: LEVEL    CSC
  line 52: PARAMS   (s: Expression, d: Duration)
  line 53: FORM     "FADE s WITHIN d"
  line 54: MEANING  "s falls without rising again and without jumps, and is 0 within d"
  line 55: VERIFY   V1 C1 ; V2 "recording of s over time"
  line 56: SOURCE   "UsoLuce 0.4, guarantee g11"
  line 57: END
```

**A non-conforming field.** The value of `KIND` is written in upper case, and `SOURCE` is mandatory:

```
1. ERRORS: 2
  line 18: [E33] field SOURCE is missing in EXTENSION FADE
  line 19: [E33] value of KIND not admitted: pattern
```

**A use that does not respect the form.** Without `WITHIN 2 s` the use `GUARANTEE g11: WHILE modo = spenta: FADE luminosita`
does not respect the `FORM`:

```
1. ERRORS: 1
  line 49: [E37] use of FADE that does not respect FORM "FADE s WITHIN d"
```

**A form that the language already expresses.** Before writing an extension it is checked whether the guarantee can
be expressed with the keywords of the language. An extension `MAI` with the meaning of `NEVER` (chapter 23)
would give two names to the same thing and would not respect the second rule of extensions. If the extension has
`REDUCES TO`, the check is automatic: the expanded form of `MAI p` is `NEVER p`, and `bcdd` reports it.

```
    REDUCES TO NEVER p
```

```
1. ERRORS: 1
  line 36: [E36] EXTENSION MAI repeats a form that the language already has: NEVER
```

If the extension does not declare `REDUCES TO`, the check rests with a person: it is an entry of section 14.

**An extension that describes the implementation.** A `MEANING` such as “when the relay opens a capacitor
keeps the lamp on for 2 seconds” describes how the lamp is built, not what is observed, and does not
respect the rules of extensions. `bcdd` does not read the meaning: the rule is an entry of section 14, which
a person judges. The new form describes the brightness that the person on the stairs observes, like `FADE`; the way of
obtaining it remains with whoever implements the lamp.

**`IMPORT PROFILE` before `STATUS`.** The lines `STATUS`, `IMPORT PROFILE` and `PURPOSE` follow the `CSC` line,
before the body of the CSC, and can be written in any order. In a version with `IMPORT PROFILE` before
`STATUS RATIFIED BY D-20`, the CSC turns out approved; still pending approval are the details without their own `STATUS` and
`g11`, which uses the profile pending approval:

```
bcdd check UsoLuce.csc
lines: 69 (recognised 58, comments 6, blank 5, unrecognised 0)
blocks: 1
  line 4: CSC UsoLuce VERSION 0.4, STATUS RATIFIED BY D-20
    line 5: IMPORT PROFILE Segnale in Segnale.csc at line 4: VERSION 0.3, STATUS HYPOTHESIS, no errors
…
4. PENDING APPROVAL, NOT CONTRACT: 6
  line 23: GUARANTEE g2a
  line 28: GUARANTEE g3a
  line 31: GUARANTEE g4a
  line 32: GUARANTEE g4b
  line 39: GUARANTEE g7a
  line 49: GUARANTEE g11
```

For a second `STATUS` line in the header, by contrast, `bcdd` reports error E10, as for a second `PURPOSE`. With
`STATUS HYPOTHESIS` immediately after the `CSC` line and `STATUS RATIFIED BY D-20` after `IMPORT PROFILE`, the report
flags the second as an error and keeps the first valid:

```
bcdd check UsoLuce.csc
lines: 70 (recognised 59, comments 6, blank 5, unrecognised 0)
blocks: 1
  line 4: CSC UsoLuce VERSION 0.4, STATUS HYPOTHESIS
    line 6: IMPORT PROFILE Segnale in Segnale.csc at line 4: VERSION 0.3, STATUS HYPOTHESIS, no errors

1. ERRORS: 1
  line 7: [E10] STATUS repeated: the first is at line 5
```

---

## Chapter 28 — A real case: the audio measurement kit

The previous chapters use a small example, built to introduce one form at a time. This chapter
examines the description of a real system, an audio measurement kit, and the report that `bcdd` produces on it. It does not
introduce new forms: each element refers back to the chapter in which it is described.

### The system

The kit is added to a listening system made up of a source, an amplifier and the loudspeakers. The music
signal, which in the files is called “programma” (programme), passes from the source to the kit's computer and
from there to the amplifier. The computer is a Raspberry Pi 4 with an audio processing program, abbreviated AP in
the files. The kit measures the acoustic response of the room and derives from it a correction for the music
signal; during listening it detects the level sent to the loudspeakers.

AP works in three modes, Misure, Calcolo and Riproduzione (Measurement, Calculation and Playback), which are chosen from the AP window or from the
phone. When moving from one mode to another, the user moves the cables by hand between the two inputs of the card
that captures the signals, input L and input R.

The kit exists in two models, 1.a and 1.b; this chapter examines model 1.b, which uses two sound cards. The
stream card carries the programme signal; the capture card receives the signals of the measurement microphone, of
the level sensor and of the reference. For the level sensor there are two choices. The first is a **direct box** (DI in the files): a
small device that takes the signal from the output terminals of the amplifier, to which the
loudspeakers are connected, and carries it to the capture card. The second is the measurement microphone itself, which after the measurements
is moved close to a loudspeaker. In the first choice the direct box is an optional part: without it the
Loudness function of AP, which depends on the level sensor, cannot be used, while the rest of the kit works.

### The description

The description consists of several files, each with a CSC or an entity (chapters 2 and 12). The CSCs describe the boundaries: for
example `Modalita`, the choice of mode; `Ricablaggio`, the cables that the user moves between one mode and
another; `Morsetti`, the output of the amplifier at the loudspeaker terminals. The entities describe the devices:
the computer, the two cards, the microphone, the direct box, the cable that carries back the reference. The entity `Kit1b`
describes the kit as a whole; the entity `Impianto1b` describes the kit together with the user's devices.

The direct box is an entity with one used boundary and one provided boundary (chapter 12):

```
-- The direct box performs the detection of the output level at the terminals of a passive loudspeaker.
-- The direct box used as reference in Misure is another function, Riferimento: not described here.
-- Postponed: connectors, attenuators, maximum levels, phantom or battery power supply.
-- Sources: system model, sections on the direct box; indications of the operator.

ENTITY DirectBox VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "The direct box of the kit: it reads the signal at the terminals of a loudspeaker and carries it to the capture card as level sensor"
  USES   Morsetti
  OFFERS SegnaleLivello
  GUARANTEE di1 STATUS RATIFIED BY D-20: VERBAL "The output level of the DI is the level at the terminals minus the chosen attenuation: the attenuator is chosen according to the input that receives it (source: system model, section on the direct box; indication of the operator)"
                 VERIFY BY JUDGEMENT "the operator, who compares the level read with two positions of the attenuator"
  GUARANTEE di2 STATUS RATIFIED BY D-20: VERBAL "The DI outputs an essentially line-level signal, often balanced, and can also go into a line input (source: indication of the operator)"
                 VERIFY BY INSPECTION "the data sheet of the DI"
END
```

The file applies some conventions adopted throughout the description of the kit. The header comments indicate the sources of the facts and what the
file does not describe; in the files shown here the sources are indicated in generic form. Each guarantee shows its own source in parentheses, inside the text in quotation marks.
`bcdd` does not interpret that text (chapter 2): the sources are therefore meant for the reader and the approver.

The guarantees are approved one by one with the decision `D-20`, while the header remains `STATUS
HYPOTHESIS`: in an entity the header is not approved, only the individual guarantees (chapter 12). The
CSCs of the kit follow the same scheme: the guarantees have their own `STATUS` (chapter 7).

The connectors, attenuators, maximum levels and power supply of the direct box, cited in the third comment,
are elements that whoever is at the boundary observes or uses, that is, concrete forms (chapter 25); the description of
the kit does not contain them yet.
The power supply can be phantom (supplied by the card through the cable) or battery.

### The kit entity

The following extract shows the main lines of `Kit1b.csc`. The omitted lines are indicated with `…`; the
line numbers of the report refer to the whole file.

```
ENTITY Kit1b VERSION 0.2
  STATUS HYPOTHESIS
  PURPOSE "The kit for the DSP passthrough on Raspberry Pi 4 with two cards: one carries the programme, the other captures microphone, level sensor and reference"
  OFFERS Modalita
  OFFERS Misura
  OFFERS LetturaLivello
  OFFERS Ricablaggio
  OFFERS RilevamentoLivello
  USES   Programma
  USES   IngressoAmplificatore
  COMPOSED OF
    computer  : Calcolatore1b
    flusso    : SchedaFlusso
    cattura   : SchedaCattura
    loop      : CavoLoop
  …
  GUARANTEE k4 STATUS RATIFIED BY D-20: VERBAL "The programme passes from input to output with at most 100 ms of delay (source: kit requirement, indicated by the operator)"
                VERIFY BY JUDGEMENT "the operator, who measures the delay between the input of the stream card and its output"
  …
  VARIANT sensore = di
    USES   Morsetti
    COMPOSED OF
      microfono : MicrofonoMisura
      di        : DirectBox [0 .. 1]   -- without DI no Loudness (rl3)
  …
    SCENARIO k-s2 EXPECT REJECTED
      @0 s     Ricablaggio.collega(ingresso: ingresso_L, ospite: microfono)
      @0 s     Ricablaggio.collega(ingresso: ingresso_R, ospite: loop)
      @5 s     Ricablaggio.collega(ingresso: ingresso_L, ospite: di)
      @10 s    Modalita.scegli(modalita: misure)
      @10 s    Modalita.attiva(modalita: misure)
  VARIANT sensore = microfono
    COMPOSED OF
      microfono : MicrofonoMisuraELivello   -- a single device, two functions in different phases
  …
END
```

In the extract the forms of part two reappear:

| In the file | What it describes | Chapter |
|---|---|---|
| `OFFERS`, `USES` | the boundaries of the kit: five provided, two used | 12 |
| `COMPOSED OF` | the parts common to every form of the kit | 13 |
| `VARIANT sensore = di`, `VARIANT sensore = microfono` | the choice group of the level sensor | 20 |
| `di : DirectBox [0 .. 1]` | the direct box, optional part in the choice `di` only | 19 |
| `USES Morsetti` in the segment `sensore = di` | a boundary used only with that choice | 20 |
| `GUARANTEE k4` | an entity guarantee, in words | 12 |
| `SCENARIO k-s2` | an entity scenario, with the name of the CSC in front of every name | 18 |

Scenario `k-s2` describes the microphone and the direct box connected to input L at the same time, and must be
rejected. The rule is expressed by guarantee `ri1` of the CSC `Ricablaggio`: input L hosts only one
device at a time. The scenario is written in the segment `sensore = di` because it names the direct box, which is present
only with that choice.

In the choice `microfono` the same microphone performs two functions in different modes: it measures the room in
Misure and acts as level sensor in Riproduzione. The language provides no form for a part that
performs a function only in certain modes (chapter 19). The description therefore treats the microphone of this
choice as an entity of its own, `MicrofonoMisuraELivello`, which provides both signals, even though the physical
device is a single one. The decision is declared in the comments of the file. For the same reason the phone, needed only in
Taratura (calibration), a procedure of Riproduzione, appears in `Impianto1b` as an always-present part.

### The report

```
$ bcdd check --strict Kit1b.csc
bcdd check --strict Kit1b.csc
lines: 123 (recognised 104, comments 18, blank 1, unrecognised 0)
blocks: 1
  line 5: ENTITY Kit1b VERSION 0.2, STATUS HYPOTHESIS
    line 8: OFFERS Modalita in Modalita.csc at line 8: VERSION 0.1, STATUS HYPOTHESIS, no errors
    line 9: OFFERS Misura in Misura.csc at line 5: VERSION 0.1, STATUS HYPOTHESIS, no errors
    line 10: OFFERS LetturaLivello in LetturaLivello.csc at line 6: VERSION 0.1, STATUS HYPOTHESIS, no errors
    line 11: OFFERS Ricablaggio in Ricablaggio.csc at line 8: VERSION 0.1, STATUS HYPOTHESIS, no errors
    line 12: OFFERS RilevamentoLivello in RilevamentoLivello.csc at line 4: VERSION 0.1, STATUS HYPOTHESIS, no errors
    line 13: USES Programma in Programma.csc at line 4: VERSION 0.1, STATUS HYPOTHESIS, no errors
    line 14: USES IngressoAmplificatore in IngressoAmplificatore.csc at line 5: VERSION 0.1, STATUS HYPOTHESIS, no errors
    line 16: computer : Calcolatore1b in Calcolatore1b.csc at line 4: VERSION 0.1, STATUS HYPOTHESIS, no errors
    line 17: flusso : SchedaFlusso in SchedaFlusso.csc at line 4: VERSION 0.1, STATUS HYPOTHESIS, no errors
    line 18: cattura : SchedaCattura in SchedaCattura.csc at line 6: VERSION 0.1, STATUS HYPOTHESIS, no errors
    line 19: loop : CavoLoop in CavoLoop.csc at line 5: VERSION 0.1, STATUS HYPOTHESIS, no errors
    line 43: USES Morsetti in Morsetti.csc at line 7: VERSION 0.1, STATUS HYPOTHESIS, no errors
    line 45: microfono : MicrofonoMisura in MicrofonoMisura.csc at line 4: VERSION 0.1, STATUS HYPOTHESIS, no errors
    line 46: di : DirectBox in DirectBox.csc at line 6: VERSION 0.1, STATUS HYPOTHESIS, no errors
    line 88: microfono : MicrofonoMisuraELivello in MicrofonoMisuraELivello.csc at line 7: VERSION 0.1, STATUS HYPOTHESIS, no errors

1. ERRORS: 0

2. DEGREE OF THE CONTRACTUAL LINES
  verbal: 5
  formal: 0
  declared extension: 0
  unrecognised: 0
  line 20: GUARANTEE k1 verbal
  line 22: GUARANTEE k2 verbal
  line 24: GUARANTEE k4 verbal
  line 47: GUARANTEE k3 verbal
  line 89: GUARANTEE km2 verbal

3. UNDECIDED: 0

4. PENDING APPROVAL, NOT CONTRACT: 0

5. UNRECOGNISED LINES: 0

6. UNDECLARED TYPES: 0

7. CSCs NAMED BUT NOT CHECKED: 0

8. USES WITHIN ENTITIES: 11
  line 16: computer uses AudioUsb: it is provided by flusso (line 17), cattura (line 18)
  line 17: flusso uses Programma: Kit1b uses it from outside (line 13)
  line 17: flusso uses IngressoAmplificatore: Kit1b uses it from outside (line 14)
  line 18: cattura uses SegnaleMisura: it is provided by microfono (line 45) (in: sensore = di)
  line 18: cattura uses SegnaleMisura: it is provided by microfono (line 88) (in: sensore = microfono)
  line 18: cattura uses SegnaleLivello: it is provided by di (line 46) (in: with di)
  line 18: cattura uses SegnaleLivello: nobody provides it (in: without di)
  line 18: cattura uses SegnaleLivello: it is provided by microfono (line 88) (in: sensore = microfono)
  line 18: cattura uses Riferimento: it is provided by loop (line 19)
  line 19: loop uses UscitaAnalogica: it is provided by flusso (line 17)
  line 46: di uses Morsetti: Kit1b uses it from outside (line 43) (in: with di)

9. COMPOSITIONS: 3
  line 5: ENTITY Kit1b: 3
    sensore = di, with di
    sensore = di, without di
    sensore = microfono

10. DECLARED ABSENCES: 2
  line 18: without di: the part cattura uses connector SegnaleLivello: no other part of Kit1b provides it, nor does Kit1b use it from outside
  line 43: without di: the public connector Morsetti of Kit1b (used) is not assigned to any part

outcome: no errors
```

The report is read with the rules of the previous chapters.

At the top, under the block `ENTITY Kit1b`, `bcdd` lists the cited boundaries and parts, each with its
file, version, `STATUS` and the outcome of the check (chapters 12 and 13). Of the parts `bcdd` reads only
the `OFFERS` and `USES` lines; their parts and the CSCs they cite are checked in their respective files (chapter 13).

Section 2 lists five entity guarantees, all in words: the description of the kit does not use the formulas of part three.
Section 4 is empty because every guarantee has its own `STATUS RATIFIED BY D-20`.

Section 8 shows the rule “every used boundary is offered” (chapter 13) applied to every composition. The first
entry shows that the part `computer` uses `AudioUsb`, provided by two parts: the stream card and the capture card.
The rule requires every used boundary to be provided by at least one part; that two parts provide the same
boundary is not an error. The entries with the suffix `(in: …)` apply only in the compositions indicated (chapter 19).

Section 9 lists three compositions, not four. The group `sensore` has two choices, and the optional direct
box doubles only the compositions of the choice `di`, because it appears in the segment of that choice (chapters 19 and 20).

Section 10 lists two declared absences, both in the composition without the direct box. Without the
direct box no part provides `SegnaleLivello` to the capture card, and `Morsetti`, which the kit uses from outside in
that choice, is not assigned to any part. The two absences correspond to errors E14 and E16
of chapter 13. Here they are not reported as errors because the missing part is optional; with the direct box
present both disappear. In the composition `sensore =
microfono` the level signal is provided by the microphone, and nothing is missing.

### The kit inside the listening system

The entity `Impianto1b` contains the kit as a part, `kit : Kit1b`, together with the source, the amplifier, the
loudspeakers and the phone. The choices of the kit appear in its compositions, preceded by the name of the part
(chapter 20):

```
8. USES WITHIN ENTITIES: 6
  line 12: kit uses Programma: it is provided by sorgente (line 13)
  line 12: kit uses IngressoAmplificatore: it is provided by amplificatore (line 14)
  line 12: kit uses Morsetti: it is provided by amplificatore (line 14) (in: kit.sensore = di)
  line 15: diffusori uses Morsetti: it is provided by amplificatore (line 14)
  line 16: telefono uses Modalita: it is provided by kit (line 12)
  line 16: telefono uses LetturaLivello: it is provided by kit (line 12)

9. COMPOSITIONS: 2
  line 4: ENTITY Impianto1b: 2
    kit.sensore = di
    kit.sensore = microfono

10. DECLARED ABSENCES: 0
```

There are two compositions: from outside only the choices of the group `sensore` of the kit are distinguished,
while its optional part does not generate separate compositions (chapter 20).
The kit uses `Morsetti` only with the choice `di`, and in the listening system the amplifier provides it.

### The limits of the report

The report confirms that the files are written correctly and that, in every composition, every used boundary is
provided by a part, except for the declared absences. It attests nothing else:

- it does not establish whether the scenarios are actually admitted or rejected: for `k-s2` it checks only that the names used
  exist in the cited CSCs (chapters 9 and 18);
- it does not assess the text of the guarantees or the sources indicated in quotation marks: the correctness of the facts is the responsibility of whoever
  wrote the description and whoever approved it (chapter 7);
- it does not check the guarantees on the built kit: that requires the concrete forms and a verification plan
  (chapters 25 and 26), and recording verification (chapter 24). No program described in the manual
  executes this verification.

### Summary

- A real system is described with the same forms as the light example: CSCs for the boundaries, entities for the
  devices, parts, variants and optional parts.
- Each guarantee states its own source in the text; `bcdd` does not interpret it.
- The report checks every composition, lists the declared absences and does not judge the facts.
- What the language does not express, such as a part that operates only in certain modes, is resolved with a
  decision of whoever writes the description, declared in the comments.

### Special cases

**A choice with the incorrect part.** If in the choice `sensore = microfono` the part
`microfono : MicrofonoMisura`, which provides only the measurement signal, is written by mistake, no part provides the level signal to
the capture card:

```
1. ERRORS: 1
  line 18: [E14] the part cattura uses connector SegnaleLivello: no other part of Kit1b provides it, nor does Kit1b use it from outside (in: sensore = microfono)
```

In the composition without the direct box the same omission remains a declared absence, because the optional
part justifies it; in the choice `microfono` no optional part justifies it, and the omission is an error.
Section 8 brings the two compositions concerned together in a single entry, separating them with `;`:

```
  line 18: cattura uses SegnaleLivello: nobody provides it (in: sensore = di, without di; sensore = microfono)
```

---

## Chapter 29 — The complete procedure, from start to finish

This chapter writes the staircase light CSC from the beginning, using the four commands of `bcdd` in sequence:
`new` creates the skeleton, `check` checks the form, `refine` submits the CSC to a language model and
`ratify` records the approval. Each step refers back to the chapter that describes it. At the end the chapter indicates
what the program does not do.

### The skeleton

```
$ bcdd new UsoLuce
created UsoLuce.csc
```

The file created contains the header with `STATUS HYPOTHESIS`, a purpose to be filled in, the forms suggested in the
comments and `END` (chapter 7). The skeleton already passes the check:

```
$ bcdd check --strict UsoLuce.csc
bcdd check --strict UsoLuce.csc
lines: 17 (recognised 4, comments 10, blank 3, unrecognised 0)
blocks: 1
  line 4: CSC UsoLuce VERSION 0.1, STATUS HYPOTHESIS

1. ERRORS: 0
…
outcome: no errors
```

The outcome attests that the file is written correctly, not that it contains a description: the purpose is still “to be filled in”.

### The first draft, by hand

The CSC is written by hand, entirely in words (chapters 2-4): the purpose, the input and output events, the
states observable at the boundary, the guarantees and the assumptions. The comments of the skeleton are removed.

```
-- The staircase light, as seen by the person on the stairs.

CSC UsoLuce VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "The person on the stairs presses a button and has light to go up or down"

  EVENT IN   premuto
  EVENT OUT  avviso
  STATE      accesa : Boolean INITIAL false

  GUARANTEE g1: VERBAL "When someone presses the button, the light switches on"
                VERIFY BY JUDGEMENT "a person who presses the button and watches"
  GUARANTEE g2: VERBAL "The light switches off by itself after a while"
                VERIFY BY JUDGEMENT "a person with a watch"
  GUARANTEE g3: VERBAL "Shortly before switching off, the light gives a warning to the person on the stairs"
                VERIFY BY JUDGEMENT "a person on the stairs who waits for the light to switch off"
  ASSUME    a1: VERBAL "Whoever presses the button holds it down for at least a tenth of a second"
                VERIFY BY JUDGEMENT "a person who observes how the button is pressed"
END
```

### The check

```
$ bcdd check --strict UsoLuce.csc
bcdd check --strict UsoLuce.csc
lines: 19 (recognised 15, comments 1, blank 3, unrecognised 0)
blocks: 1
  line 3: CSC UsoLuce VERSION 0.1, STATUS HYPOTHESIS

1. ERRORS: 0

2. DEGREE OF THE CONTRACTUAL LINES
  verbal: 4
  formal: 0
  declared extension: 0
  unrecognised: 0
  line 11: GUARANTEE g1 verbal
  line 13: GUARANTEE g2 verbal
  line 15: GUARANTEE g3 verbal
  line 17: ASSUME a1 verbal

3. UNDECIDED: 0

4. PENDING APPROVAL, NOT CONTRACT: 4
  line 11: GUARANTEE g1
  line 13: GUARANTEE g2
  line 15: GUARANTEE g3
  line 17: ASSUME a1

5. UNRECOGNISED LINES: 0

6. UNDECLARED TYPES: 0

7. CSCs NAMED BUT NOT CHECKED: 0

outcome: no errors
```

The file is written correctly and the four contractual lines are pending approval. Two guarantees remain vague: `g2` does not specify
after how long the light switches off; `g3` does not specify how long before the switch-off the warning arrives.

### The questions of the language model

With `bcdd refine` the language model asks questions on the vague points and proposes details (chapter 8). The initial lines, which show the
check of the file and the call to the model, are omitted; the questions and the proposals vary from one run
to another.

```
$ bcdd refine UsoLuce.csc
…
QUESTION 1 of 2
  How long after the last press must the light switch off, and with what tolerance?
  1) 60 seconds, with a tolerance of 5 seconds
  2) 90 seconds, with a tolerance of 5 seconds
  3) 3 minutes, with a tolerance of 10 seconds
answer (1 to 3, or write your own; press Enter alone to skip): 2
  choice 2: 90 seconds, with a tolerance of 5 seconds

QUESTION 2 of 2
  How long before switch-off does the warning arrive?
  1) 5 seconds before
  2) 10 seconds before
answer (1 to 2, or write your own; press Enter alone to skip): 1
  choice 1: 5 seconds before
…
PROPOSAL 1 of 3, details g2 (line 13)
  GUARANTEE g2a DETAILS g2 STATUS HYPOTHESIS: VERBAL "The light switches off 90 s after the last press, with a tolerance of 5 s"
                                              VERIFY BY JUDGEMENT "a person who measures with a stopwatch the time between the last press and switch-off"
accept? y = yes, n = no, q = quit (discards the rest): y

PROPOSAL 2 of 3, details g2 (line 13)
  GUARANTEE g2b DETAILS g2 STATUS HYPOTHESIS: VERBAL "A press while the light is on restarts the 90 s from the beginning"
                                              VERIFY BY JUDGEMENT "a person who presses the button again while the light is on and measures with a stopwatch the time until switch-off"
accept? y = yes, n = no, q = quit (discards the rest): y

PROPOSAL 3 of 3, details g3 (line 15)
  GUARANTEE g3a DETAILS g3 STATUS HYPOTHESIS: VERBAL "The warning arrives between 15 and 5 s before switch-off"
                                              VERIFY BY JUDGEMENT "a person on the stairs with a stopwatch"
accept? y = yes, n = no, q = quit (discards the rest): n

summary: accepted 2, discarded by you 1, discarded by the check 0
write 2 proposals (4 lines) in UsoLuce.csc and 2 answers in UsoLuce.csc.dialogo? y = yes, n = no: y
written UsoLuce.csc: 2 proposals (4 lines)
written UsoLuce.csc.dialogo: 2 answers
```

The third proposal does not correspond to the answer given, `5 seconds before`, and is discarded. The proposals
are accepted or discarded at the judgement of whoever writes the CSC: the model proposes, and only what is accepted
and confirmed enters the file. Every line written in this way remains pending approval.

### Corrections by hand and the scenarios

The detail of `g3` is written by hand, like any line. The
scenarios are also added (chapter 9), and they must be written before the approval: a scenario is not added to an
approved CSC. The last lines of the file become:

```
  GUARANTEE g3a DETAILS g3: VERBAL "The warning arrives 5 s before switch-off, with a tolerance of 1 s"
                            VERIFY BY JUDGEMENT "a person on the stairs who measures with a stopwatch the time between the warning and switch-off"
  ASSUME    a1: VERBAL "Whoever presses the button holds it down for at least a tenth of a second"
                VERIFY BY JUDGEMENT "a person who observes how the button is pressed"

  SCENARIO s1 EXPECT ADMITTED
    @0 s     premuto    accesa = true
    @85 s    avviso
    @90 s    accesa = false
  SCENARIO s2 EXPECT REJECTED
    @0 s     premuto    accesa = true
    @30 s    accesa = false
END
```

Scenario `s1` must be admitted: the light switches off 90 seconds after the press, with the warning 5 seconds
before. Scenario `s2` must be rejected: the light switches off after 30 seconds, in contrast with `g2a`.

```
$ bcdd check --strict UsoLuce.csc
bcdd check --strict UsoLuce.csc
lines: 33 (recognised 28, comments 1, blank 4, unrecognised 0)
blocks: 1
  line 3: CSC UsoLuce VERSION 0.1, STATUS HYPOTHESIS

1. ERRORS: 0
…
4. PENDING APPROVAL, NOT CONTRACT: 7
  line 11: GUARANTEE g1
  line 13: GUARANTEE g2
  line 15: GUARANTEE g2a
  line 17: GUARANTEE g2b
  line 19: GUARANTEE g3
  line 21: GUARANTEE g3a
  line 23: ASSUME a1
…
outcome: no errors
```

### The approval

The building manager examines the CSC and approves it with the decision `D-1`, noted in the register
of decisions. `bcdd ratify` records the approval in the file (chapter 7):

```
$ bcdd ratify UsoLuce.csc --all D-1
approved with D-1 in CSC UsoLuce: 4 lines
  line 4: CSC UsoLuce
  line 15: GUARANTEE g2a
  line 17: GUARANTEE g2b
  line 21: GUARANTEE g3a
contract: 7
```

The command modifies four lines: the header and the three details. A detail does not follow the `STATUS`
of the header (chapter 8), so each one is assigned its own, including `g3a`, which had none. The other contractual
lines take that of the header. In the output of `bcdd ratify` the line number is that of the
modified line: for the header it is the `STATUS` line (line 4), whereas the report of `bcdd check` indicates the
`CSC` line (line 3). The final report confirms the approval:

```
$ bcdd check --strict UsoLuce.csc
bcdd check --strict UsoLuce.csc
lines: 33 (recognised 28, comments 1, blank 4, unrecognised 0)
blocks: 1
  line 3: CSC UsoLuce VERSION 0.1, STATUS RATIFIED BY D-1

1. ERRORS: 0
…
4. PENDING APPROVAL, NOT CONTRACT: 0
…
outcome: no errors
```

The CSC is now the contract between the building manager and whoever implements the light.

### After the approval

Approved lines are not modified. A later modification, for example a different on-time, is
written in a new version, to be approved again (chapter 10). When the system becomes more complex, the
description is divided into several CSCs, one per boundary, and the entity is introduced (chapters 11-13). The guarantees that a program must be able to check are
written as formulas (chapters 21-23).

### What the program does not do

`bcdd` checks the form of files and writes to a file only when a command provides for it. In particular:

- **it does not judge whether a guarantee is correct.** `no errors` indicates a correctly written file: the skeleton
  with the purpose “to be filled in” passes the check just like the complete CSC. The content of the guarantees is the responsibility of whoever
  writes them and whoever approves them (chapter 2);
- **it does not interpret the text in quotation marks.** If in scenario `s1` the light switches off after 30 seconds, with
  the warning at 25, the report does not change, even though the scenario contrasts with `g2a`. `bcdd` checks the names used in
  scenarios and the order and units of their times, but does not compare the scenarios with the guarantees written in words (chapter 9). Nor does it associate the
  name of a constant with the text of the guarantees (chapter 8);
- **it does not compare two versions of the same CSC.** It reads one file at a time and does not detect the differences
  with respect to the previous version; the comparison is carried out with version control tools, before
  approving (chapter 10);
- **it does not approve.** `bcdd ratify` records a decision already taken by whoever has the authority to take it; neither
  `bcdd` nor the language model approves a line (chapter 7);
- **it does not write without confirmation.** `bcdd refine` modifies the file only with the final confirmation, and never
  replaces an approved line (chapter 8);
- **it does not verify the built system.** Guarantees are verified on a real system with the recordings and the
  verification plan (chapters 24 and 26), which `bcdd` does not execute;
- **it does not evaluate formulas**: it checks their form, names and types, but does not establish whether the scenarios have the declared outcome
  or whether the guarantees can hold together. The report lists these checks as not executed
  (chapter 24). Appendix B lists what `bcdd` does not check.

### Summary

- The complete procedure is: `bcdd new` for the skeleton, the draft by hand, `bcdd check --strict` after every
  modification, `bcdd refine` for the questions on the vague points, the scenarios before the approval, `bcdd ratify` after
  the decision.
- Each proposal of the language model is accepted or discarded; it enters the file as a line pending approval.
- After the approval every modification requires a new version.
- `bcdd` checks the form and does not judge the content, does not compare versions and does not approve.

---

## Appendix A — Keywords, in the order in which they are introduced

The table lists the words of the language in the order of the chapters, with the chapter in which each is
described and its use. It comprises the keywords, the operators, the names of the basic types, the time
units and the reserved lower-case words. `bcdd` recognises all the words of the table. The complete list of
reserved words follows the table.

| Word | Ch. | Use |
|---|---|---|
| `CSC` … `END` | 2 | opens and closes the description of a boundary |
| `--` | 2 | comment, ignored by the program |
| `VERSION` | 2 | version number of a CSC or of an entity |
| `PURPOSE` | 2 | purpose: in one sentence, what the boundary is for |
| `EVENT IN` | 2 | input event: what arrives at the boundary from the other side |
| `STATE` … `INITIAL` | 2 | state, that is what is observed at the boundary at every instant, with its initial value |
| `Boolean`, `true`, `false` | 2 | logical type (true or false) and its two values |
| `GUARANTEE` | 2 | guarantee |
| `VERBAL` | 2 | guarantee written in words |
| `VERIFY BY JUDGEMENT` | 2 | verification by the judgement of a person |
| `VERIFY BY INSPECTION` | 2 | verification by inspection of a document or a recording |
| `ASSUME` | 3 | assumption: condition on the other side on which the guarantee depends |
| `EVENT OUT` | 4 | output event: what leaves the boundary towards the other side |
| `CAPABILITY` | 5 | request that the other side can make |
| `requested`, `accepted`, `rejected`, `completed`, `failed` | 5 | the phases of the lifecycle of a request |
| `AUTONOMOUS` | 5 | request started by the provider |
| `TYPE` | 6 | named type: list of values or type described in words |
| `:=` | 6 | introduces the content of a named type (`TYPE`) or the value of a named constant (`DEFINE`) |
| `Integer`, `Real`, `String` | 6 | basic types: integers, real numbers, strings |
| `[a .. b]` | 6 | interval of values of `Integer` and `Real` |
| `Duration`, `s`, `ms` | 6 | duration, in seconds or milliseconds |
| `Sequence of`, `Optional` | 6 | sequence of values; value that may be missing |
| `Record`, `ABSENT` | 6, 23 | type with several fields; absence of an `Optional` value |
| `STATUS` | 7 | approval status of the CSC or of a line |
| `HYPOTHESIS` | 7 | pending approval |
| `RATIFIED BY` | 7 | approved, with the decision reference |
| `DETAILS` | 8 | detail: specifies a guarantee or an assumption more precisely |
| `DEFINE` | 8, 23 | named constant; with parameters, function |
| `UNDECIDED` | 8 | undecided number |
| `SCENARIO` | 9 | scenario described instant by instant |
| `@` | 9 | time of an instant of a scenario |
| `EXPECT ADMITTED`, `EXPECT REJECTED` | 9 | the scenario must be admitted, or rejected |
| `GIVEN` | 9 | starting state of a scenario |
| `ENTITY` | 12 | entity: what stands behind one or more boundaries |
| `OFFERS`, `USES` | 12 | boundary that the entity provides, or uses |
| `COMPOSED OF` | 13 | parts list of an entity |
| `[m .. n]` | 16 | multiplicity: minimum and maximum number of copies of a part |
| `VARIANT` | 20 | variant: one of the alternatives of an aspect of the entity, declared with `VARIANT group = choice` |
| `ALWAYS` | 21 | always |
| `EVENTUALLY` | 21 | sooner or later |
| `WHENEVER` … `THEN` | 21 | whenever… then |
| `AT ONCE` | 21 | in the same step |
| `WHILE` | 21 | while |
| `NOT`, `AND`, `OR`, `IMPLIES` | 21 | combination of conditions |
| `=` `<>` `<` `<=` `>` `>=` | 21 | comparisons |
| `+` `-` `*` `/` `^` | 21 | sum, difference, product, quotient, power |
| `IN {` … `}` | 21 | the value is one of those listed |
| `IF` … `THEN` … `ELSE` | 21 | value chosen on the basis of a condition; the expression goes in parentheses |
| `ABS`, `MIN`, `MAX`, `LOG10`, `ROUND`, `FLOOR`, `CEIL` | 21 | mathematical functions |
| `WITHIN` | 22 | within a certain time |
| `TIME SINCE` | 22 | time elapsed since an event |
| `COUNT`, `COUNT` … `IN LAST` | 22 | count of an event, from the start or in an interval |
| `SINCE` | 22 | in `COUNT(e SINCE f)`: count after the last `f` |
| `WITH` | 22 | filter on the parameters of an event |
| `LAST` | 22, 23 | in `IN LAST`; in `LAST(e)`, the last `e` that occurred |
| `REPEAT` … `EVERY`, `FOREVER` | 22 | steps of a scenario that repeat |
| `PREV` | 22 | value of a state in the previous step |
| `NEVER` | 23 | never; shorthand |
| `ONCE` | 23 | occurred at least once; shorthand |
| `CHANGED` | 23 | the state has changed value; shorthand |
| `PRECEDES` | 23 | an event precedes a condition; shorthand |
| `BEFORE`, `AFTER` | 23 | before the first event, from the first event onwards; shorthands |
| `ACCEPTS` … `ONLY WHILE` | 23 | condition for accepting a request; shorthand |
| `ENSURES` | 23 | what holds when a request succeeds; shorthand |
| `RESOLVES` … `WITHIN` | 23 | maximum time of the response to a request; shorthand |
| `REQUIRES` | 23 | condition for making a request, written in an assumption; shorthand |
| `AFTER` … `UNTIL`, `BETWEEN` … `AND`, `FOR AT LEAST` | 23 | shorthands that the manual does not use; for `BETWEEN` and `FOR AT LEAST` the expanded form is not yet defined |
| `TRANSITION` … `->` … `ON` … `WHEN` | 23 | closed set of the transitions of a state; shorthand |
| `DEFINE EVENT` | 23 | derived event |
| `FOR ALL` … `IN` | 23 | for every value of a finite type; shorthand |
| `x[T]`, `.` | 23 | indexed state; field of a record |
| `FOLLOWS` | 23 | state that follows the parameter of an event; shorthand |
| `PRESENT` | 23 | an `Optional` value is present |
| `BINDING` … `END` | 25 | block of the concrete forms of a boundary |
| `BIND` | 25 | concrete form of an element |
| `AS` | 25 | distinguishing name of a `BINDING` block |
| `VERIFICATION` … `END` | 26 | block of the verification plan |
| `MEANS` … `OBSERVES` … `RESOLUTION` | 26 | recording instrument, with the elements it observes and the resolution |
| `USING` | 26 | `BINDING` block through which an instrument observes |
| `TRANSLATES` | 26 | scenario translated into the concrete forms |
| `EXTENSION` | 27 | extension: new form of the language, declared in a profile |
| `KIND`, `LEVEL`, `PARAMS`, `FORM`, `MEANING`, `REDUCES TO`, `SOURCE` | 27 | fields of an extension, with `VERIFY` |
| `PATTERN`, `SCOPE`, `FUNCTION`, `DECLARATION`, `RELATION`, `SCENARIO-FORM` | 27 | values of the `KIND` field |
| `Name`, `Type`, `Event`, `Condition`, `Expression`, `Duration`, `Property` | 27 | categories of the parameters of an extension |
| `PROFILE`, `IMPORT PROFILE` | 27 | profile, and the line with which a block imports it |

### The list of reserved words

The keywords and reserved words number **136**. None can be a name. The language distinguishes
upper and lower case, so `pattern` and `level` are valid names. The words of the CSC, of the entity, of the blocks and of the header:

```
CSC VERSION END STATUS HYPOTHESIS RATIFIED BY PURPOSE CAPABILITY AUTONOMOUS
EVENT IN OUT STATE INITIAL DEFINE UNDECIDED GUARANTEE ASSUME DETAILS VERBAL VERIFY
JUDGEMENT INSPECTION SCENARIO GIVEN EXPECT ADMITTED REJECTED COMPOSED OF
TYPE ENTITY OFFERS USES VARIANT
IMPORT PROFILE BINDING VERIFICATION EXTENSION
```

The words of formulas and scenarios, with the type `Record`:

```
WHILE ALWAYS EVENTUALLY WHENEVER THEN WITHIN AT ONCE REPEAT FOREVER EVERY
AND OR NOT IMPLIES IF ELSE COUNT LAST TIME SINCE PREV WITH ABSENT PRESENT Record
```

The words of shorthands and the mathematical functions:

```
NEVER AFTER BEFORE BETWEEN UNTIL PRECEDES FOR LEAST ACCEPTS ONLY REQUIRES ENSURES RESOLVES
CHANGED TRANSITION ON WHEN FOLLOWS ALL
ABS MIN MAX LOG10 ROUND FLOOR CEIL
```

The fields of an extension, the values of the `KIND` field and the categories of parameters:

```
KIND LEVEL PARAMS FORM MEANING REDUCES TO SOURCE
PATTERN SCOPE FUNCTION DECLARATION RELATION SCENARIO-FORM
Name Type Event Condition Expression Duration Property
```

The words of concrete forms and of the verification plan:

```
BIND AS MEANS OBSERVES RESOLUTION USING TRANSLATES
```

The words of two forms reserved for future use and those of withdrawn forms:

```
REFINED REFINES
FACE LINK MAP REFINEMENT VIEW
```

Finally, in lower case, `true`, `false`, the five names of the lifecycle (`requested`, `accepted`, `rejected`,
`completed`, `failed`) and `_`. The codes `V1`, `V2` and `C1` … `C8` are recognised as codes only in the `VERIFY`
field of an extension; elsewhere they are valid names. The names of the extensions of a profile are not reserved.

---

## Appendix B — What `bcdd` checks

This appendix describes the checks of `bcdd` 1.0-beta, the version used for the examples in the manual. `bcdd
check` classifies what it reads in three ways:

- an **error** is a form that the program recognises but that is not written correctly; it appears in section
  1 of the report (`ERRORS`) with a code in square brackets, makes the command end with exit code 1 and prevents `bcdd ratify`;
- an **unrecognised line** is a line that does not correspond to any form of the language; it appears in section 5, it is not an
  error, and with `--strict` it makes the check fail and prevents `bcdd ratify` (chapter 2);
- everything else is recognised and appears in the other sections of the report.

### Errors

The messages shown come from test files: the names that appear in them (`P`, `g1`, `A`, …) are those used in those
files, and in real cases they change. The column “Ch.” indicates the chapter in which the error appears in an example; a
dash indicates an error that the manual does not show. There are forty errors, from E01 to E40.

| Code | When it arises | Message | Ch. |
|---|---|---|---|
| E01 | two elements of the same block have the same name: two guarantees, a value and a state, two parameters, two parts, two fields of a record; two blocks with the same name in the same file | `name already used at line 5: g1` | 2 |
| E02 | `DETAILS` names a line that does not exist in the block or that is not of the expected kind: a guarantee or an assumption for a contractual line, a `DEFINE` for a `DEFINE`, a scenario for a scenario | `DETAILS names an id that is neither a GUARANTEE nor an ASSUME of this CSC: g9` | 8 |
| E03 | a scenario names an undeclared event, state, request or parameter; a value that does not belong to any list of values of the block | `name not declared as EVENT: f`; `name not declared as a parameter of e: b`; `name not declared as a value of TYPE: z` | 6, 23 |
| E04 | `STATUS RATIFIED` without `BY` and the decision reference | `STATUS RATIFIED without a decision: BY D-number is needed` | 7 |
| E05 | the details are circular, including when a line is a detail of itself | `circular DETAILS: g1 -> g1` | 8 |
| E06 | an open string is not closed before the end of the file | `unclosed string: the file ends inside the string opened here` | — |
| E07 | a block without `END`, because the file ends or another block begins | `unclosed block: END of CSC P is missing`; `unclosed block: END of CSC Comando is missing` | 25 |
| E08 | an `END` line that does not close any open block | `END without an open block` | 25 |
| E09 | a line that begins with `CSC`, `ENTITY`, `BINDING`, `VERIFICATION`, `PROFILE`, or with `EXTENSION` in a profile, and does not have the expected form | `invalid header: CSC Name VERSION number expected`; `invalid header: BINDING CSCName VERSION number [AS name] expected` | — |
| E10 | a CSC, an entity or a profile without `PURPOSE`, or with two; two `STATUS` lines in the header | `PURPOSE missing in CSC P`; `PURPOSE missing in PROFILE Senza`; `PURPOSE repeated: the first is at line 2`; `STATUS repeated: the first is at line 5` | 2, 27 |
| E11 | the file contains no CSC, entity, `BINDING`, `VERIFICATION` or profile; the message is preceded by `file:` instead of the line number | `the file contains no CSC` | — |
| E12 | in a scenario the time of an instant decreases, or the scenario mixes instants with and without a time unit | `the time of the step decreases: @3 s after @5 s`; `steps with and without a time unit in the same SCENARIO` | 9 |
| E13 | a guarantee or an assumption in words without the `VERIFY` line | `VERBAL without VERIFY: VERIFY BY JUDGEMENT or INSPECTION and a string are needed` | 2 |
| E14 | in an entity, a part uses a boundary that no other part provides and that the entity does not use from outside | `the part pb uses connector B: no other part of E14 provides it, nor does E14 use it from outside` | 13 |
| E15 | a line that begins with `REFINEMENT`, a withdrawn form | `REFINEMENT VIEW has been withdrawn: a decomposition is written with ENTITY` | — |
| E16 | a boundary that the entity provides and that no part provides, or that the entity uses and that no part uses | `the public connector C of E16 (provided) is not assigned to any part` | 13 |
| E17 | a part provides a boundary that no other part uses and that the entity does not provide to the outside | `the part pa provides connector A: no other part of E17 uses it, nor does E17 provide it from outside` | 13 |
| E18 | an `ASSUME`, `CAPABILITY`, `EVENT`, `STATE`, `DEFINE` or `TYPE` line appears in an entity | `ASSUME cannot appear in an entity: write it in the CSC of one of its connectors` | 12 |
| E19 | the number of copies of a part is not valid | `the part pa has an invalid number of copies: [2 .. 1]. Write [minimum .. maximum] with two integers: the minimum 0 or more, the maximum at least 1 and not smaller than the minimum` | 16, 19 |
| E20 | in a scenario or in an entity formula, a name preceded by a boundary that the entity neither provides nor uses; in a CSC, a name preceded by a boundary | `B.x: E20 neither provides nor uses connector B; a scenario can cite only the connectors of E20`; `B.x: in a CSC, names are not written with the connector in front. The order of two connectors is written in a SCENARIO of the entity` | 11, 18, 21 |
| E21 | `VARIANT` in a CSC, or written without `=` or without a choice; `PURPOSE` inside a variant segment | `VARIANT cannot appear in a CSC: variants are written in an entity`; `VARIANT badly written: VARIANT group = choice is needed`; `PURPOSE cannot appear in a VARIANT segment: write it before the first VARIANT` | 20 |
| E22 | a group with a single choice, a choice written twice, a variant segment without lines | `choice group a has a single choice (b): at least two are needed; a part that may be missing is written with [0 .. 1]`; `the choice a = b is already written at line 3`; `the VARIANT segment a = b is empty: a choice without lines is written with a part [0 .. 1]` | 20 |
| E23 | an entity with more than 64 compositions | `entity E23 has more than 64 compositions: bcdd does not check them one by one. Remove a choice, or divide the entity into smaller entities` | 20 |
| E24 | in a formula, in a `DEFINE`, in a `FOLLOWS` line or in the use of an extension: an undeclared name, or one of a kind different from the one the position requires; a field that the record does not have; a function call with incorrect arguments; in an entity, a name without the boundary in front | `name not declared: premuta`; `name not declared as a field of Tocco: stanza`; `the argument valore is missing in the call to vicino`; `accesa is not an event: an EVENT, a DEFINE EVENT or a phase of a CAPABILITY is needed` | 21, 23 |
| E25 | an expression of a type not admitted in its position; a value written in `INITIAL`, in the `GIVEN`, in an assignment or in an argument that is not of the declared type | `inconsistent type: Duration needed, Integer found`; `value not of type Modo: false`; `value not of type Percentuale: 120` | 6, 22, 23 |
| E26 | `AND` and `OR` mixed without parentheses; two `IMPLIES`, two comparisons or two `^` in a row without parentheses | `AND and OR together without parentheses: write (a AND b) OR c, or a AND (b OR c)`; `chained comparisons: write a <= b AND b <= c` | 21 |
| E27 | a formula keyword nested in another; two scopes in the same property; `WITHIN` and `AT ONCE` together; `REQUIRES` in a guarantee | `ALWAYS inside another form: the language does not nest ALWAYS, EVENTUALLY, WHENEVER and their shorthands`; `a property has a single scope: AFTER is the second`; `REQUIRES is used only in an ASSUME: in a GUARANTEE write ALWAYS (requested(X) IMPLIES c)` | 21, 23 |
| E28 | `DEFINE`s or named types that name one another circularly | `circular DEFINE: A -> B -> A` | — |
| E29 | the type of an index is not finite; an index on a name that has none; an indexed state written without an index; an index of an inconsistent type | `the type of the index of s is not finite: Real`; `accesa has no index`; `accesa has an index: write accesa[value of Piano]`; `index of clipCount not of type Ch: X` | 23 |
| E30 | in a scenario, a repetition that does not conform to the expected form | `REPEAT repeated in the scenario: the first is at line 6`; `the step @60 s is not shorter than the period of REPEAT: every repeated step has a time smaller than EVERY 60 s`; `REPEAT without steps: the repeated steps are written after the REPEAT line` | 22 |
| E31 | in a `BINDING` or in a verification plan whose bound CSC has been found, an element or a scenario that the CSC does not declare | `spia is not an element of CSC UsoLuce VERSION 0.3`; `TRANSLATES names a scenario that CSC UsoLuce VERSION 0.3 does not have: s9` | 25, 26 |
| E32 | an extension outside a profile | `EXTENSION outside a PROFILE: an extension is declared in a profile` | 27 |
| E33 | a missing or repeated field of an extension, or one with a value that is not admitted; a non-conforming `FORM`; `KIND FUNCTION` without the type of the result; in `VERIFY V1`, a code other than `C1` … `C8` | `field SOURCE is missing in EXTENSION FADE`; `value of KIND not admitted: pattern`; `the parameter d must appear once in FORM` | 27 |
| E34 | two extensions with the same name in the same profile; an extension with the name of a word of the language | `extension name already used at line 3: FADE`; `the name of the extension is a word of the language: ALWAYS` | — |
| E35 | `REDUCES TO` names what is not a word of the language, a parameter or an extension of the same profile; extensions that name one another circularly with `REDUCES TO` | `REDUCES TO names X: it is not a word of the language, a parameter or an extension of PROFILE P`; `circular REDUCES TO: A -> B -> A` | — |
| E36 | `REDUCES TO` repeats a single form of the language or another extension | `EXTENSION MAI repeats a form that the language already has: NEVER` | 27 |
| E37 | a use of an extension that does not respect its `FORM`, its `KIND` or its `LEVEL` | `use of FADE that does not respect FORM "FADE s WITHIN d"` | 27 |
| E38 | a `BINDING` or a verification plan imports a profile in a version different from that of the bound CSC | `PROFILE Protocollo imported with VERSION 0.2, but CSC Comando imports it with VERSION 0.3` | — |
| E39 | a `STATUS` in a verification plan | `STATUS cannot appear in a VERIFICATION: a verification plan is not approved` | 26 |
| E40 | two `BINDING`s for the same CSC and the same version without a distinguishing name, or with the same distinguishing name, in the same file | `second BINDING without a name for CSC Comando VERSION 0.1: the first is at line 13. With two or more BINDINGs, each has a name: AS name` | 25 |

In its messages `bcdd` uses the term “connector” for a CSC cited by an entity and “id” for the short name; the
manual uses “boundary” and “short name”. In the errors of an entity with several
compositions the suffix `(in: …)` indicates the compositions in which the error applies (chapter 19).

Some errors also make the line in which they occur unrecognised, which is therefore also listed in section 5:
E06, E08, E09, E15, E18, E21 and E32; with E32 the lines of the misplaced extension are also unrecognised. The
errors from E24 to E31 and from E33 to E40, by contrast, leave the line recognised: the form is read in full, and the error
indicates what is not correct.

`bcdd` reports an error only when it can establish it with certainty. If a check depends on a cited file that is not found (a bound
CSC, the CSC of a qualified name, an imported profile), the check is suspended and the citation appears in
section 7.

### What appears in the report without being an error

| Section | What it lists | Ch. |
|---|---|---|
| 2. DEGREE OF THE CONTRACTUAL LINES | for each contractual line, the degree: verbal, formal, declared extension or unrecognised | 2, 21, 27 |
| 3. UNDECIDED | the undecided numbers | 8 |
| 4. PENDING APPROVAL, NOT CONTRACT | the lines pending approval: contractual lines, details of `DEFINE`s and of scenarios, `BIND` lines, extensions of a profile pending approval | 2, 7, 25, 27 |
| 5. UNRECOGNISED LINES | the lines that `bcdd` does not recognise, with the reason if it depends on a profile not found; with `--strict` they make the check fail | 2, 27 |
| 6. UNDECLARED TYPES | the types used without a `TYPE` line | 6 |
| 7. CSCs NAMED BUT NOT CHECKED | the CSCs, parts, `BINDING` blocks and profiles cited that `bcdd` has not found | 12, 13, 27 |
| 8. USES WITHIN ENTITIES | for each part, what provides each boundary that the part uses | 13 |
| 9. COMPOSITIONS | the compositions of an entity that has more than one | 19, 20 |
| 10. DECLARED ABSENCES | what is missing only because an optional part is missing | 19 |
| 12. MISSING CONCRETE FORMS | for each `BINDING`, the elements of the bound CSC without a `BIND` line | 25 |
| 13. VERIFICATION PLAN COVERAGE | for each verification plan, the formal guarantees observed by each instrument and those not executed | 26 |
| 14. TO BE JUDGED | the rules that require human judgement: the consistency of a detail with a line in words, the meaning rules of extensions | 8, 21, 27 |
| 15. CHECKS NOT EXECUTED | the checks on formulas that `bcdd` does not execute, with the lines to which they would apply | 21, 24 |

Sections 8, 9, 10 and 12-15 appear only when they are needed. Number 11 is not used.

With the option `--json`, `bcdd check` writes instead of the report a JSON object, with `"forma": "bcdd-check"` and
`"versione": 5`, which contains the same information.

### The messages of the commands

In the following cases the command stops with a single-line message, without an error code in square brackets
such as `[E03]`, ends with an exit code other than 0 and does not modify any file:

| Message | When | Ch. |
|---|---|---|
| `bcdd check: file not found: nessuno.csc` | the file indicated does not exist | — |
| `bcdd new: UsoLuce.csc already exists: I am not overwriting it` | a file with the same name already exists | 7 |
| `bcdd ratify: the file does not pass bcdd check --strict (errors: 1, unrecognised lines: 0): I am not approving` | the file has errors or unrecognised lines | 7 |
| `bcdd ratify: g1 is already part of the contract (line 11): I am changing nothing` | the line indicated is already approved | 7 |
| `bcdd ratify: invalid decision: D7 (D-number is needed)` | the decision reference does not have the form `D-` followed by digits | 7 |
| `bcdd ratify: in a BINDING the header or --all is approved, not a line` | a line of a `BINDING` is indicated; for a profile the message indicates that the whole profile is approved | 25 |
| `bcdd ratify: the BINDING Comando VERSION 0.1 is already approved (D-21): I am changing nothing` | the chosen `BINDING` or profile is already approved | 25 |
| `bcdd ratify: no block to approve with the name NAME in the file` | no CSC, entity, profile or `BINDING` has the name indicated with `--csc` | — |
| `bcdd ratify: the file contains no block to approve: a VERIFICATION is not approved` | the file contains only verification plans | 26 |

### What `bcdd` does not check

- the meaning of formulas: it does not establish whether a scenario has the outcome it declares, whether every trigger occurs in
  a scenario, whether guarantees and assumptions can hold together, whether a formal detail is consistent with the line it
  specifies; these are the checks of section 15 (chapters 21 and 24);
- the rules by judgement: the consistency of a detail with a line in words and the meaning rules of
  extensions; these are the entries of section 14 (chapters 8 and 27);
- recordings: `bcdd` does not read recorded traces, and section 13 indicates which guarantees an instrument observes, not
  whether they are satisfied (chapter 26);
- the values of constants, and whether the name of a constant cited in the text of a guarantee exists (chapter 8);
- the limits of an interval, which it does not compare with each other (chapter 6);
- unknown types: a value of a type described in words, of an undeclared type or of an `UNDECIDED`
  constant; in entity scenarios a value that is a name; in entity formulas the type of the elements of the
  cited CSCs (chapters 18 and 21);
- the uses of extensions of `KIND RELATION` and `KIND SCENARIO-FORM`, which it leaves unrecognised (chapter 27);
- what changes between two versions of the same CSC (chapter 10).

Lines with keywords written in lower case (chapter 2) and the line
`STATUS RATIFIED BY` in the header of an entity (chapter 12) also remain unrecognised. A duration with a unit other than `s` and `ms`,
for example `1 min`, does not belong to the language (chapters 6 and 8): the line that contains it is an unrecognised
line.

No program described in the manual executes recording verification (chapter 24) or a verification plan
(chapter 26).

---

## Appendix C — Glossary

This appendix collects the terms that the manual uses with a particular meaning. For each it indicates the
chapter in which the term is introduced and the definition, which applies throughout the manual. At the end are listed
the terms of the language specification that the manual does not use, or uses in a narrower sense.

| Term | Ch. | Definition |
|---|---|---|
| system (sistema) | 1 | what is described, of any size: an installation, a program, a device |
| boundary (confine) | 1 | interface between a system and a person or another system, through which what passes between the two is observed |
| side (lato) | 1 | each of the two counterparts of a boundary; in the example, the person on the stairs and the installation |
| black box (scatola nera) | 1 | system of which only what goes in and what comes out is known |
| guarantee (`GUARANTEE`) (promessa) | 1, 2 | what one side of the boundary guarantees to whoever is on the other side; it concerns only what is observed at the boundary |
| verification (`VERIFY`) (controllo) | 1, 2 | indication of who verifies that a guarantee is satisfied, and in what way |
| pending approval (`STATUS HYPOTHESIS`) (da approvare) | 1, 7 | status of a contractual line, or of the CSC, not yet approved, freely modifiable; in the report of `bcdd` it appears under `PENDING APPROVAL, NOT CONTRACT` |
| approved (`STATUS RATIFIED BY`) (approvata) | 7 | status of a contractual line, or of the CSC, approved by whoever has the authority, with the decision reference; from that moment it can no longer be modified |
| part (parte) | 1, 13 | smaller system contained in a larger system; in BCDD, entity contained in another entity |
| language model (modello linguistico) | 1 | program, trained on large amounts of text, that generates text and code from instructions written in natural language |
| implement, implementation (realizzare, realizzazione) | 1 | to build the system that keeps the guarantees; the built system, with its internal choices |
| behaviour (comportamento) | 1 | what is observed from outside: what goes in, what comes out and when |
| contract (contratto) | 1 | set of the approved guarantees and assumptions on a boundary |
| BCDD | 1 | language for specifying the behaviour of a system through its boundaries; acronym of *Behavioural Contract-Driven Design*, design driven by contracts on behaviour |
| CSC | 1, 2 | written description of a boundary, contained in a `.csc` file; acronym of *Capability State Contract* |
| comment (`--`) (commento) | 2 | note for the reader, ignored by the program |
| version (`VERSION`) (versione) | 2, 10 | number that identifies a draft of the CSC; it changes when the contract changes |
| keyword (parola chiave) | 2 | fixed word of the language, in English and in upper case |
| purpose (`PURPOSE`) (scopo) | 2 | sentence that indicates what the boundary is for |
| event (evento) | 2 | what happens at an instant and is then over |
| input event (`EVENT IN`) (evento in ingresso) | 2 | event that arrives at the boundary from the other side |
| state (`STATE`) (stato) | 2 | element visible at the boundary that always has a value |
| type (tipo) | 2, 6 | set of the values that a state or a datum can take |
| `Boolean` | 2 | logical type, with the values true (`true`) and false (`false`) |
| initial value (`INITIAL`) (valore iniziale) | 2 | value of a state at system start-up; mandatory |
| short name (nome breve) | 2, 3, 9 | name assigned to a contractual line or to a scenario in order to cite it (`g1`, `a1`, `s1`) |
| in words, verbal (`VERBAL`) (a parole, verbale) | 2 | guarantee written in a natural language, in quotation marks; “verbal” is the name of the corresponding degree, in the sense of “made of words” |
| string (stringa) | 2 | text in quotation marks |
| by judgement (`BY JUDGEMENT`) (a giudizio) | 2 | verification in which a person carries out a test and judges |
| by inspection (`BY INSPECTION`) (per ispezione) | 2 | verification that consists in examining an existing document or recording |
| `bcdd` | 2 | command-line program that creates and checks `.csc` files, submits them to a language model and records the approval of lines (chapter 29) |
| `bcdd check` | 2 | command that checks the form of a file without modifying it |
| option (opzione) | 2 | addition to a command that modifies its behaviour |
| `--strict` | 2 | option that makes the check fail even for a single unrecognised line |
| block (blocco) | 2 | description contained in the file, from the line that opens it (`CSC`, `ENTITY`, `BINDING`, `VERIFICATION`, `PROFILE`) to `END` |
| report (rapporto) | 2 | text printed by `bcdd check`, divided into numbered sections |
| error (errore) | 2 | form that the program recognises but that is not written correctly |
| unrecognised line (riga non riconosciuta) | 2 | line that does not correspond to any form of the language; it is not an error, but it is always reported |
| contractual line (riga contrattuale) | 2 | line that enters the contract once approved: a guarantee and, from chapter 3, an assumption |
| degree (grado) | 2, 21, 27 | way in which a guarantee is written, on which the way it is verified depends: verbal, formal or declared extension |
| outcome (esito) | 2, 5, 24 | (1) last line of the report of `bcdd check`: `no errors` does not mean that the guarantees are correct (chapter 2); (2) result of a request, succeeded or failed (chapter 5); (3) result of the verification of a guarantee (chapter 24) |
| assumption (`ASSUME`) (presupposto) | 3 | condition on the other side on which the guarantee depends; if it is not satisfied, the guarantee is not violated |
| provider (chi offre) | 4, 12 | side of the boundary that keeps the guarantees; the CSC is written from its side |
| consumer (chi usa) | 4, 12 | side of the boundary that satisfies the assumptions and relies on the guarantees |
| output event (`EVENT OUT`) (evento in uscita) | 4 | event that the provider sends towards the other side |
| request (`CAPABILITY`) (richiesta) | 5 | what the consumer can ask of the provider; it has a response (accepted or rejected) and an outcome (succeeded or failed) |
| response (risposta) | 5 | first conclusion of a request: accepted or rejected |
| lifecycle (`requested`, `accepted`, `rejected`, `completed`, `failed`) (ciclo di vita) | 5, 9 | the five names of the phases of a request; they fix the order of the phases, not the obligations |
| autonomous request (`AUTONOMOUS`) (richiesta autonoma) | 5 | request started by the provider without the other side requesting it; it has neither `requested` nor `rejected` |
| parameter (parametro) | 5, 6 | value that accompanies an event or a request |
| list of values (enumeration) (elenco di valori, enumerazione) | 6 | type consisting of a list of named values |
| interval (`[a .. b]`) (intervallo) | 6 | limits of the values admitted for an `Integer` or `Real` type |
| type described in words (`TYPE … := VERBAL`) (tipo descritto a parole) | 6 | type with a name and a description in quotation marks, which the program does not interpret |
| undeclared type (tipo non dichiarato) | 6 | type used without a `TYPE` line; it is not an error, and it is listed in section 6 of the report |
| decision reference (riferimento della decisione) | 7 | identifier with which the approval decision is recorded; required by `bcdd ratify` |
| header (intestazione) | 7, 12 | the `CSC` or `ENTITY` line and the lines that follow it before the body, in any order: `PURPOSE`, the optional `STATUS`, the optional `IMPORT PROFILE`. In a CSC the `STATUS` of the header applies to the lines that do not have their own; in an entity only `STATUS HYPOTHESIS` is admitted. In the other blocks (chapters 25-27) the header comprises `STATUS` and `IMPORT PROFILE` in a `BINDING`, only `IMPORT PROFILE` in a verification plan, `PURPOSE` and `STATUS` in a profile |
| `bcdd new` | 7 | command that creates the skeleton of a `.csc` file |
| `bcdd ratify` | 7 | command that records the approval of one contractual line or of all of them, of a `BINDING` or of a profile, modifying only the `STATUS` lines |
| detail (`DETAILS`) (dettaglio) | 8 | line that expresses a guarantee or an assumption more precisely, without replacing or contradicting it |
| named constant (`DEFINE`) (costante con nome) | 8, 23 | value, or expression, to which a name is assigned for use in the CSC |
| to be judged (da giudicare) | 8 | section 14 of the report: rules that require human judgement, such as the consistency of a detail with a line in words; they are not errors |
| undecided number (`UNDECIDED`) (numero non deciso) | 8 | missing number; the program lists it until it is decided |
| `bcdd refine` | 8 | command with which the language model asks questions and proposes lines, always pending approval |
| level (livello) | 8 | number of `DETAILS` steps that separate a line from a line without `DETAILS`; `bcdd refine` does not propose beyond level 2 |
| declaration (dichiarazione) | 8, 9 | line that declares an element of the CSC (`TYPE`, `CAPABILITY`, `EVENT`, `STATE`, `DEFINE`, `SCENARIO`). It does not have its own `STATUS` and takes that of the header. The exceptions are details of `DEFINE`s and of scenarios, which are pending approval like every detail |
| dialogue file (`.dialogo`) (file del dialogo) | 8 | file next to the CSC in which `bcdd refine` keeps questions and answers |
| scenario (`SCENARIO`) (storia) | 9 | sequence of instants that the guarantees of the CSC must admit or reject |
| instant of a scenario (`@`) (istante di una storia) | 9 | line of a scenario that indicates a time and what happens or is observed at that instant |
| assertion in words (`VERBAL` in a scenario) (asserzione a parole) | 9 | description in words of an instant; it does not require `VERIFY` |
| admitted, rejected (`EXPECT ADMITTED`, `EXPECT REJECTED`) (ammessa, respinta) | 9 | indication of whether the scenario satisfies the contract or violates it |
| starting state (`GIVEN`) (stato di partenza) | 9 | values of the states at the start of a scenario, when they are not the initial ones |
| new version (versione nuova) | 10 | way of changing an approved contract: it is rewritten with a new number |
| entity (`ENTITY`) (entità) | 12 | system that stands behind one or more boundaries; it is described by the boundaries it provides and those it uses; the description does not indicate where it is located |
| entity guarantee (promessa d'entità) | 12 | guarantee that links two or more boundaries of the same entity and that none of the CSCs can express on its own |
| connector (connettore) | 12 (note), App. B | term used by `bcdd` in its messages for a CSC cited by an entity |
| provides (`OFFERS`) (offre) | 12 | line of an entity that indicates a boundary that the entity provides |
| uses (`USES`) (usa) | 12 | line of an entity that indicates a boundary that the entity uses |
| citation (citazione) | 12 | line of an entity, of type `OFFERS`, `USES` or part, that indicates a CSC or an entity; `bcdd` looks for it and shows its version, `STATUS` and outcome |
| every used boundary is offered (chi usa trova chi offre) | 13 | rule by which, inside an entity, every boundary used by a part is provided by another part or is an external boundary, that is a boundary that the entity itself uses |
| parts list (`COMPOSED OF`) (elenco delle parti) | 13 | the `COMPOSED OF` line and the lines of the parts that follow it |
| part name (nome della parte) | 13 | name of the role of a part in the entity (`pulsante`), distinct from the name of the entity that describes it (`Pulsante`) |
| internal boundary (confine interno) | 13 | boundary between two parts of an entity, which the entity neither provides nor uses; it is not observable from outside |
| public boundary (confine pubblico) | 13 | boundary that an entity provides or uses towards the outside |
| external boundary (confine esterno) | 14 | boundary that a part uses and that no part of the entity provides; it is declared on the entity with `USES` |

| closure, closed entity (chiusura, entità chiusa) | 13 | property of an entity with parts that respects the rule “every used boundary is offered” and the two rules that complete it (E16, E17); `bcdd` checks it with errors E14, E16 and E17 |
| `--dir` | 13, 15 | option that indicates to `bcdd` a folder in which to look for cited files; it can be repeated, and the folders are examined in the order in which they are indicated |
| channel (canale) | 14 | medium that can lose, delay or reorder what it carries; its behaviour is described in a boundary with its own CSC |
| indicated version (versione indicata) | 15 | version written after the name of the CSC in an `OFFERS` or `USES` line. A `USES` line without a version matches any `OFFERS` line. An `OFFERS` line without a version does not match a `USES` line that indicates one |
| match (corrispondenza, corrispondere) | 15 | relation between a `USES` line of a part and an `OFFERS` line of another part, or a `USES` line of the entity, with the same name, when the versions respect the rules of chapter 15 |
| copy (copia) | 16 | instance of a part contained in an entity; every copy keeps all the guarantees of the part |
| multiplicity (`[m .. n]`) (molteplicità) | 16 | indication of the minimum and maximum number of copies of a part; without a multiplicity the part has one copy |
| neighbouring part (parte vicina) | 17 | another part of the same entity that cites one of the same CSCs |
| excessive division (divisione eccessiva) | 17 | division into parts beyond what is necessary; a sign of it is an entity with a single part that provides and uses the same boundaries |
| entity scenario (storia d'entità) | 18 | scenario written on an entity, in which every name is preceded by the name of the CSC it comes from |
| qualified name (`Csc.nome`) (nome qualificato) | 18 | name of an element preceded by the name of the CSC and by a dot, used in entity scenarios |
| optional part (parte facoltativa) | 19 | part that whoever composes the system decides whether to install; the choice is made before the system is used and does not change |
| composition (composizione) | 19, 20 | each of the complete forms in which an entity can be assembled; each one is checked separately |
| declared absence (assenza dichiarata) | 19 | what is missing only because an optional part is missing; it is not an error, and `bcdd` lists it in section 10 |
| suffix `(in: …)` (suffisso) | 19 | indication, in the report, of the compositions in which an error or an entry applies |
| variant (`VARIANT`) (variante) | 20 | one of the alternatives of an aspect of the entity, declared with `VARIANT group = choice` |
| choice (scelta) | 20 | name to the right of the `=` sign in a `VARIANT` line |
| segment (segmento) | 20 | lines of a variant, from the `VARIANT` line to the next one or to `END`; they apply only with that choice |
| common lines (righe comuni) | 20 | lines of an entity that precede the first `VARIANT`; they apply in every composition |
| choice group (gruppo di scelte) | 20 | set of alternative choices with the same group name (to the left of the `=` sign), of which only one applies in each composition |
| formula (formula) | 21 | guarantee written in a form that a program can check step by step; it has no `VERIFY` |
| step (passo) | 21 | unit of observation: the events that occur at an instant and the values of the states immediately after. Several consecutive steps can have the same instant. Every line of a scenario that begins with `@` is a step |
| trace (traccia) | 9, 21 | sequence of steps, written in a scenario or recorded on a built system |
| condition on the step (condizione sul passo) | 21 | expression that in every step is true or false: an event, a comparison, a phase of a request, combined with `NOT`, `AND`, `OR`, `IMPLIES` |
| precedence (precedenza) | 21 | order in which the operators of a formula without parentheses are applied; ambiguous combinations require parentheses (error E26) |
| open line (riga aperta) | 21 | line that ends with an operator or a keyword that requires a continuation, or with an unclosed parenthesis; it therefore continues on the next line |
| checks not executed (controlli non eseguiti) | 21, 24 | section 15 of the report: the checks on formulas that `bcdd` does not execute, with the lines to which they would apply |
| always (`ALWAYS`) (sempre) | 21 | the condition holds in every step |
| sooner or later (`EVENTUALLY`) (prima o poi) | 21 | the condition holds in at least one step |
| whenever… then (`WHENEVER … THEN`) (ogni volta che… allora) | 21 | in every step in which the trigger holds, the consequence must hold in the same step or in a later step |
| trigger, consequence (innesco, conseguenza) | 21 | the two conditions of `WHENEVER … THEN`: the first, when it holds, requires the second to hold; the trigger is also the part `p` of `ALWAYS (p IMPLIES q)` and the condition that opens `WHILE` (chapter 24) |
| in the same step (`AT ONCE`) (nello stesso passo) | 21 | the consequence holds in the very step of the trigger |
| while (`WHILE`), scope (mentre, ambito) | 21 | `WHILE c: P`: the formula `P` must hold in the steps in which `c` holds, which form the scope of `P`; each continuous stretch in which `c` holds is a scope of its own; without `WHILE` the scope is the whole trace |
| formal (formale) | 21 | degree of a guarantee written as a formula or with a shorthand, which `bcdd` reads in full; it indicates how the guarantee can be verified, not that it has been verified |
| time limit (`WITHIN`) (limite di tempo) | 22 | duration within which the condition of `EVENTUALLY` or the consequence of `WHENEVER` must hold |
| elapsed time (`TIME SINCE`) (tempo trascorso) | 22 | time passed since the last step in which an event occurred; 0 in the step of the event, infinite before the first event (only in comparisons) |
| count (`COUNT`, `COUNT … SINCE`, `COUNT … IN LAST`) (conteggio) | 22 | number of steps in which an event occurred. `COUNT` counts from the start of the trace. `COUNT … SINCE` counts after the last step of another event. `COUNT … IN LAST d` counts in the interval of duration `d` that ends with the step considered: this step is included, the step exactly `d` away is excluded |
| filter (`WITH`) (filtro) | 22 | condition on the parameters of an event or of a phase of a request |
| repetition (`REPEAT … EVERY`) (ripetizione) | 22 | steps of a scenario that follow the `REPEAT` line and repeat with a period, from a minimum to a maximum number of times or without end |
| previous value (`PREV`) (valore precedente) | 22 | value of a state in the previous step; in the first step, the initial value |
| shorthand, short form (abbreviazione, forma breve) | 23 | form that expands into an equivalent formula written with the keywords of chapters 21 and 22, the expanded form; its meaning is only that of the expanded form |
| expanded form (forma estesa) | 23 | formula equivalent to a shorthand, written with the keywords of chapters 21 and 22; the shorthand is said to “expand” into its expanded form |
| closed set of transitions (`TRANSITION`) (insieme chiuso di transizioni) | 23 | guarantee that lists all the ways in which a state changes value |
| derived event (`DEFINE EVENT`) (evento derivato) | 23 | name given to a condition on the step, used in a formula like an event; it is not written in the steps of scenarios |
| function (`DEFINE` with parameters) (funzione) | 23 | expression with typed parameters, used with the arguments written by name |
| named type (`TYPE … := Type`) (tipo con nome) | 23 | name given to a type, valid throughout the block |
| record (`Record`) (record) | 23 | type made of named fields; `x.campo` names one of its fields |
| indexed state (`STATE x[T]`) (stato con indice) | 23 | one state for each value of a finite type; it is named with `x[valore]` |
| text verification (verifica sul testo) | 24 | checks executed on the CSC, before construction: form, consistency, scenarios, coverage, every used boundary is offered, entity guarantees, details |
| recording verification (verifica sulle registrazioni) | 24 | checks executed on the traces recorded on a built system; no program described in the manual executes it |
| recording (registrazione) | 24 | trace observed at the boundaries of a built system |
| consistency (coerenza) | 24 | existence of at least one trace that satisfies all the assumptions and all the guarantees together |
| coverage (copertura) | 24 | presence, for every guarantee with a trigger, of an admitted scenario in which the trigger occurs |
| realisability (realizzabilità) | 24 | existence of a system that satisfies the guarantees whatever the behaviour of the other side; no check guarantees it |
| satisfied on the trace (rispettata sulla traccia) | 24 | outcome of a formal guarantee never violated in the recorded trace; it gives no indication about the situations not observed (in the specification `SODDISFATTA SULLA TRACCIA`) |
| violated (violata) | 24 | outcome of a formal guarantee whose formula does not hold in a step of the trace; the outcome indicates the step |
| inconclusive (inconclusiva) | 24 | outcome of a formal guarantee that the trace does not allow to be established, because it ends before the outcome can be determined |
| not executed (non eseguita) | 24 | outcome of a formal guarantee on what the recording instrument does not observe |
| conforming by judgement, non-conforming by judgement, not assessed (conforme a giudizio, non conforme a giudizio, non valutata) | 24 | outcomes of a verbal guarantee, with who judged and on what; “not assessed” if nobody has judged |
| assumption not satisfied (presupposto non rispettato) | 3, 24 | outcome that reports the failure of the other side to satisfy an assumption on which the guarantee depends; the guarantee is not violated |
| concrete form (`BINDING`) (forma concreta) | 25 | what someone at the boundary observes or uses of an element of a CSC: a terminal, a text, a colour, a file format. The concrete forms of a boundary are written in a `BINDING … END` block, distinct from the CSC |
| binding (concrete form) (vincolante) | 25 | said of a concrete form observed or used by someone external to the implementation: a person, another program, a third-party system |
| “who sees it?” («chi lo vede?») | 25 | criterion that establishes whether an element enters the CSC, the concrete forms, or remains in the implementation |
| bound CSC (CSC legata) | 25, 26 | CSC named in the header of a `BINDING` or of a verification plan, with its version; `bcdd` looks for it like a cited CSC |
| `BIND` line (riga `BIND`) | 25 | line of a `BINDING` that describes in words the concrete form of an element of the bound CSC |
| distinguishing name (`AS`) (nome distintivo) | 25 | name that distinguishes several `BINDING` blocks of the same CSC; the verification plan uses it with `USING`, `bcdd ratify` with `--csc` |
| missing concrete forms (forme concrete mancanti) | 25 | section 12 of the report: the elements of the bound CSC that no `BIND` line names; they are not errors |
| verification plan (`VERIFICATION`) (piano di prova) | 26 | `VERIFICATION … END` block that indicates the recording instruments of a boundary, with their resolution, and the scenarios in concrete forms; it contains no guarantees and is not approved |
| verification plan coverage (copertura del piano di prova) | 26 | section 13 of the report: for each instrument the formal guarantees it observes in full, and the guarantees not executed |
| recording instrument (`MEANS`) (mezzo di registrazione) | 24, 26 | tool that records what happens at a boundary through the concrete forms of the boundary: a recorder, a sensor, a camera, a program |
| observe (said of an instrument) (osservare) | 26 | to record an element; an element that no instrument records is not observed, and the formal guarantees that cite it are not executed |
| resolution (`RESOLUTION`) (risoluzione) | 26 | the smallest time interval that a recording instrument distinguishes; “satisfied on the trace” applies with the resolution of the instrument |
| translated scenario (`TRANSLATES`) (storia tradotta) | 26 | scenario of the verification plan written with the concrete forms, which translates a scenario of the bound CSC |
| extension (`EXTENSION`) (estensione) | 27 | new form of the language, not to be confused with the extension `.csc` of a file name; it is declared in a profile, with eight fields: `KIND`, `LEVEL`, `PARAMS`, `FORM`, `MEANING`, `REDUCES TO` (optional), `VERIFY`, `SOURCE` |
| meaning (`MEANING`) (significato) | 27 | field of an extension that describes in words the meaning of the form; if `REDUCES TO` is missing, this description applies |
| `REDUCES TO` field (campo `REDUCES TO`) | 27 | optional field of an extension with its expanded form (chapter 23); if present, the extension is a shorthand and the guarantee that uses it has formal degree |
| continuous quantity (`SIGNAL`) (grandezza continua) | 27 | quantity defined at every instant and not only in the steps, declared with the extension `SIGNAL` of the profile `Segnale` |
| profile (`PROFILE`, `IMPORT PROFILE`) (profilo) | 27 | collection of extensions for a field of use, with a name and a version, which a CSC imports with `IMPORT PROFILE`; a profile does not import another |
| category (categoria) | 27 | kind of element that the use of an extension writes in place of a parameter: `Name`, `Type`, `Event`, `Condition`, `Expression`, `Duration`, `Property` |
| place (posto) | 27 | word of the `FORM` equal to the name of a parameter, where the use of the extension writes the argument |
| declared extension (estensione dichiarata) | 27 | degree of a guarantee written with an extension without `REDUCES TO`; it is verified as the `VERIFY` field declares |
| trial word (parola in prova) | 27 | word of the language that a future revision may move into a profile, with the same name and the same meaning; it remains reserved even in the CSCs that do not import the profile |
| direct box (DI) | 28 | device that takes the signal from the output terminals of the amplifier and carries it to the capture card; in the measurement kit it is one of the two choices of the level sensor and, in that choice, an optional part (chapter 19); in the files it is abbreviated to DI |

### Terms that the manual does not use, and why

These are terms of the language specification. The manual does not use them, either because the writer of a
CSC does not need them or because the manual replaces them with a term already defined; whoever consults the specification meets them
under these names.

- **nucleo, BASE** (core, BASE): they divide the words of the language according to the way the program treats them. The
  writer needs to know only that some forms are shorthands (chapter 23).
- **promozione** (promotion), provisional or definitive, and the number of trials: they concern whoever evolves the
  language. The writer needs to know only that some words are “on trial” (chapter 27).
- **Core, Binding, Verification, livelli** (levels): the names of the specification for behaviour, concrete forms and
  the verification plan. The manual uses “behaviour”, “concrete forms” and “verification plan”; `BINDING` and
  `VERIFICATION` appear as keywords of the blocks (chapters 25 and 26) and, with `CSC` and `ENTITY`, as
  values of the `LEVEL` field of an extension (chapter 27). The name “Core” does not appear; “level” remains reserved
  for the number of `DETAILS` steps (chapter 8), with the exception of the `LEVEL` field of an extension.
- **consolidamento, dettaglio dall'alto in basso** (consolidation, top-down detailing): the manual uses “making a guarantee precise”.
- **V1, V2, C1-C8, E1-E7, D1-D6, P1-P9**: codes of the checks, rules and principles of the specification.
  The manual describes in words what they check. The error codes of the report (`E13`…) remain,
  because they appear on the screen; `V1`, `V2` and `C1`-`C8` appear only in the `VERIFY` field of
  an extension (chapter 27).
- **ipotesi, ratifica** (hypothesis, ratification), and **proposta** (proposal) as a status: the manual uses “pending approval” and “approved”; “proposal”
  indicates only what the language model proposes (chapter 8). “Hypothesis” and “ratify” appear only
  to explain the keywords `HYPOTHESIS` and `RATIFIED` and the command `ratify` (chapter 7).
- **condizione, assunzione** (condition, assumption): the names the specification gives to what `ASSUME` declares. The Italian
  edition replaces them with the plain word «presupposto»; this edition uses “assumption”, which matches the keyword (chapter 3),
  and uses “condition” in its ordinary sense.
- **garanzia, garanzia d'entità** (guarantee, entity guarantee): the names the specification gives to what `GUARANTEE` declares.
  The Italian edition replaces them with the plain words «promessa» and «promessa d'entità» and uses «garanzia» only once, to
  gloss the keyword (chapter 2); this edition uses “guarantee” and “entity guarantee”, which match the keyword.
- **parte** (part) for the two sides of a boundary: the manual uses “side”, “provider”, “consumer”; “part” indicates only
  the components of a system.
- **collegamento** (link): the manual does not use this word as a term; for `BINDING` it uses “concrete forms”, and for
  a medium that carries signals or data it uses “channel”.
- **cosa** (thing), and **pezzo** (piece) in the sense of component: for what stands behind a boundary the manual uses
  “system” and “entity”, for the components “part”.
- **faccia, vista di raffinamento, LINK, MAP, REFINES, REFINED BY** (face, refinement view, …): withdrawn forms or forms reserved
  for future use. They cannot be used, so the manual does not describe them.
- **composizione** (composition) in the sense of `COMPOSED OF`: so as not to give two meanings to the same word, the manual
  calls `COMPOSED OF` “the parts list” and uses “composition” only for one of the complete forms of
  an entity with optional parts or variants (chapters 19 and 20).
- **risposta** (response) for the second condition of `WHENEVER … THEN`: “response” indicates the first conclusion of a
  request, accepted or rejected (chapter 5); the manual uses “consequence”.
