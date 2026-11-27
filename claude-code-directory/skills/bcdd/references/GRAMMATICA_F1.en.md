# The BCDD grammar, version 1.0-beta

<!-- SPDX-License-Identifier: CC-BY-4.0 -->
*Copyright 2026 Noli Paolo. Document distributed under the [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.en) licence.*

**BCDD** = *Behavioural Contract-Driven Design* · **CSC** = *Capability State Contract*

**Status**: version 1.0-beta. It describes the form of the `.csc` files that the program `bcdd` reads, the errors it
reports, the report of `bcdd check` and the use of the commands `check`, `new` and `ratify`.

## Contents of the document

The document defines the syntax of CSCs accepted by `bcdd`: `bcdd` accepts, rejects and reports
exactly what is written here. The document does not describe how the program is implemented.

Sections 1-7 define what `bcdd` can read (4.9 entities, 4.10 variants and optional
parts, 4.11 concrete forms, the verification plan, profiles and extensions, 4.12 formulas, 4.13
names and types, 4.14 the use of extensions); section 8 lists the errors; section 9 describes the
report of `bcdd check`, character by character (9.4 entities and citations, 9.5 compositions, 9.6
concrete forms and the verification plan, 9.7 the entries to be judged and the checks not executed); sections 10, 11 and
12 describe the commands `check`, `new` and `ratify`; section 13 describes the dialogue file; section 14 lists
what `bcdd` does not check.

The language, with its examples, is presented in *The BCDD manual*; this document uses its terms (the
glossary is Appendix C of the manual). `bcdd` reads all the forms of the language described in the manual: the
formulas, the shorthands, the concrete forms, the verification plan, the profiles and the extensions. It checks their form,
names and types; it does not evaluate formulas on the scenarios and does not compare them with one another (sections 9.7 and 14).

**The terms.** The names of the concepts are those of the manual: *guarantee* (`GUARANTEE`), *assumption* (`ASSUME`),
*request* (`CAPABILITY`), *scenario* (`SCENARIO`), *list of values* (a type `TYPE … := { … }`), *named
constant* (`DEFINE`), *undecided number* (`UNDECIDED`), *short name* (the name of a guarantee, of an assumption or of
a scenario), *pending approval* (`STATUS HYPOTHESIS`), *approved* (`STATUS RATIFIED BY`), *parts list*
(`COMPOSED OF`), *copy* of a part, *choice group* (the `VARIANT` lines with the same name to the left of
`=`). *Contract* is the set of the approved guarantees and assumptions on a boundary. The report and the messages of `bcdd`
use the same terms, with two differences, written as the program prints them: `contract` also indicates a single
approved line; “connector” indicates a CSC cited by an entity. The command that approves is called `ratify`.
For the constructs of chapters 21-27 of the manual the same terms apply: *formula*, *condition on the step*, *trigger*, *consequence*, *scope*, *shorthand*,
*expanded form*, *concrete form* (`BINDING`), *verification plan* (`VERIFICATION`), *recording instrument*
(`MEANS`), *resolution*, *profile*, *extension*, *declared extension*. The names of the checks (C1…C8), of the
rules on extensions (E1…E7) and on details (D1…D6) are those of the language specification: they appear here
to say what `bcdd` executes, and in the report they are described in words.

The outputs of `bcdd` shown in this document are those of the program in English, its default language. With
`bcdd --lang it …` or with the environment variable `BCDD_LANG=it` the program writes in Italian; the Italian outputs
are in `GRAMMATICA_F1.md`. Section 10 describes how the language is chosen.

**Declaration.** In this document *declaration* denotes every unit of the file that begins at the start of a
line and continues up to the next declaration (section 3); as a rule it begins with a keyword. Examples are a guarantee, an
assumption, a scenario, a step, the header of a block, an `OFFERS` line, and so on. The manual uses
the word in a narrower sense, for the lines that declare an element of the CSC only (`TYPE`,
`CAPABILITY`, `EVENT`, `STATE`, `DEFINE`, `SCENARIO`).

---

## 0. In brief

- A `.csc` file is UTF-8 text, divided into lines.
- The file contains `CSC … END` and `ENTITY … END` blocks. A `REFINEMENT VIEW … END` block, a withdrawn
  form, is error E15 and its lines are not recognised (section 4.8).
  A CSC describes a boundary; an entity states which CSCs it provides (`OFFERS`), which it uses (`USES`) and of which other
  entities it is made, including how many copies, and never states where it is located (section 4.9). An entity has scenarios, which
  name the elements of its CSCs with the qualified names `Csc.name` (section 4.6). An entity can contain
  `VARIANT group = choice` segments and optional parts `[0 .. n]`: it then holds for each of its
  **compositions**, and `check` checks all of them (section 4.10).
- The file can also contain the concrete forms of a boundary (`BINDING … END`), the verification plan
  (`VERIFICATION … END`) and the profiles (`PROFILE … END`), which contain the extensions (`EXTENSION … END`). `bcdd`
  reads them and checks their names against those of the CSC to which they are bound (section 4.11).
- Inside a block every declaration begins **at the start of a line** with a keyword in
  English, written in upper case: `PURPOSE`, `CAPABILITY`, `EVENT`, `STATE`, `DEFINE`, `GUARANTEE`,
  `ASSUME`, `SCENARIO`, … A declaration left open, for example with an unclosed parenthesis or with an
  `AND` at the end, continues on the next line (section 3).
- `bcdd` reads the guarantees written **in words** (`VERBAL`) and those written **as formulas** (`WHENEVER … THEN
  …`, `ALWAYS …`, the shorthands and the extensions of imported profiles). Of a formula it checks the form, the names
  and the types (sections 4.12-4.14); it does not evaluate it on the scenarios. The degree of every guarantee (verbal, formal,
  declared extension) is read from its form (section 6).
- Every line of the file ends up in one and only one place: recognised, comment, blank or unrecognised. No line
  is lost, and no unrecognised line is passed over in silence.
- An unrecognised line **is not an error**. There are forty errors (E01 … E40), listed in section 8.
- What only a person can decide (for example whether a detail in words is consistent with the guarantee that it
  details) is listed in the `TO BE JUDGED` section of the report, and the checks that `bcdd` does not execute on
  formulas are declared `CHECKS NOT EXECUTED` (section 9.7). Neither the former nor the latter are errors.
- `check` looks for the CSCs and the entities that the entities of the file cite, the imported profiles and the CSC to which
  a `BINDING` or a `VERIFICATION` is bound (in the same file, in its folder, in the `--dir` folders) and states where it
  found them; a missing citation, or a cited file with errors, does not change the outcome. Inside an entity made of parts, a CSC that a part uses, that no other part provides and that
  the entity does not use from outside is error E14 (section 9.4).
- A guarantee or an assumption must state how it is verified: `VERBAL "…"` without `VERIFY` is error E13.
- With the option `--strict` (section 10) a file that has even a single unrecognised line makes
  `bcdd check` exit with code 3. Without the option, an unrecognised line does not change the code; the
  `outcome` line counts it in any case (section 9.2).
- Every `GUARANTEE` and `ASSUME`, every detail of `DEFINE` or of `SCENARIO`, every `BIND` line and every profile is
  **approved** or **pending approval** (section 7.1). Only `bcdd ratify` approves, and only in a file that `check
  --strict` accepts (section 12). A verification plan is never approved.
- `check` accepts `DETAILS` at any depth; it is `refine` that stops at the second level (section 7.3).

---

## 1. The file

| What | Rule |
|---|---|
| Extension | `.csc`. `bcdd new` always creates a `.csc` file; `bcdd check` reads a file with any name |
| Encoding | UTF-8. A byte that is not valid UTF-8 stops the check (section 10) |
| BOM | the three bytes `EF BB BF` at the head of the file, if present, are ignored |
| End of line | the LF character. A CR character immediately before LF is ignored (files written on Windows) |
| Lines | they are counted from 1. The last line counts even if it does not end with LF. An empty file has 0 lines |
| Spaces | only the space and the tab are spaces. Every other invisible character (for example the non-breaking space) is a foreign character |

---

## 2. The words of the file

The text is divided into **tokens**, like the words of a sentence. Spaces separate the tokens and have
no other effect: alignment in columns is free.

### 2.1 Notation of the rules

The rules are written in EBNF notation (*Extended Backus-Naur Form*), which reads as follows:

| Notation | Meaning |
|---|---|
| `A = B C ;` | A is made of B followed by C |
| `"CSC"` | the word to be written exactly so, with the same upper case |
| `[ x ]` | x can be omitted |
| `{ x }` | x zero, one or more times |
| `x \| y` | x or y |
| `( … )` | groups |

### 2.2 Rules of the words

| No. | Rule | Example |
|---|---|---|
| L1 | **Comment**: from `--` to the end of the line, if `--` is not inside a string. The comment does not count | `EVENT IN arrivo   -- from the button` |
| L2 | **String** (`Stringa`): from `"` to the next `"`. It can contain line breaks and run over several lines. It has no escape sequences: a string cannot contain `"`. Inside a string nothing is a keyword and nothing is a comment | `"A press switches on the light"` |
| L3 | **Word**: it begins with a letter (of any alphabet, accented included) or with `_`; it continues with letters, diacritical marks, digits from 0 to 9, `_`, and with `-` only if it stands between two of these characters | `intensità`, `g-n1`, `ATTESA_MAX_LLM` |
| L4 | **Dotted number**: an optional `-`, **attached** to the first digit; then digits from 0 to 9, possibly divided by dots, each between two digits. The `-` belongs to the number only if the character before it is not a letter, a diacritical mark, a digit or `_` (otherwise L3 applies: `g-1` remains a word) and if it is not the start of `--` (comment, L1) | `180`, `0.5`, `0.1.2`, `-20.0`, `-40` |
| L5 | **Symbols**: `:=` `..` `(` `)` `,` `:` `=` `[` `]` `@` `.` `{` `}`, and the symbols of formulas `<` `<=` `>` `>=` `<>` `+` `-` `*` `/` `^` `->` `;`. The longest symbol is always taken: `:=`, `..`, `<=`, `>=`, `<>` and `->` are a single symbol; `.` is a single symbol when it is not followed by another `.` and is not inside a dotted number (L4). The `-` is the minus sign only when it is not the start of a comment (L1), does not stand inside a word (L3), does not belong to a number (L4) and is not the start of `->` | `DEFINE D := 3`, `Sessione.pronta`, `{L, R}`, `a - b`, `x <= 1.0` |
| L6 | **Foreign character**: every other character outside strings and comments (for example `→`, `±`, `≤`, `$`, `%`). It is not an error: it makes the declaration that contains it unrecognised | `±`, `→` |

**Reading examples.** `g-1` is a word (L3); `--20` is a comment (L1); in `x=-3` after `=` there is the number
`-3`, because `=` is not a letter; `- 3` is the minus sign and then the number `3`; `a - b` is the word `a`, the minus
sign and the word `b`, whereas `a-b` is a single word (L3) and `a -3` is the word `a` followed by the number `-3`, with no
symbol between the two; `5-3` is the number `5`, the minus sign and the number `3`, because the `-` after a digit does not
belong to the number (L4); `-x` is the minus sign and the word `x`; `A->B` is `A`, `->` and `B`; `0.5` is a number;
`a.b` is three tokens (`a`, `.`, `b`); `Sessione . pronta` is the same three tokens as `Sessione.pronta`,
because spaces do not count; `x.5` is three tokens (`x`, `.`, `5`) that no rule accepts. To read a
minus between two values without doubt, it is written separated from both: `a - b`, `x - 3`.

Letters are compared as they are written: `città` written with the precomposed “à” and `città` written
with “a” plus a separate accent are two different names. Upper and lower case matter: `Check` and `check`
are different names, and `guarantee` is not the keyword `GUARANTEE`.

### 2.3 Keywords and reserved words

The **keywords** are in English. They are the words that `bcdd` reads, divided here by use.

The words of the CSC, of the entity, of the blocks and of the header:

```
CSC VERSION END STATUS HYPOTHESIS RATIFIED BY PURPOSE CAPABILITY AUTONOMOUS
EVENT IN OUT STATE INITIAL DEFINE UNDECIDED GUARANTEE ASSUME DETAILS VERBAL VERIFY
JUDGEMENT INSPECTION SCENARIO GIVEN EXPECT ADMITTED REJECTED COMPOSED OF
TYPE ENTITY OFFERS USES VARIANT
IMPORT PROFILE BINDING VERIFICATION EXTENSION
```

the words of formulas and of scenarios (sections 4.6 and 4.12), with the type `Record` (section 4.4):

```
WHILE ALWAYS EVENTUALLY WHENEVER THEN WITHIN AT ONCE REPEAT FOREVER EVERY
AND OR NOT IMPLIES IF ELSE COUNT LAST TIME SINCE PREV WITH ABSENT PRESENT Record
```

the words of the shorthands and the mathematical functions (section 4.12):

```
NEVER AFTER BEFORE BETWEEN UNTIL PRECEDES FOR LEAST ACCEPTS ONLY REQUIRES ENSURES RESOLVES
CHANGED TRANSITION ON WHEN FOLLOWS ALL
ABS MIN MAX LOG10 ROUND FLOOR CEIL
```

the fields of an extension, the values of the `KIND` field and the categories of parameters (section 4.11):

```
KIND LEVEL PARAMS FORM MEANING REDUCES TO SOURCE
PATTERN SCOPE FUNCTION DECLARATION RELATION SCENARIO-FORM
Name Type Event Condition Expression Duration Property
```

the words of the concrete forms and of the verification plan (section 4.11):

```
BIND AS MEANS OBSERVES RESOLUTION USING TRANSLATES
```

The values of the `LEVEL` field (`CSC`, `ENTITY`, `BINDING`, `VERIFICATION`) are already keywords. `Duration` is
also the name of a base type (section 4.4) and, in the `PARAMS` field, the category with the same meaning.
`SCENARIO-FORM` is a single word (L3) with a `-`: it could not be written as a Nome in any case (L7); the reservation
also excludes the short name `SCENARIO-FORM` (L8).

The words of two forms planned for future developments of the language are **reserved**; `bcdd` does not recognise them in any declaration (`REFINED BY`,
which will state on which guarantees of the parts an entity guarantee rests, and `REFINES`, the relation between two versions of
a CSC):

```
REFINED REFINES
```

The following are **reserved because they have been withdrawn from the language**:

```
FACE LINK MAP REFINEMENT VIEW
```

The following are also reserved, in lower case: `true false requested accepted rejected completed failed _`.

In all, the keywords and reserved words number **136**.

A keyword or reserved word cannot be a name. A line that uses one as a name is not recognised. The
exceptions are the declarations that begin with `REFINEMENT`: they are error E15 (section 4.8).

**A single list.** The keywords and reserved words of this section are the same for `check`, `new`
(rule L7, section 11), `ratify` (short name and name after `--csc`, section 12.5) and `refine` (names and short names
of the proposals): no command has a list of its own.

**What is not reserved**, and why:
- `V1`, `V2` and `C1` … `C8` are read only in the `VERIFY` field of an extension (section 4.11), where their
  position is enough to recognise them; elsewhere they are valid names (`STATE C1 : Boolean INITIAL false` is recognised);
- the names of the extensions of profiles (`SIGNAL`, `CONTINUOUS`, `STABILIZES`, `GRACE`, …): a profile that is not imported
  adds no words, and in a block that imports it the name of an extension is recognised from its position
  (section 4.14);
- the units (`ms`, `s`) and the words `Boolean`, `String`, `Integer`, `Real`, `Sequence`, `of`, `Optional`, which
  in the position of a type have the meaning of section 4.4. As the name of a declared type they are not valid
  (G15, G30, G37, G41).

**Why the words that the program reads in one place only are also reserved.** A request named
`ENSURES` or a state named `LEVEL` would give the same word two meanings in the same file. The
lower case remains free (section 2.2): `pattern` and `level` are valid names.

**Why `FACE`, `LINK`, `MAP`, `REFINEMENT` and `VIEW` remain reserved.** They are forms withdrawn from the language,
replaced by CSCs and entities. They remain reserved to avoid confusion: whoever knows the withdrawn forms reads them
with the old meaning, and a free name `MAP` in a CSC would look like the withdrawn relation `MAP`.
A withdrawn word remains reserved for ever: freeing it would bring no advantage, and it could no longer be
reserved again without invalidating CSCs.

### 2.4 Names

| No. | Rule | Valid example | Invalid example |
|---|---|---|---|
| L7 | **Nome** (name) = a word without `-`, which is not reserved | `pressione`, `Città`, `ATTESA_MAX_LLM` | `g-n1` (has `-`), `END` |
| L8 | **Id** (the short name of guarantees, assumptions and scenarios) = a word that is not reserved; it can contain `-` | `g-n1`, `f-1`, `g1a` | `g-` (ends with `-`) |
| L9 | **Decisione** (the decision reference) = a word made of `D-` followed by digits only | `D-125` | `D125`, `operatore`, `D-12a` |
| L10 | **Versione** (version) = a dotted number without `-` | `0.1`, `1`, `0.1.2` | `v1`, `-0.1` |
| L11 | **Numero** (number) = a dotted number with at most one dot, without `-` | `180`, `0.5` | `0.1.2`, `-3` |
| L12 | **Numero con segno** (signed number) = a dotted number with at most one dot, with or without `-` | `-20.0`, `3`, `0.5` | `-0.1.2` |
| L13 | **Intero** (integer) = a dotted number without dots and without `-` | `1`, `4` | `1.5`, `-1` |

Where the sign is needed the rule says so: only L12 admits it, in the limits of a range (G14), in values (G26) and
in formulas (G59), where the minus in front of a value can also be written separated (`- x`). Versions, the times of
steps (G21: `@-1` is not a step), the limits of a multiplicity (G35) and of a repetition (G47) and resolutions
(G52) remain unsigned.

---

## 3. How the file is divided into declarations

Rules U1-U5 decide **to which declaration every line belongs**. The count of recognised and unrecognised
lines depends on them.

| No. | Rule |
|---|---|
| U1 | A line that contains only spaces is **blank**; a line that contains only a comment is a **comment**. Blank lines and comments belong to no declaration and do not interrupt one |
| U2 | Every other line that **does not begin inside a string** opens a **new declaration**, except in cases U4 and U5 |
| U3 | A line that begins inside a string opened on a previous line belongs to the declaration of that string, even if it is blank or contains `--` |
| U4 | A line that begins with `VERIFY` or with `VERBAL` continues the previous declaration **if that declaration begins with `GUARANTEE` or `ASSUME`**; otherwise it opens a new declaration, which is recognised only as the `VERIFY` field of an extension (section 4.11) |
| U5 | A line that does not begin inside a string continues the previous declaration if the latter has remained **open**: (a) it has an unclosed parenthesis `(`, `[` or `{`, or (b) its last token, excluding the comment, calls for a continuation: one of the symbols `:` `,` `:=` `=` `<>` `<` `<=` `>` `>=` `+` `-` `*` `/` `^` `->` `;`, or one of the words `THEN` `WITHIN` `AND` `OR` `IMPLIES` `NOT` `IN`. The exception is a line whose first token is `@`, `END` or a word that opens a declaration in section 5 (for example `GUARANTEE`, `SCENARIO`, `BIND`, `KIND`, `REPEAT`): such a line always opens a new declaration. Blank lines and comments between the two lines do not interrupt the continuation (U1) |

The first word of a declaration states its type. A keyword that is not the first of the line
opens nothing: it is part of the current declaration.

Example, with the lines numbered:

```
 1  GUARANTEE g1: VERBAL "A press
 2                       switches on the light"     ← U3: inside the string
 3  -- note                                         ← U1: comment, does not interrupt
 4                VERIFY BY JUDGEMENT "the operator" ← U4: continues g1
 5  this line is made up                            ← U2: new declaration
```

Lines 1, 2 and 4 are a single declaration.

**Continuation (U5).** The words that always open a declaration, and therefore never continue the
previous one, are: `CSC`, `ENTITY`, `REFINEMENT`, `BINDING`, `VERIFICATION`, `PROFILE`, `EXTENSION`, `END`, `STATUS`,
`IMPORT`, `PURPOSE`, `TYPE`, `CAPABILITY`, `EVENT`, `STATE`, `DEFINE`, `GUARANTEE`, `ASSUME`, `SCENARIO`, `REPEAT`,
`OFFERS`, `USES`, `COMPOSED`, `VARIANT`, `BIND`, `MEANS`, `KIND`, `LEVEL`, `PARAMS`, `FORM`, `MEANING`, `REDUCES`,
`SOURCE`, and the symbol `@`. In this way an unclosed parenthesis or an operator at the end of a line does not absorb a
following declaration or the `END` of a block. Only the declaration left open is unrecognised, and the rest of the file is
read as before. `VERIFY` and `VERBAL` follow U4.

```
 1  GUARANTEE g2: WHENEVER pressione THEN        ← ends with THEN: remains open
 2                  accesa WITHIN 1 s            ← U5: continues g2
 3  GUARANTEE g3: WHENEVER pressione             ← does not call for a continuation
 4                  THEN accesa WITHIN 1 s       ← U2: new declaration, unrecognised
 5  GUARANTEE g4: ALWAYS (accesa AND             ← open parenthesis
 6  END                                          ← END: opens a new declaration; g4 is unrecognised
```

Lines 1 and 2 are a single declaration, recognised. Line 4 is a declaration on its own, unrecognised, and
line 3, left incomplete, is unrecognised. Line 5 is unrecognised because the parenthesis remains open; line 6 closes
the block.

A **recognised** declaration makes all its lines recognised; an **unrecognised**
declaration makes all its lines unrecognised.

---

## 4. The grammar of declarations

Every rule describes an entire declaration, from the first word to the last, even if it spans several lines.
A declaration is recognised only if **all** its tokens respect the rule, with nothing
more.

### 4.1 Blocks

| No. | Rule | Example |
|---|---|---|
| G1 | `IntestazioneCsc = "CSC" Nome "VERSION" Versione ;` | `CSC LuceScale VERSION 0.1` |
| G2 | `IntestazioneVista = "REFINEMENT" "VIEW" Nome ;` is not a declaration of the language: it serves only to read the name of the withdrawn block in the report (section 4.8) | `REFINEMENT VIEW LuceParti` |
| G3 | `Fine = "END" ;` | `END` |

The `ENTITY` block has its own header G31 (section 4.9); the `BINDING`, `VERIFICATION`, `PROFILE` and
`EXTENSION` blocks have the headers G40, G48, G49 and G50 (section 4.11). All of them end with G3.

### 4.2 Header of the CSC

| No. | Rule | Example |
|---|---|---|
| G4 | `StatoCsc = "STATUS" Stato ;` | `STATUS RATIFIED BY D-125` |
| G5 | `Stato = "HYPOTHESIS" \| "RATIFIED" "BY" Decisione ;` | `HYPOTHESIS` |
| G6 | `Scopo = "PURPOSE" Stringa ;` | `PURPOSE "Switches on the staircase light"` |
| G39 | `ImportaProfilo = "IMPORT" "PROFILE" Nome "VERSION" Versione ;` | `IMPORT PROFILE Segnale VERSION 0.3` |

**The header lines.** In a CSC the **header zone** runs from the `CSC` line to the first declaration that
does not begin with `STATUS`, `IMPORT` or `PURPOSE` (comments and blank lines do not count). There `STATUS` (G4), `IMPORT
PROFILE` (G39) and `PURPOSE` (G6) stand **in any order**:

- `STATUS` is recognised at any point of the zone; a second `STATUS` recognised in the zone is error
  **E10** (`STATUS repeated: the first is at line N`, section 8), and the status of the CSC is that of the first. After the
  zone `STATUS` is not recognised;
- `IMPORT PROFILE` is recognised only in the zone, zero or more times; after the zone it is not recognised. Without
  `VERSION`, or with a version that does not respect L10, it is not recognised. The version is mandatory because
  relaxing the rule later will invalidate no file, whereas tightening it would;
- `PURPOSE` is mandatory and unique in every CSC (E10 if it is missing or repeated). It is recognised also outside the
  zone, at any point of the block;
- a declaration that begins with `STATUS`, `IMPORT` or `PURPOSE` but is not recognised (`STATUS PIPPO`, `IMPORT
  PROFILE Segnale` without a version) remains unrecognised and **does not close** the zone: a badly written line does not take
  the place of those that follow;
- a declaration that opens a block (`CSC`, `ENTITY`, `REFINEMENT`, `BINDING`, `VERIFICATION`, `PROFILE`) closes the
  CSC with E07 (section 5), and the zone with it.

**The same zone in the other blocks.** Every block imports profiles for itself. The header zone, with the same
rules, also exists in an entity (`STATUS HYPOTHESIS`, `IMPORT PROFILE`, `PURPOSE`; section 4.9), in a `BINDING`
(`STATUS`, `IMPORT PROFILE`), in a `VERIFICATION` (`IMPORT PROFILE`; a `STATUS` is error E39) and in a `PROFILE`
(`STATUS`, `PURPOSE`; `IMPORT PROFILE` is unrecognised there, because a profile does not import other profiles). The
rules of the `BINDING`, `VERIFICATION` and `PROFILE` blocks are in section 4.11.

**The imported profile.** `IMPORT PROFILE P VERSION v` is a **citation**: `bcdd` looks for the block `PROFILE P` as
it looks for a cited CSC (section 9.4), and finds it only with the written version `v` (same text). A profile found
with another version is not found: the report lists it in section 7, with the version found. Of the profile
found `bcdd` reads the extensions (section 4.14). Two lines that import the same profile with the same version
are not an error and count as one; if two lines of the same block import the same profile with different
versions, the second in the order of the file is not recognised, because the same extension name would have two
meanings. The line registers no name in the list of names of the block.

A deliberate exception to G5: `STATUS RATIFIED` followed by anything other than `BY` and a
Decisione (up to the colon in a contractual line, up to the end in the header) **is
recognised**, with error E04. A badly written approval must not disappear among the unrecognised
lines: it is precisely the error that the check must show. `STATUS` followed by a word other
than `HYPOTHESIS` and `RATIFIED`, by contrast, is not recognised.

### 4.3 Inputs, outputs, states, constants

| No. | Rule | Example |
|---|---|---|
| G7 | `Capacita = "CAPABILITY" Nome [ Parametri ] [ "AUTONOMOUS" ] ;` | `CAPABILITY Check(file: String)` |
| G8 | `Evento = "EVENT" ( "IN" \| "OUT" ) Nome [ Parametri ] ;` | `EVENT IN pressione` |
| G9 | `Parametri = "(" [ Parametro { "," Parametro } ] ")" ;` | `(file: String, riga: Optional String)` |
| G10 | `Parametro = Nome ":" Tipo ;` | `accettata: Boolean` |
| G11 | `StatoOsservabile = "STATE" Nome ":" Tipo "INITIAL" Valore [ "FOLLOWS" Nome "." Nome ] \| "STATE" Nome "[" Nome "]" ":" Tipo "INITIAL" Valore ;` | `STATE accesa : Boolean INITIAL false`, `STATE clipCount[Ch] : Integer [0 ..] INITIAL 0`, `STATE volume : Integer [0 .. 100] INITIAL 50 FOLLOWS imposta.livello` |
| G12 | `Definizione = "DEFINE" Nome [ ParametriDefine ] [ "DETAILS" Id [ "STATUS" Stato ] ] ":=" ( "UNDECIDED" \| Espr ) \| "DEFINE" "EVENT" Nome ":=" Espr ;` | `DEFINE ATTESA_MAX_LLM := UNDECIDED`, `DEFINE vicino(a: Real, b: Real) := ABS(a - b) <= 0.01`, `DEFINE EVENT riavvio := accepted(Avvio)` |
| G12a | `ParametriDefine = "(" Parametro { "," Parametro } ")" ;` | `(a: Real, b: Real)` |

G7 declares a request; G12 a named constant, a function with parameters or a derived event.

**Indexed states and states that follow an event (G11).**
- `STATE x[T] : …` declares an indexed state: it is equivalent to one state for each value of `T`. `T` is a
  **finite** type: a list of values (G37), `Boolean`, or a name given with G41 to one of these or to an `Integer` with both
  limits; otherwise it is error E29. Between the square brackets stands a name (G11): `STATE q[Integer [0 .. 3]] : …`
  is not recognised, and one writes `TYPE Indice := Integer [0 .. 3]` and `STATE q[Indice] : …`. In the declaration the type of the index is written, not a variable. The value
  of `INITIAL` holds for every element. Where the state is used, the index is a value of `T` or a variable of `FOR ALL` over `T`
  (section 4.12); in scenarios a value of `T` (G20).
- `STATE s : T INITIAL v FOLLOWS e.campo` declares a state that follows the field `campo` of the event `e`: `e` is an
  `EVENT` of the block, `campo` one of its parameters, and the type of the parameter is that of the state (E24 and E25 otherwise).
  The meaning is that of the expanded form `ALWAYS (e IMPLIES s = LAST(e).campo)` and `ALWAYS (CHANGED(s) IMPLIES e)`:
  the line is also a formal property, without a short name, and the report does not list it among the contractual lines.
- An index and `FOLLOWS` in the same line are not a form: the line is not recognised. Events and requests do not
  have indices.

**Constants, functions and derived events (G12).**
- The value of a `DEFINE` is an expression of section 4.12. A Valore of section 4.7 is a special case:
  the lines with a number, a string, `true`, `false` or a value of a list of values are read as before.
- `DEFINE name(p: T, …) := expression` is a function with typed parameters; it is used with the arguments by name,
  `name(p: arg, …)`, like the arguments of events in scenarios (section 4.12). The names of the parameters hold only
  in the line.
- `DEFINE EVENT name := condition` gives a name to a derived event: the condition is a `Boolean` expression on the
  step, the line has neither parameters nor `UNDECIDED`, and the name is used where an event is used (section 4.12), except in the
  steps of scenarios, which contain only declared events (E03, as at present).
- `DEFINE name DETAILS parent [STATUS …] := …` details another `DEFINE` of the same block (section 7.1 for the
  status; E02 if the parent is not a `DEFINE`). `UNDECIDED` has no parameters.
- `DEFINE`s do not refer to one another circularly: `DEFINE A := B + 1` with `DEFINE B := A - 1` is error E28.
- The type of a constant is that of its expression (section 4.13); that of `UNDECIDED` is not known, and an
  `UNDECIDED` constant is used without a type check.

**A constant with its value.** The most common case is a Valore of section 4.7: a number, with or without a sign
and with or without a unit, a string, `true`, `false` or a value of a list of values. The unit stands **on the same
line** as the number (G27). Examples, for the staircase light:

```
DEFINE DURATA_LUCE := 60 s        -- recognised: number and unit
DEFINE DURATA_LUCE := 60s         -- recognised: the space can be omitted
DEFINE RITARDO_MAX := 250 ms      -- recognised
DEFINE PIANI := 4                 -- recognised: plain number, without unit
DEFINE LAMPEGGIO := UNDECIDED     -- recognised: goes into section 3 of the report
DEFINE ATTENUAZIONE_MIN := -40    -- recognised: signed number
DEFINE DURATA_LUCE := 1 min       -- unrecognised: min is not a unit of the language
DEFINE LIVELLO_MAX := 90 dB       -- unrecognised: the only units are s and ms;
                                  --   one writes DEFINE LIVELLO_MAX_DBA := 90
DEFINE DURATA_LUCE := 60          -- recognised, but the next line, which begins with “s”,
                      s           --   opens a new declaration, unrecognised (U2)
DEFINE DURATA_AVVISO := DURATA_LUCE - 5 s   -- recognised: an expression, of type Duration
DEFINE DOPPIA := DURATA_LUCE * 2  -- recognised: a duration times a number is a duration
DEFINE STRANA := DURATA_LUCE + 2  -- recognised, with error E25: a duration plus a plain number
```

`check` checks the type of the expression (section 4.13), not the value: it does not know whether `120 s` is a lot or a little, and a
constant name written inside a string (`VERBAL "switches off after DURATA_LUCE"`) is only text.

**From `UNDECIDED` to a value.** `UNDECIDED` denotes an undecided number: `check` lists it in section 3 of the
report as long as it is present. When the number is decided, the value is written in place of `UNDECIDED`, by hand: no command
does it. What is needed depends on the CSC:
- in a CSC **pending approval** the line is changed, and nothing more;
- in an **approved** CSC the line is not changed: a new VERSION is written, which returns to pending approval
  until it is approved (section 7.2).

### 4.4 Types

| No. | Rule | Example |
|---|---|---|
| G13 | `Tipo = "Boolean" \| "String" \| "Duration" \| ( "Integer" \| "Real" ) [ Intervallo ] \| "Sequence" "of" Tipo \| "Optional" Tipo \| TipoRecord \| TipoNonDichiarato ;` | `Sequence of String` |
| G14 | `Intervallo = "[" NumeroConSegno ".." NumeroConSegno "]" \| "[" NumeroConSegno ".." "]" \| "[" ".." NumeroConSegno "]" ;` | `Real [0.0 .. 1.0]`, `Integer [-40 .. 0]`, `Integer [0 ..]`, `Integer [.. 10]` |
| G15 | `TipoNonDichiarato = Nome ;` different from the seven words `Boolean String Duration Integer Real Sequence Optional` | `Testo` |

| G30 | `TipoDescritto = "TYPE" Nome ":=" "VERBAL" Stringa ;` inside a CSC block; `Nome` is not one of the seven base types | `TYPE Testo := VERBAL "the content of a file, line by line"` |
| G37 | `TipoEnumerato = "TYPE" Nome ":=" "{" Nome { "," Nome } "}" ;` inside a CSC block; the `Nome` of the type is not one of the seven base types | `TYPE Fase := {inattiva, armata, in_corso}` |
| G41 | `TipoConNome = "TYPE" Nome ":=" Tipo ;` inside a CSC block; `Nome` is not one of the seven base types | `TYPE Percentuale := Integer [0 .. 100]`, `TYPE Campione := Record {L: Real, R: Real}` |
| G42 | `TipoRecord = "Record" "{" Campo { "," Campo } "}" ;` with `Campo = Nome ":" Tipo ;` | `Record {L: Real, R: Real}` |

An undeclared type is admitted: it is not an error, and it appears in section 6 of the report with the lines where it is
used, so that it does not remain hidden. `Sequence` without `of`, or `Optional` without a type, are not recognised. `check` does not
compare the limits of a range with each other: `Real [20.0 .. -20.0]` is recognised (section 14). A range with
an omitted limit does not have that limit: `Integer [0 ..]` is a non-negative integer with no maximum; `[ .. ]`, with neither
limit, is not a range and makes the declaration unrecognised.

**Named types (G41) and `Record` (G42).**
- `TYPE Nome := Tipo` gives a name to any type of G13: the name stands for the type it names, throughout the
  block, even if the line comes after the use. It enters the list of names of the block (E01 if repeated) and leaves
  section 6. Two type names that refer to one another circularly (`TYPE A := B`, `TYPE B := A`) are error E28.
- `Record {campo: Tipo, …}` is a type with fields; `x.campo` names one of its fields (section 4.12). The names of the fields
  hold only in the `Record`: two fields with the same name are E01; a field can have the same name as an element
  of the block. A `Record` has no written values: a state of type `Record` has no valid `INITIAL` (E25), and
  in scenarios the value of a parameter of type `Record` is written `_`.
- `TYPE Nome := VERBAL …` (G30) and `TYPE Nome := { … }` (G37) remain as below. A `TYPE` that respects
  none of the three, or that gives a new name to a base type (`TYPE Boolean := Integer`), is not recognised and
  registers no name.

**Types described in words (G30):**
- the name of the type enters the list of names of the block: another identical name is E01;
- a type described in words is **not** an undeclared type: it leaves section 6 of the report, throughout the
  block, even if the description comes after the use;
- a `TYPE` written in another way, which is neither G30, G37 nor G41 (`TYPE Colore := {}`), or that describes a base
  type (`TYPE Boolean := VERBAL "…"`), is not recognised and registers no name;
- a type is not a guarantee: it does not require `VERIFY` and does not give E13. A `VERIFY` line after a `TYPE` opens
  a new declaration, unrecognised (rule U4).

Example: `STATE contenuto : Testo INITIAL ""` with `TYPE Testo := VERBAL "the content of a file"` in the
same block: `Testo` does not appear in section 6.

**Lists of values (G37).** A list of values is a type made of a closed set of named values; a value
of that type is one of them. Example:

```
TYPE Fase := {inattiva, armata, in_corso, accettata, rifiutata}
EVENT OUT stato(fase: Fase)
STATE fase_ora : Fase INITIAL inattiva
```

| What | Rule |
|---|---|
| The name of the type | as G30: it enters the list of names of the block (E01 if repeated) and leaves section 6 `UNDECLARED TYPES`, throughout the block |
| The values | they are names (L7) and enter the **same list** of names of the block: a value equal to a state, an event, a request, a constant, a short name or a value of another list of values is **E01** on the second, in the order of the file (line, then column). A value repeated in the same list is E01 on the second. Line and column of the error: those of the value |
| A name as a value | (G26) in `INITIAL`, `GIVEN`, assignments and arguments, and in a `DEFINE` whose value is a single name. In a CSC block, if the name is not a value of a list of values of the same block (and, in a `DEFINE`, not another name of the block either): **E03** `name not declared as a value of TYPE: X`. In an entity scenario section 4.6 applies. In a wider expression section 4.13 applies |
| The type of the value | **is checked** (section 4.13): `STATE fase_ora : Fase INITIAL rifiutata` is recognised without errors; `STATE accesa : Boolean INITIAL armata` (with `armata` a value of `Fase`) is recognised with error **E25** `value not of type Boolean: armata` |
| It is not a guarantee | no `VERIFY`, no E13, as G30. A `VERIFY` line after a `TYPE` opens a new declaration, unrecognised (U4) |
| Unrecognised, with no names registered | `TYPE X := {}`, `TYPE X := {a b}`, `TYPE X := {a,}`, `TYPE Boolean := {a, b}` (base type), `TYPE X := {"a", "b"}`, `TYPE X := {1, 2}` |
| `TYPE X := {a, a}` | recognised, with E01 on the second `a` |
| In the JSON | a declaration of type `TYPE`, as G30; the values are not declarations of their own: they are in its `testo` |

The lifecycle names (`requested` …), `true`, `false` and `_` are reserved and cannot be values of a list of
values (L7).

### 4.5 Contractual lines

| No. | Rule | Example |
|---|---|---|
| G16 | `RigaContrattuale = ( "GUARANTEE" \| "ASSUME" ) Id [ "DETAILS" Id ] [ "STATUS" Stato ] ":" Proprieta ;` | `GUARANTEE g2a DETAILS g2 STATUS HYPOTHESIS: VERBAL "…" VERIFY BY JUDGEMENT "…"` |
| G17 | `Proprieta = "VERBAL" Stringa Verifica \| Formula ;` (`Formula`: G55, section 4.12) | `VERBAL "Check never modifies the file" VERIFY BY INSPECTION "the file"`, `WHENEVER pressione THEN accesa WITHIN 1 s` |
| G18 | `Verifica = "VERIFY" "BY" ( "JUDGEMENT" \| "INSPECTION" ) Stringa ;` | `VERIFY BY JUDGEMENT "the operator"` |

A contractual line is a guarantee (`GUARANTEE`) or an assumption (`ASSUME`). It is read in two parts.
The **line header** runs from the first word to the colon; the **property** comes after the colon.
- If the line header does not respect G16, the line is not recognised and its short name does not exist for the
  check.
- If the line header respects it but the property does not respect G17, the short name exists (it can be named
  with `DETAILS`, it counts for repeated names) but the line is unrecognised and its degree is `unrecognised`. This is the
  case of a formula written in a form that section 4.12 does not provide for (section 6).
- A formula does not require `VERIFY`: its mode of verification is given by the form (section 6). A `VERIFY` line after
  a formula continues the declaration (U4) and makes it unrecognised.

The same holds for G12: in `DEFINE LIMITE := DURATA * * 2` the name `LIMITE` exists, but the line is
unrecognised because the expression does not respect section 4.12.

**The missing verification (error E13).** A deliberate exception to G17, like that of G5: if after the colon the
property is **exactly** `VERBAL` followed by a closed string, and the declaration ends there, the line **is
recognised**, its degree is `verbal` and there is error E13. Example: `GUARANTEE g2: VERBAL "without verification"`. The
reason: every guarantee and every assumption must state how it is verified. A guarantee that does not state it is not a
form that `bcdd` cannot read: `bcdd` reads all of it and sees that a mandatory item is missing. Classifying it among the
unrecognised lines, with outcome 0 without `--strict`, would let a guarantee with no way of
checking it pass as valid. It is the same reasoning as E04 (an approval without a decision).

E13 is narrow on purpose. If after the string there is anything else, the rule remains G17: for
example `VERBAL "…" VERIFY BY MAGIC "…"` declares a mode of verification that the language does not provide for, and is
unrecognised, without E13. In the steps of scenarios the element `VERBAL "…"` (G22) is an assertion in words, not
a property: it does not require `VERIFY` and never gives E13.

**Which unrecognised declarations register a name.** A registered name exists for the check: it can be
named (`DETAILS`, steps), and it counts for E01. Only the following register one:
- `GUARANTEE` and `ASSUME` with a valid line header (G16), whatever the property;
- `DEFINE` read up to and including `:=` according to G12 (with the parameters, `DETAILS` and `STATUS` if present, or
  `DEFINE EVENT Nome`), followed by anything.

`CAPABILITY`, `EVENT`, `STATE`, `SCENARIO` and `TYPE` register nothing unless they are recognised in full.
The reason for the difference: the short name of a contractual line serves the chain of `DETAILS` and the
approval status (section 7), and the line header is read on its own, before the colon. For the other
declarations the part that matters (parameters, type, `GIVEN`) is precisely the part that has not been read. The consequence:
a step that names an event or a request whose declaration is not recognised gives E03 (`name not declared as …`).
The error indicates the point to correct, and the badly written declaration is in section 5 of the report in any case.

### 4.6 Scenarios

| No. | Rule | Example |
|---|---|---|
| G19 | `Scenario = "SCENARIO" Id [ "DETAILS" Id [ "STATUS" Stato ] ] [ "GIVEN" Assegnazione { "," Assegnazione } ] "EXPECT" ( "ADMITTED" \| "REJECTED" ) ;` | `SCENARIO s1 GIVEN accesa = false EXPECT ADMITTED`, `SCENARIO s1a DETAILS s1 STATUS HYPOTHESIS GIVEN accesa = false EXPECT ADMITTED` |
| G20 | `Assegnazione = Nome [ "[" Valore "]" ] "=" Valore ;` | `accesa = true`, `clipCount[L] = 2` |
| G21 | `Passo = "@" Numero [ Unita ] [ Elemento { [ "," ] Elemento } ] ;` | `@100 s   pressione(tasto: 1)   accesa = true` |
| G22 | `Elemento = "VERBAL" Stringa \| Ciclo \| Assegnazione \| Occorrenza ;` | `VERBAL "the light has been off for a short time"` |
| G23 | `Ciclo = ( "requested" \| "accepted" \| "rejected" \| "completed" \| "failed" ) "(" Nome ")" ;` | `requested(Refine)` |
| G24 | `Occorrenza = Nome [ "(" Argomento { "," Argomento } ")" ] ;` | `risposta(proposta: "g2a", accettata: false)` |
| G25 | `Argomento = Nome ":" ( Valore \| "_" ) ;` | `tasto: _` |
| G36 | `NomeQualificato = Nome "." Nome ;` only in scenarios and in entity formulas: the first name is a CSC of the entity, the second one of its elements | `Sessione.pronta`, `Abbinamento.abbina` |
| G47 | `Ripetizione = "REPEAT" ( "FOREVER" \| Intero ".." Intero ) "EVERY" Numero Unita ;` | `REPEAT FOREVER EVERY 1 s`, `REPEAT 2..5 EVERY 100 ms` |

A scenario begins with `SCENARIO` (G19) and continues with its steps (G21). How one element of a
step is distinguished from another, looking at most at the next token:
- `VERBAL` opens an assertion in words;
- one of the five lifecycle words opens a `Ciclo`;
- a name followed by `=` is an `Assegnazione`, that is “in this step the state has the value…”;
- another name is an event `Occorrenza`;
- after `=` there always comes a Valore (G26): `@1 s fase_ora = armata premi(…)` is an assignment and then
  an occurrence; in `x = premi` the value is the name `premi` (and E03 if it is not a value of a list of values).

The comma between two elements may be written or omitted; a comma at the end of the step leaves the declaration open
(U5): if the next line begins with `@` the step remains unrecognised. The unit after the number of the step holds only
if it is on the same line.

**Indices in scenarios (G20).** `x[v] = w` assigns the element `v` of an indexed state: `v` is a value of the type
of the index (E29 otherwise), `w` a value of the type of the state. An indexed state written without an index, or a
state without an index written with an index, is error E29.

**Details of a scenario (G19).** `SCENARIO id DETAILS parent [STATUS …]` details another scenario of the same
block (E02 if `parent` is not a scenario). The status of the detailed scenario follows section 7.1. A scenario without
`DETAILS` has no `STATUS`: `SCENARIO s1 STATUS HYPOTHESIS EXPECT ADMITTED` is not recognised.

**Repetitions (G47).** A `REPEAT` line stands among the steps of a scenario and holds until its end: the steps that
follow it are the repeated ones. `REPEAT FOREVER EVERY d` repeats the steps without end; `REPEAT m..n EVERY d` from
`m` to `n` times. Each repetition begins `d` after the previous one, and the times `@t` of the repeated steps count
from the start of the repetition. Example:

```
SCENARIO lampeggio EXPECT ADMITTED
  @0 s     accendi
  REPEAT FOREVER EVERY 1 s
  @0 s     spegni
  @0.5 s   accendi
```

| Case | Outcome |
|---|---|
| a second `REPEAT` line in the same scenario | **E30** `REPEAT repeated in the scenario: the first is at line N`, on the second |
| `REPEAT m..n` with `m` > `n` or `n` = 0 | **E30** `invalid repetitions: m..n. Write REPEAT minimum..maximum, with the maximum at least 1 and not smaller than the minimum` |
| a repeated step with time `t` greater than or equal to `d` | **E30** `the step @t is not shorter than the period of REPEAT: every repeated step has a time smaller than EVERY d` |
| a `REPEAT` line with no steps after it | **E30** `REPEAT without steps: the repeated steps are written after the REPEAT line` |
| a scenario with steps without units and a `REPEAT … EVERY d` line | **E30** `REPEAT … EVERY requires a scenario with time units` |
| `REPEAT FOREVER` without `EVERY`, `REPEAT 2..5 EVERY 1` (without unit), `REPEAT -1..2 EVERY 1 s` | it is not G47: the line is not recognised |
| E12 | it holds in the steps before `REPEAT` as at present, and among the repeated steps themselves, with the relative times; the first repeated step is not compared with those before `REPEAT` |

A `REPEAT` line is not a step: it neither opens nor closes the scenario (section 5).

Known limitation: in `@0 s pressione` the word `s` is the time unit. An event named `s` or `ms` therefore cannot
be the first element of a step without a unit.

**Entity scenarios.** In an `ENTITY` block `SCENARIO` (G19) and the steps (G21-G25) hold as in the CSC, with a
single difference: the names of states, events and requests are **qualified** (G36). `NomeQualificato` is written in place
of `Nome` in these three rules, and only in them:

```
G20e  Assegnazione = NomeQualificato "=" Valore ;
G23e  Ciclo        = ( "requested" | "accepted" | "rejected" | "completed" | "failed" ) "(" NomeQualificato ")" ;
G24e  Occorrenza   = NomeQualificato [ "(" Argomento { "," Argomento } ")" ] ;
```

G20e holds in the `GIVEN` and in the steps. The arguments (G25) remain simple names: they are the parameters of the event.
A simple name in an entity scenario is read with G20, G23, G24 as in the CSC, and gives E03 (an entity does not
have elements of its own). Example, in the entity `Processore` that provides `Abbinamento`, `Sessione` and `Pulsanti`:

```
SCENARIO comandoDopoAbbinamento GIVEN Sessione.pronta = true EXPECT ADMITTED
  @0 s   Abbinamento.abbina(codice: "AB12")
  @1 s   Pulsanti.premi(pulsante: "flat", acceso: true)
```

Meaning: as a scenario of a CSC, an open, timed trace that the entity admits or rejects, observed on
several boundaries of the same entity. It is not part of the contract: it is not approved, and it indicates neither an order among the parts, nor a
priority, nor a channel. What `check` checks:

| Case | Outcome |
|---|---|
| `X.y`, `X` is a recognised `OFFERS` or `USES` of the entity without E01, the CSC `X` is found (section 9.4) and has `y` of the right kind: `STATE` in assignments, `EVENT` in occurrences, `CAPABILITY` in lifecycle phases; every argument is a parameter of the event | no error |
| as above, but `y` is not there, or is not of the right kind | **E03** `name not declared as EVENT: X.y` (and likewise `STATE`, `CAPABILITY`) |
| as above, but an argument is not a parameter of the event | **E03** `name not declared as a parameter of X.y: a` |
| `X` is not among the `OFFERS` and `USES` of the entity (recognised and without E01) | **E20** `X.y: E neither provides nor uses connector X; a scenario can cite only the connectors of E`, with `E` the name of the entity (`?` if it cannot be read) |
| `X` belongs to the entity but the CSC `X` is not found | no error: the check of `y` and of its arguments is **suspended**, as E14 with a part not found; the citation is already in section 7 |
| a **simple** name (`pronta`) | **E03**, as in the CSC without that name: `name not declared as STATE: pronta` |
| a value that is a name (`fase: armata`) | it is accepted as a value, without a check: the values of the lists of values of a cited CSC are not read (section 14) |
| a written value (number, string, `true`, `false`, `ABSENT`) for a state or a parameter of `X.y` | it is checked against the type read in the block found, if it is a base type (`Boolean`, `String`, `Duration`, `Integer`, `Real`, with their range, also inside `Optional`): **E25** if it is not of the type. A type that is not a base type (a list of values, a named type, a type described in words of the cited CSC) is not checked |
| `X.y` in a **CSC** (also with `X` equal to the CSC itself), in a `GIVEN`, in an assignment, in an occurrence, in a lifecycle phase or in a phase of a formula (section 4.12) | **E20** `X.y: in a CSC, names are not written with the connector in front. The order of two connectors is written in a SCENARIO of the entity`. The declaration is read with G20e, G23e, G24e only to give the error |
| `X.y` outside a scenario (for example `DEFINE N := X.y`, `STATE s : X.T INITIAL …`, `OFFERS X.y`) | it is not a form: the declaration is not recognised |

Line and column of E20 and of E03 on a qualified name: those of `X`. A declaration with E20 or E03 remains
**recognised** (the form is right, the name is not), as with E03 in the CSC. With several versions of the same CSC
provided or used (section 5) it is enough for `y` to be present in one of the blocks found for that name. If `y` is not present in
any of the blocks found, but at least one of the `OFFERS` or `USES` lines with that name has not been found, the
check of `y` and of its arguments is **suspended**, without E03: the missing version might have `y`, and an
error is reported only when it is certain. E03 is written only when all the lines with that name are found. A line
found only through the fallback (`, expected VERSION w`, section 9.4) does not count as found for this check: it is like
a line not found, and the check of `y` is suspended, without E03 on the block of another version; in the report the
line has `expected` in any case. E12 holds in entity scenarios as in the CSC. The short name of an entity scenario
enters the list of names of the entity (section 5).

### 4.7 Values

| No. | Rule | Example |
|---|---|---|
| G26 | `Valore = Stringa \| NumeroConSegno [ Unita ] \| "true" \| "false" \| "ABSENT" \| Nome ;` where `Nome` is a value of a list of values (section 4.4) | `180 s`, `""`, `false`, `-40`, `armata`, `ABSENT` |
| G27 | `Unita = "ms" \| "s" ;` on the same line as the number, with or without a space | `250 ms`, `50ms` |

### 4.8 The parts list, and the withdrawn view

| No. | Rule | Example |
|---|---|---|
| G28 | `ElencoParti = "COMPOSED" "OF" ;` | `COMPOSED OF` |
| G29 | `Parte = Nome ":" Nome ;` held only in views, which have been withdrawn from the language: **it holds nowhere** | `archivio : Archivio` |

G28 holds in the entity (section 4.9). `LINK`, `MAP` and `REFINED BY` are not read: they are unrecognised lines.

**The view has been withdrawn.** A decomposition is written with `ENTITY`. A `REFINEMENT VIEW` is
treated as follows:

- a declaration that begins with the word `REFINEMENT`, in a place where a block begins (outside a
  block, or inside an open block, which it closes with E07), is **error E15** on the word `REFINEMENT`, whatever
  follows it. The declaration is not recognised;
- the declaration opens a **withdrawn block**, which ends with `END` (G3), like the other blocks. Inside the
  withdrawn block every other declaration is not recognised: it registers no name, it is not looked for, it does not
  appear in section 7 and it does not give E01. A `CSC`, an `ENTITY` or another `REFINEMENT` closes it with E07,
  as for the other blocks; without `END` at the end of the file there is E07;
- the withdrawn block does not register its name: it does not give E01 with another block of the same name;
- in the report the withdrawn block appears among the blocks, `line N: REFINEMENT VIEW Nome` if the declaration
  respects G2, otherwise `REFINEMENT VIEW (invalid header)`; E07 names it (`END of REFINEMENT
  VIEW X is missing`). It does not count for E11.

**Why an error, and not an unrecognised line or a warning.** `check` has no warnings: a section
of the report would be needed for a single case. An unrecognised line denotes a form that `bcdd` cannot read, and without
`--strict` it does not change the code: the view would pass in silence, and whoever wrote it would believe they had declared
a decomposition. Here, by contrast, `bcdd` can read the form and knows that it is wrong, because it has been withdrawn: this is the
definition of an error in section 8, and the same reasoning as E04 and E13. The message states what to
write in its place.

**Why the lines of the block are not recognised.** Reading the parts of a view would mean continuing to give
a meaning to a form that no longer has one. The lines all remain visible in section 5, with their number.
The block remains a block, with its `END`, because otherwise `END` would give E08 and `COMPOSED OF` and the parts
would appear to be written out of place.

### 4.9 Entities

An **entity** is recognised by the boundaries on which it stands: the CSCs it provides and those it uses. The provider of a CSC
keeps its guarantees (`GUARANTEE`), the consumer satisfies its assumptions (`ASSUME`). An entity can be
made of other entities, its **parts**. It has no elements of its own (events, states, requests): those stand in the
CSCs, and a declaration of an element of its own in an entity is error E18 (section 5). An entity has scenarios with the
qualified names (section 4.6).

| No. | Rule | Example |
|---|---|---|
| G31 | `IntestazioneEntita = "ENTITY" Nome "VERSION" Versione ;` | `ENTITY LuceScale VERSION 0.2` |
| G32 | `Offerta = "OFFERS" Nome [ "VERSION" Versione ] ;` the name is a CSC | `OFFERS Pressione VERSION 0.1` |
| G33 | `Uso = "USES" Nome [ "VERSION" Versione ] ;` the name is a CSC | `USES Comando` |
| G34 | `ParteEntita = Nome ":" Nome [ "VERSION" Versione ] [ Molteplicita ] ;` the first is the name of the part, the second an entity | `pulsante : Pulsante VERSION 0.1`, `telefono : Misuratore [1 .. 4]` |
| G35 | `Molteplicita = "[" Numero ".." Numero "]" ;` | `[1 .. 4]`, `[2 .. 2]` |

- `VERSION` without a version, or with a version that does not respect L10 (`v1`), makes the declaration
  unrecognised: `OFFERS Comando VERSION v1` is not recognised and is not looked for.
- A part (G34) holds at any point of the entity; the parts list, `COMPOSED OF` (G28), is written only
  once and tells the reader that the entity is made of parts (section 5, “The parts of an entity”).
- An entity can have `STATUS HYPOTHESIS` (G4) and `IMPORT PROFILE` lines (G39) in its header zone, like
  the CSC (section 4.2). It has exactly one `PURPOSE` (G6), `GUARANTEE` lines (G16), with `DETAILS` among them, and scenarios
  with their steps (section 4.6). Entity guarantees are in words or formulas. They are approved one by one or with
  `--all` (section 12); the entity as a whole is not (section 7.1).
- **Entity guarantees written as formulas.** A formula in an entity `GUARANTEE` (section 4.12) names the
  elements of the CSCs of the entity with the qualified names `X.y` (G36), with the rules of entity scenarios of
  section 4.6: `X` is an `OFFERS` or `USES` of the entity (E20 otherwise, with the message `X.y: E neither provides nor uses
  connector X; an entity guarantee can cite only the connectors of E`), `y` an element of the right kind in the
  CSC `X` found (E24 otherwise), and the check is suspended if `X` is not found. With compositions, `X` is
  checked per composition as in scenarios (section 4.10). In this version `X.y` in an entity formula has
  an **unknown** type, even when the block found gives it a base type: `check` checks its name and its kind,
  not its type, and on these formulas it does not give E25 (section 14). In entity scenarios the written values are checked
  against base types (section 4.6). A simple name is a value of a list of
  values of a cited CSC, accepted without a check, or a variable of `FOR ALL`; in a position that
  requires an event, a request, a state or a condition it is error E24 (`in an entity the names of the CSCs are written
  with the connector in front: x`). An entity uses the extensions of the profiles that it imports itself, with `LEVEL
  ENTITY` (section 4.14). Example: `GUARANTEE g1: WHENEVER Pressione.pressione AND NOT Luce.accesa THEN
  Luce.accesa WITHIN 1 s`.

**The multiplicity of a part (G35).** `telefono : Misuratore [1 .. 4]` states that the entity is made of at least `m` = 1
and at most `n` = 4 copies of the part. Every copy is bound in full by the CSCs that the part provides and uses. The
multiplicity does not state when a copy is present or leaves, how the copies are distinguished or which comes first, nor where
they are located. Without a multiplicity a part counts as `[1 .. 1]`.

| What | Rule |
|---|---|
| Order | only one: first the version (of the named entity), then the multiplicity (of the part). `telefono : Misuratore [1 .. 4] VERSION 0.1` does not respect G34: it is not recognised and is not a part |
| Correct limits | two integers (L13) with 0 <= `m` <= `n` and `n` >= 1: `m` = 0 makes the part **optional** (section 4.10) |
| **E19** | the form G35 is present, but a limit has a dot (`[1.5 .. 4]`), or `m` > `n` (`[4 .. 1]`), or `n` = 0 (`[0 .. 0]`). Line of the part, column of `[` |
| The part with E19 | **remains a part**: it is looked for, it appears under the entity, it counts in the closure (E14, E16, E17) and in section 8 as if the multiplicity were correct. A wrong limit gives a single error, not a cascade of errors. It counts as a **fixed** part (present in every composition), even with `m` = 0 |
| Not G35 | `[1 .. ]`, `[1, 4]`, `[-1 .. 4]` (`-1` is not a Numero, L11), `[1 .. 4` : the declaration does not respect G34, is not recognised and is not a part (like every declaration that does not respect G34, section 5) |
| Closure and section 8 | the line remains **one** part; the match does not change (9.4). The `OFFERS X` of a part does not satisfy its own `USES X` **even with `m` >= 2**: the copies of the same part do not serve one another. Two nodes that serve each other are two parts (`a : Nodo`, `b : Nodo`) |
| In the report | the citation line is written without the multiplicity, as without the version (9.4) |
| In the JSON | the `PART` citation has the field `molteplicita`: `{"min": m, "max": n}` with the two limits as numbers, or `null` if the line does not write one. With E19 the field is present all the same, with the limits as written if they are integers; if a limit has a dot the field is `null` |

An entity with parts must be **closed**: every public boundary is kept by a part on the same side (E16), and
every boundary provided by a part is used by another part or provided by the entity (E17). Closure is checked in every
composition (section 4.10).

The example of the staircase light (the CSCs `Pressione`, `Luce`, `Comando` and the entities `Pulsante`, `Lampada` are
in the same folder, one file each):

```
ENTITY LuceScale VERSION 0.2
  PURPOSE "The staircase light"
  OFFERS Pressione
  OFFERS Luce
  COMPOSED OF
    pulsante : Pulsante
    lampada  : Lampada
  GUARANTEE g1: VERBAL "A press with the light off switches on the light within 1 s"
                VERIFY BY JUDGEMENT "the operator, pressing the button"
END
```

The staircase light provides `Pressione` and `Luce` to the person on the stairs; inside, the lamp uses `Comando`, which the
button provides. The report of this file is in section 9.4.

### 4.10 Variants, optional parts and compositions

An entity can state that one of its functions is performed by one device or another (**variants**), and that a part can
be missing (**optional part**). It then holds for each of its **compositions**, and `check` checks all of them.

| No. | Rule | Example |
|---|---|---|
| G38 | `Variante = "VARIANT" Nome "=" Nome ;` the first name is the **choice group**, the second the **choice** | `VARIANT sensore = di` |

**The segments.** In an `ENTITY` block a G38 line opens a **segment**, which ends at the next `VARIANT` line or at
`END`. The lines before the first segment are the **common lines**. In a segment the following hold: `OFFERS` (G32), `USES` (G33),
`COMPOSED OF` (G28, once per segment: a second one in the same segment is not recognised, without effect), the parts
(G34, optional ones included), `GUARANTEE` (G16, with `DETAILS`) and `SCENARIO` (G19) with the steps. The segments with the same
choice group are the **choices** of that group and exclude one another; they need not stand one after the other. The
choice groups and the choices have names of their own: they do not enter the list of names of the entity (section 5).

| Case | Outcome |
|---|---|
| `VARIANT` in a `CSC` block | **E21**; unrecognised |
| `VARIANT` in an entity that does not respect G38 (`VARIANT sensore`, `VARIANT sensore = di microfono`) | **E21**; unrecognised; it opens a segment all the same, without a choice group: its lines are read (names, short names, degrees), but the entity **has no compositions**: no E22, E23, E14, E16, E17 for it, no entry in sections 8, 9 and 10 |
| `VARIANT` outside a block, in a withdrawn block | unrecognised, without error |
| `PURPOSE` in a segment | **E21**; unrecognised and it does not count for E10 |
| `STATUS` in a segment | unrecognised, without error (like every `STATUS` outside the header zone) |
| `ASSUME`, `CAPABILITY`, `EVENT`, `STATE`, `DEFINE`, `TYPE` in a segment | **E18**, as in the rest of the entity |
| a choice group with a single choice | **E22** on its `VARIANT`; the group counts as a factor of 1 |
| the same choice written twice | **E22** on the second line; the lines of the second segment count as lines of the same choice |
| a segment without any recognised declaration (lines with E01 count; comments, blank lines, unrecognised lines and a `COMPOSED OF` on its own do not count) | **E22** on its `VARIANT`: an empty choice is written with a part `[0 .. 1]` |

**The optional part.** `parte : E [0 .. n]` (G35 with `m` = 0, section 4.9) means “without the part, or with
from 1 to `n` copies”: two compositions, each fixed for the whole trace. In the composition “with” the part counts as
`[1 .. n]`; in the composition “without” it does not provide, does not use and does not count in the closure. It is always looked for. It can stand among the
common lines or in a segment (it is then present only with that choice).

**The factors.** A **factor** is what is chosen when the entity is composed:

| Factor | Values, in order | Name of a value |
|---|---|---|
| a choice group of the entity | the choices, in the order of the first line of each | `D = S` |
| an optional part (without E19) | present, then absent | `with P`, `without P` |
| a choice group of a **found** part whose block has recognised G38 lines (the choices of the part are lifted to the entity) | the choices, in the order of the block of the part | `P.D = S` |

The factors are ordered by line in the checked file: a choice group at the line of its first `VARIANT`, a part
at its line; the choice groups of a part in the order of its block. A factor inside a segment exists only
in the compositions of that choice; the factors of an optional part only in the compositions “with”. **The optional
parts of a part are not lifted**: they do not change its `OFFERS` and `USES` lines, the only ones that are read of a
part (9.4, a single depth).

**The compositions.** A composition has a value for every factor that exists in it. They are listed in
lexicographic order on the factors (the first changes most slowly). The **name** is the list of the values, in order,
separated by `, `: `sensore = di, with di`. An entity without factors has one composition without a name. In every
composition:
- the public boundaries are the common `OFFERS` and `USES` plus those of the chosen segments;
- the parts are the common ones plus those of the chosen segments, minus the absent optional ones;
- a part provides and uses its common lines plus those of its choices. In the block of a part, the lines of the segment
  of a badly written `VARIANT` are neither provided nor used.

**The limit (E23).** The number of compositions is counted before they are listed, with the formula on the factors, and counting
stops as soon as it exceeds **64**. Beyond that: **E23** on the header, column 0; no closure for the entity, no
entry in section 8.

**Closure in every composition.** E14, E16 and E17 (sections 8 and 9.4, with the match of 9.4) are checked
in every composition that has at least one part present, with or without `COMPOSED OF`. In a composition without any
part present (for example when the only part is optional and absent) closure is not checked, as in
an entity without parts. If a part of the entity, in any segment, is not found, E14, E16 and E17 are suspended
for the whole entity. The same error (code, line, column, message) of several compositions is written once,
with the suffix `(in: …)` of section 9.5.

**The declared absence.** Let `C` be a composition with at least one absent optional part, `A` the absent parts and
`C+` the same composition with all the parts of `A` present. An error E14, E16 or E17 of `C` that is **not** present in
`C+` is not an error: it is a **declared absence**, in section 10 of the report. The named part (`without P`) is
every `p` of `A` such that the error is not present in `C` with `p` alone put back; if none suffices on its own, all those of
`A`, in line order, separated by `, `. No other error is ever an absence. The same error can be an
absence in one composition and an error in another: it appears in both places.

**Names, details and scenarios in segments.** Two lines **can stand together** if they do not stand in two different choices
of the same group. E01 between two parts, or between two `OFFERS` (or two `USES`), holds only between lines that can stand
together (section 5); the short names of guarantees and scenarios remain unique throughout the entity. The line named by a
`DETAILS` must stand among the common lines or in the same choice as the detail, otherwise **E02**. In an entity
scenario `X.y` is checked per composition: a scenario of a segment holds with that choice, a common one in all of them;
**E20** with the suffix `(in: …)` where `X` is not a boundary of the composition. E03 does not depend on the composition.

**A line in a segment** is written in the report like the others (citation lines, sections 2-7). The guarantees of
a segment are approved by short name like the others; the `VARIANT` lines are not approved (section 12).

### 4.11 Concrete forms, verification plan, profiles and extensions

A `BINDING` block contains the concrete forms of a boundary, a `VERIFICATION` block the verification plan, a
`PROFILE` block the extensions of a field of use, each in an `EXTENSION` block. `BINDING`, `VERIFICATION` and
`PROFILE` are blocks like `CSC` and `ENTITY`: they stand outside every other block, they end with `END` (G3), and their
header, appearing inside an open block, closes that block with error E07 (section 5). `EXTENSION` stands only
inside a `PROFILE`.

| No. | Rule | Example |
|---|---|---|
| G40 | `IntestazioneBinding = "BINDING" Nome "VERSION" Versione [ "AS" Nome ] ;` the first name is the bound CSC | `BINDING Comando VERSION 0.1`, `BINDING Pressione VERSION 0.1 AS filo` |
| G48 | `IntestazioneVerification = "VERIFICATION" Nome "VERSION" Versione ;` the name is the bound CSC | `VERIFICATION Luce VERSION 0.1` |
| G49 | `IntestazioneProfilo = "PROFILE" Nome "VERSION" Versione ;` | `PROFILE Segnale VERSION 0.3` |
| G50 | `IntestazioneEstensione = "EXTENSION" Nome ;` | `EXTENSION FADE` |
| G51 | `Legame = "BIND" Elemento [ "STATUS" Stato ] ":" "VERBAL" Stringa ;` with `Elemento = Nome [ "." Nome ] ;` | `BIND accesa: VERBAL "the ceiling light emits full light"`, `BIND chiuso.motivo: VERBAL "the text on the display"` |
| G52 | `Mezzo = "MEANS" Nome "OBSERVES" Elemento { "," Elemento } "RESOLUTION" Numero Unita [ "USING" Nome ] ;` | `MEANS telecamera OBSERVES accesa RESOLUTION 40 ms` |
| G53 | `StoriaTradotta = "SCENARIO" Id "TRANSLATES" Id ;` followed by its steps | `SCENARIO s1-filo TRANSLATES s1` |
| G43 | `CampoKind = "KIND" Parola ;` | `KIND PATTERN` |
| G44 | `CampoLevel = "LEVEL" Parola ;` | `LEVEL CSC` |
| G45 | `CampoParams = "PARAMS" "(" [ ParametroEst { "," ParametroEst } ] ")" [ ":" Tipo ] ;` with `ParametroEst = Nome ":" ( Tipo \| Categoria ) ;` and `Categoria = "Name" \| "Type" \| "Event" \| "Condition" \| "Expression" \| "Duration" \| "Property" ;` | `PARAMS (s: Expression, d: Duration)`, `PARAMS (x: Real, a: Real, t: Real) : Boolean` |
| G46 | `CampoVerify = "VERIFY" ( "V1" Controllo { "," Controllo } [ ";" "V2" Stringa ] \| "BY" ( "JUDGEMENT" \| "INSPECTION" ) Stringa ) ;` with `Controllo` one of the words `C1` … `C8` | `VERIFY V1 C1 ; V2 "measurement of s over time"` |
| G54 | `CampoTesto = ( "FORM" \| "MEANING" \| "SOURCE" ) Stringa \| "REDUCES" "TO" RiduzioneEst ;` | `FORM "FADE s WITHIN d"` |

`Parola` in G43 and G44 is any word (L3), reserved ones included: the value is checked afterwards (E33), so that a badly written
value does not disappear among the unrecognised lines. `V1`, `V2` and `C1` … `C8` are read as such only in G46
(section 2.3).

#### The `BINDING` block

```
BINDING Luce VERSION 0.1
  STATUS HYPOTHESIS
  BIND accesa: VERBAL "the ceiling light emits full light"
  BIND modo:   VERBAL "the indicator light on the button: green with the light off, off with the light on"
END
```

- The **header zone** (section 4.2) contains `STATUS` (at most one, E10 if repeated) and `IMPORT PROFILE`. A
  `BINDING` has no `PURPOSE`: a `PURPOSE` line is unrecognised there.
- The body contains `BIND` lines (G51) and uses of extensions of `KIND DECLARATION` and `LEVEL BINDING` of the profiles that
  the block imports (section 4.14). Every other declaration is unrecognised there.
- The **bound CSC** is the CSC named in the header, with the written version. `bcdd` looks for it like a line
  `USES Nome VERSION v` (section 9.4), and reports it under the line of the block or in section 7.
- A `BIND element` line binds an element of the bound CSC to its concrete form, in words. The element is a
  `STATE`, an `EVENT`, a `CAPABILITY` or a `DEFINE` of the bound CSC, or `e.p` with `e` an `EVENT` or a
  `CAPABILITY` and `p` one of its parameters. If the bound CSC is found with the written version and the element is not there, it is
  error **E31**. If the CSC is not found, or is found only in another version, the check is suspended.
- A `BIND` line is not a property: it does not require `VERIFY` and does not give E13; a `VERIFY` line after a `BIND` line opens
  a new declaration, unrecognised (U4). A `BIND` line has no `DETAILS`: it only specifies the element that it
  binds. `BIND accesa DETAILS l1: …` is not recognised.
- Several `BIND` lines for the same element are admitted: they describe different aspects of the same form.
- The `STATE`s, `EVENT`s and `CAPABILITY`s of the bound CSC that no `BIND element` line of the block names are
  listed in section 12 of the report, without error (section 9.6). A `BIND e.p` line does not count for `e`.
- The name of the block does not enter the list of names of the blocks of the file: `BINDING Comando` in the same file as the
  `CSC Comando` is not E01. The name after `AS` is the **distinguishing name** of the block.
- **Several blocks for the same CSC.** In the checked file, two `BINDING` blocks for the same CSC and the same
  version (same text) without `AS`, or with the same name after `AS`, are error **E40** on the second. A
  block without `AS` and one with `AS` for the same CSC and version are admitted.
- A `BINDING` has a status (approved or pending approval), like a CSC: its `STATUS` holds for the `BIND` lines that
  do not have one of their own (section 7.1), and `ratify` approves it (section 12).

#### The `VERIFICATION` block

```
VERIFICATION Luce VERSION 0.1
  MEANS telecamera OBSERVES accesa, modo RESOLUTION 40 ms
  MEANS registratore OBSERVES pressione RESOLUTION 1 ms
  SCENARIO s1-sonda TRANSLATES s1
    @0 s     VERBAL "the finger presses the button"
    @0.5 s   VERBAL "the ceiling light is on"
END
```

- The **header zone** contains only `IMPORT PROFILE`. A `STATUS` at any point of the block, in the
  zone or outside it, is error **E39**: a verification plan is not approved. A `PURPOSE` line is unrecognised there.
- The bound CSC is looked for as for a `BINDING`.
- A `MEANS` line (G52) declares a recording instrument: the name of the instrument, the elements of the bound CSC that it
  observes (the same elements as a `BIND` line, with E31 if they are not there), the resolution, a duration with a unit,
  and with `USING b` the distinguishing name of the `BINDING` through which it observes. The names of the instruments and the short names of the translated
  scenarios stand in a single list: a repeated name is E01.
- `USING b` is a citation: `bcdd` looks for the `BINDING` block of the same CSC and of the same version with the distinguishing
  name `b`, in the order of section 9.4 (the checked file, then the file `NomeCSC.csc` in its folder, then
  the `--dir` folders); if found, it appears under the line of the block; if not found, in section 7.
- A translated scenario (G53) translates the scenario `id` of the bound CSC: if the CSC is found with the written version and
  has no scenario `id`, it is error **E31**. It has neither `GIVEN` nor `EXPECT`: its expected outcome is that of the scenario
  it translates. Its steps follow G21; their elements are assertions in words (`VERBAL`) and uses of extensions of
  `KIND SCENARIO-FORM` and `LEVEL VERIFICATION` (section 4.14). A step with another element is not recognised. E12
  and the repetitions (G47) hold as in the other scenarios.
- A `VERIFICATION` contains neither guarantees nor assumptions: a `GUARANTEE` or an `ASSUME` is unrecognised there. It does not
  have a status, it does not appear in section 4 of the report and `ratify` rejects it (section 12).
- `bcdd` computes the **coverage** of the plan from the `OBSERVES` lines and writes it in section 13 of the report (section
  9.6). The table is not written in the file.
- The name of the block does not enter the list of names of the blocks of the file.

#### The `PROFILE` block and the extensions

```
PROFILE Segnale VERSION 0.3
  PURPOSE "Quantities that vary continuously, measurements on samples, response over time"
  STATUS HYPOTHESIS

  EXTENSION FADE
    KIND     PATTERN
    LEVEL    CSC
    PARAMS   (s: Expression, d: Duration)
    FORM     "FADE s WITHIN d"
    MEANING  "s decreases without rising again and without jumps, and is 0 within d of the first step of the scope"
    VERIFY   V1 C1 ; V2 "recording of s over time"
    SOURCE   "the staircase light, guarantee g10"
  END
END
```

- The **header zone** of a profile contains `PURPOSE` (exactly one: E10 if it is missing or repeated) and
  `STATUS` (at most one: E10 if repeated), in any order. `IMPORT PROFILE` is unrecognised there: a profile
  does not import other profiles. Like every line that begins with `IMPORT` and is not recognised, it does not close the zone
  (section 4.2): a `STATUS` that follows it is still the status of the profile.
- The body contains only `EXTENSION` blocks. Every other declaration (`TYPE`, `DEFINE`, `GUARANTEE`, …) is
  unrecognised there.
- The name of the profile enters the list of names of the blocks of the file: a profile and a CSC with the same name in the
  same file are E01.
- The `STATUS` of the profile holds for all its extensions, which have no `STATUS` of their own. `ratify` approves the
  whole profile (section 12).
- **An `EXTENSION` outside a `PROFILE`** (outside every block, in a CSC, in an entity, in a `BINDING` or in a
  `VERIFICATION`) is error **E32** on the word `EXTENSION`. It opens a block all the same, which ends with its `END`
  (G3): its lines are not recognised and do not register names, as in the withdrawn block of section 4.8. Its
  `END` does not close the block that contains it.

**An extension.** Between the line `EXTENSION Nome` and its `END` stand the fields, in any order, each at most
once. `KIND`, `LEVEL`, `PARAMS`, `FORM`, `MEANING`, `VERIFY` and `SOURCE` are mandatory; `REDUCES TO` is
optional. Every other declaration is unrecognised. What `check` checks:

| Case | Outcome |
|---|---|
| a mandatory field is missing, or its line is not recognised | **E33** `field K is missing in EXTENSION X`, on the `EXTENSION` line, column 0 |
| a field written twice | **E33** `field K repeated in EXTENSION X: the first is at line N`, on the second |
| `KIND` with a value other than `PATTERN`, `SCOPE`, `FUNCTION`, `DECLARATION`, `RELATION`, `SCENARIO-FORM` | **E33** `value of KIND not admitted: V` |
| `LEVEL` with a value other than `CSC`, `ENTITY`, `BINDING`, `VERIFICATION` | **E33** `value of LEVEL not admitted: V` |
| `KIND FUNCTION` without the type of the result after `PARAMS ( … )` | **E33** `EXTENSION X has KIND FUNCTION: after PARAMS the result type is needed, PARAMS (…) : Type` |
| the first word of `FORM` is not the name of the extension | **E33** `FORM must begin with the name of the extension: X` |
| a parameter of `PARAMS` that does not appear in `FORM`, or appears in it more than once | **E33** `the parameter p must appear once in FORM` |
| `VERIFY V1` with a word other than `C1` … `C8` | **E33** `VERIFY V1 names a check that does not exist: W` |
| two extensions with the same name in the same profile | **E34** `extension name already used at line N: X`, on the second |
| the name of the extension is a keyword or reserved word (section 2.3) | **E34** `the name of the extension is a word of the language: X`; the line is recognised as a header, with no name registered |
| `REDUCES TO` names a word that is neither of the language, nor a parameter of the extension, nor another extension of the same profile (the units `s` and `ms` after a number are part of the number, G27, and are not names) | **E35** `REDUCES TO names X: it is not a word of the language, a parameter or an extension of PROFILE P` |
| the extensions of the same profile refer to one another circularly through `REDUCES TO` | **E35** `circular REDUCES TO: A -> B -> A`, on the member of the cycle that comes first in the file |
| `REDUCES TO`, with the parentheses around a single element removed, is **a single construct** of rules G55-G63 (a pattern, a scope, a function, a history expression, a phase, `IF`, an operator such as `NOT`, `AND`, `+`, `<=`), or a single use of another extension, whose operands and places are **all** parameters, each once, in any order, even when the construct begins with a place (`p PRECEDES q`, `(p) PRECEDES q`, `x REQUIRES c`, `ABS(x)`, `MAX(x, y)`, `COUNT(p) IN LAST d`, `requested(x)`, `NOT c`, `x + y`, `(IF c THEN a ELSE b)`). Two extensions with the same reduction apart from the names of the parameters are not reported in this version (section 14) | **E36** `EXTENSION X repeats a form that the language already has: F` (with `F` the first word or the symbol of the construct, for example `NEVER`, `PRECEDES`, `FOR AT LEAST`, `ABS`, `COUNT`, `requested`, `NOT`, `+`, `IF`), or `EXTENSION X repeats EXTENSION Y` |

- **`FORM`** is normative: the text of the string is divided into tokens with the rules of section 2; a word
  equal to the name of a parameter is the **place** of that parameter, every other token is **fixed**. The first word is
  the name of the extension.
- **`PARAMS`**: every parameter has a type (G13) or a **category**: `Name` (a declared name), `Type` (a type),
  `Event` (an event, G62), `Condition` (a `Boolean` expression), `Expression` (an expression), `Duration` (a
  duration with a unit: it is the type `Duration`), `Property` (a whole property, G55). An undeclared type is admitted and
  appears in section 6. The names of the parameters hold only in the extension; two parameters with the same name are
  E01.
- **`REDUCES TO`** (`RiduzioneEst` in G54) is read according to the `KIND`: a property (G55) for `PATTERN`,
  `DECLARATION` and `RELATION`; a scope (G56) for `SCOPE`; an expression (G59) for `FUNCTION`; one or more step
  elements (G22), separated by commas, for `SCENARIO-FORM`. The parameters stand there in place of names, events,
  expressions or properties, according to their category: a parameter of category `Event` stands where an event stands,
  one of category `Property` where a whole property stands (G55), one of category `Type` where a type stands, every
  other where a `Primario` stands (G60). The form `X REQUIRES c` is admitted there: E27 on the `GUARANTEE` holds for contractual
  lines, not for reductions. `check` checks the names (E35) and the form; it does not check the types, which depend
  on the arguments of each use. A reduction that does not respect its rule is not recognised: the field counts as
  present (no E33), but the extension counts as **without** `REDUCES TO` for the degree of its uses (section 4.14),
  and E36 is not checked on it. E35, by contrast, is checked before the form, on every `REDUCES TO` line: a name
  that does not exist is a certain error whatever the form, and the line with E35 remains recognised (section 8). Thus
  `REDUCES TO EVENTUALLY p WITHIN 1 min` gives E35 on `min`, and `WITHIN d s` (with `d` a parameter) gives E35 on `s`, because
  a unit is such only after a number on the same line (G27).
- **`VERIFY`** (G46): with `V1` it lists the checks that can handle the form, with `V2` what counts as an
  observation; or `BY JUDGEMENT` or `BY INSPECTION` with their string. The `;` between the two parts is a symbol
  (L5).
- **The rules by judgement** on extensions (the meaning does not describe the implementation and gives neither authority nor
  precedence among parts; an extension without `REDUCES TO` does not repeat a form that the language already has; `MEANING` and
  `REDUCES TO` say the same thing) are entries of section 14 of the report (section 9.7), never errors.
- An extension with at least one error E33-E36 in its file cannot be used: a block that imports it treats the lines
  that use it as lines with a profile not found (section 4.14).

#### The lines

The lines of these blocks are recognised, comments, blank or unrecognised as in every other block. In the
`blocks:` line of the report a `BINDING`, a `VERIFICATION` and a `PROFILE` count as blocks; an `EXTENSION` does not,
because it stands in its profile. A file that contains only `BINDING`, `VERIFICATION` or `PROFILE` blocks does not have E11.

No block of the language remains unread: section 11 of the report, which listed them, no longer exists, and its
number is not used.

### 4.12 Formulas

A **formula** is a property written in a form that `bcdd` reads in full (G55): an optional scope and a
pattern, with the expressions that compose them. It stands after the colon of a `GUARANTEE` or of an `ASSUME` (G17);
expressions also stand in the value of a `DEFINE` (G12) and in the `REDUCES TO` of an extension (G54).

```
G55  Formula      = { "FOR" "ALL" Nome "IN" Nome ":" } [ Ambito ":" ] Pattern ;
G56  Ambito       = "WHILE" Espr
                  | "AFTER" Evento [ "UNTIL" Evento ]
                  | "BEFORE" Evento
                  | "BETWEEN" Evento "AND" Evento
                  | UsoEstensione ;                                   (KIND SCOPE)
G57  Pattern      = "ALWAYS" Espr
                  | "EVENTUALLY" Espr [ "WITHIN" Espr ]
                  | "WHENEVER" Espr "THEN" Espr [ "WITHIN" Espr | "AT" "ONCE" ]
                  | "NEVER" Espr
                  | Espr "PRECEDES" Espr
                  | Espr "FOR" "AT" "LEAST" Espr
                  | "ACCEPTS" Nome "ONLY" "WHILE" Espr
                  | Nome "REQUIRES" Espr
                  | Nome "ENSURES" Espr
                  | "RESOLVES" Nome "WITHIN" Espr
                  | "TRANSITION" Nome ":" Transizione { "," Transizione }
                  | UsoEstensione ;                                   (KIND PATTERN)
G58  Transizione  = Nome "->" Nome "ON" Evento [ "WHEN" Espr ] ;
G59  Espr         = "FOR" "ALL" Nome "IN" Nome ":" Espr | Implicazione ;
     Implicazione = Logica [ "IMPLIES" Logica ] ;
     Logica       = Negazione { "AND" Negazione } | Negazione { "OR" Negazione } ;
     Negazione    = "NOT" Negazione | Confronto ;
     Confronto    = Somma [ ( "=" | "<>" | "<" | "<=" | ">" | ">=" ) Somma
                          | "IN" "{" Valore { "," Valore } "}" ] ;
     Somma        = Prodotto { ( "+" | "-" ) Prodotto } ;
     Prodotto     = Meno { ( "*" | "/" ) Meno } ;
     Meno         = "-" Meno | Potenza ;
     Potenza      = Postfisso [ "^" Postfisso ] ;
     Postfisso    = Primario { "[" Espr "]" | "." Nome } ;
G60  Primario     = NumeroConSegno [ Unita ] | Stringa | "true" | "false" | "ABSENT"
                  | Nome | "(" Espr ")" | "(" "IF" Espr "THEN" Espr "ELSE" Espr ")"
                  | Funzione | Storia | Fase | Chiamata | "(" Evento ")"
                  | UsoEstensione ;                                   (KIND FUNCTION)
     Funzione     = ( "ABS" | "LOG10" | "ROUND" | "FLOOR" | "CEIL" | "PREV" | "PRESENT" | "CHANGED" ) "(" Espr ")"
                  | ( "MIN" | "MAX" ) "(" Espr "," Espr { "," Espr } ")" ;
G61  Storia       = "COUNT" "(" Evento [ "SINCE" Evento ] ")" [ "IN" "LAST" Postfisso ]
                  | "TIME" "SINCE" Evento
                  | "LAST" "(" Evento ")"
                  | "ONCE" Evento ;
G62  Evento       = RifEvento [ "WITH" Espr ] ;
     RifEvento    = Nome | Fase | "(" Evento ")" ;
     Fase         = ( "requested" | "accepted" | "rejected" | "completed" | "failed" ) "(" Nome [ "." Nome ] ")" ;
G63  Chiamata     = Nome "(" Nome ":" Espr { "," Nome ":" Espr } ")" ;
G64  UsoEstensione = Nome { Elemento } ;      (read according to the FORM of the extension, section 4.14)
```

**How it is read.** The rules of section 4 also hold here: a formula is recognised only if all its
tokens respect G55, with nothing more. Some choices are made by looking one token ahead:
- after `FOR` comes `ALL` (quantification) or `AT LEAST` (G57);
- after `IN` comes `LAST` (G61), `{` (set of values) or, in `FOR ALL i IN T`, the name of a type;
- within parentheses, if `WITH` is present at the first level, the content is an event with a filter (`(frame WITH ch = L)`),
  otherwise an expression;
- a name followed by `(` and by `Nome :` is a call to a `DEFINE` with parameters (G63); a name that is the name of
  an extension of `KIND FUNCTION` of an imported profile is a use of the extension (section 4.14);
- a name that is the name of an extension of `KIND PATTERN` or `SCOPE` of an imported profile, in the position of a
  pattern or of a scope, is a use of the extension.

**Precedence**, from the strongest binding to the weakest:

| Level | Operators | Associativity |
|---|---|---|
| 1 | `x[i]`, `x.campo` | left to right |
| 2 | `^` | **none**: `a ^ b ^ c` is error E26 |
| 3 | `-` in front of a value | right to left |
| 4 | `*`, `/` | left to right |
| 5 | `+`, `-` | left to right |
| 6 | `=`, `<>`, `<`, `<=`, `>`, `>=`, `IN` | **none**: `a <= b <= c` is error E26 |
| 7 | `NOT` | right to left |
| 8 | `AND` and `OR` | the same operator is repeated (`a AND b AND c`); `AND` and `OR` mixed without parentheses are error E26 |
| 9 | `IMPLIES` | **none**: `a IMPLIES b IMPLIES c` is error E26 |
| 10 | `FOR ALL i IN T:` | the body extends to the end of the expression that contains it; inside another expression it stands within parentheses |

Thus `NOT a AND b` is `(NOT a) AND b`, `a AND b IMPLIES c` is `(a AND b) IMPLIES c`, `-x ^ 2` is `-(x ^ 2)` and `x + y * 2`
is `x + (y * 2)`. `e WITH c` takes as its condition the whole expression that follows, up to `SINCE`, `)`, `:` or the
end of the formula: `TIME SINCE (frame WITH ch = L) > 5 s` is written with the parentheses, because without them the
condition would be `ch = L > 5 s`, a chained comparison (E26). `IF … THEN … ELSE` always stands within parentheses:
`DEFINE soglia := (IF notte THEN 10 ELSE 30)`; without parentheses the line is not recognised.

**`IN LAST` binds more tightly than every operator.** The duration of `COUNT( … ) IN LAST d` is a `Postfisso` (G61): a number with a
unit, a name, a function, a call or an expression within parentheses. Thus `ALWAYS COUNT(accendi) IN LAST 0.2 s
<= 1` is `(COUNT(accendi) IN LAST 0.2 s) <= 1`, and `COUNT(frame) IN LAST EVAL / (fs * EVAL)` divides the count. A
computed duration is written within parentheses: `COUNT(e) IN LAST (2 * DURATA) > 3`.

**A phase with the qualified name.** `Fase` (G62) admits `Nome "." Nome` for entity formulas, where the first
name is a connector (section 4.9): `requested(Sessione.Abbina)`. In a CSC a phase with the qualified name is
error **E20** with the message for the CSC (section 4.6), even when the first name is a request of the CSC
itself. After a phase, `WITH` stands only where an event stands (G62) or inside the parentheses of `"(" Evento ")"`:
`ALWAYS requested(Pulizie) WITH f = "x"` is not recognised, like `ALWAYS e WITH c`.

**Errors of form.** A formula that `bcdd` reads in full and that violates a rule of the language gives an error; the
declaration remains recognised, as with E13:

| Case | Error |
|---|---|
| `AND` and `OR` at the same level without parentheses | **E26** `AND and OR together without parentheses: write (a AND b) OR c, or a AND (b OR c)`, on the first operator that changes |
| `IMPLIES` after `IMPLIES` without parentheses | **E26** `IMPLIES after IMPLIES without parentheses: write a IMPLIES (b IMPLIES c)`, on the second |
| a comparison after a comparison without parentheses | **E26** `chained comparisons: write a <= b AND b <= c`, on the second |
| `^` after `^` without parentheses | **E26** `^ after ^ without parentheses: write (a ^ b) ^ c`, on the second |
| a pattern word (`ALWAYS`, `EVENTUALLY`, `WHENEVER`, `NEVER`, `ACCEPTS`, `RESOLVES`, `TRANSITION`) where an expression stands, or `PRECEDES`, `FOR AT LEAST`, `REQUIRES`, `ENSURES` inside the operand of another pattern | **E27** `K inside another form: the language does not nest ALWAYS, EVENTUALLY, WHENEVER and their shorthands`, with `K` the nested word |
| a second scope after the first (`WHILE c: AFTER e: …`) | **E27** `a property has a single scope: K is the second` |
| `WITHIN … AT ONCE` in the same pattern | **E27** `WITHIN and AT ONCE in the same property: choose one` |
| `X REQUIRES c` in a `GUARANTEE` | **E27** `REQUIRES is used only in an ASSUME: in a GUARANTEE write ALWAYS (requested(X) IMPLIES c)` |

Every other form that does not respect G55-G64 (for example `ALWAYS p WITHIN 1 s`, `WHENEVER p` without `THEN`, an
extra parenthesis, `MIN(x)` with a single argument) is not recognised, without error. Line and column of E26 and E27:
those of the word or symbol indicated. A formula with E26 or E27 does not give E25: the types of a formula of wrong
form are not certain. The names are checked in it all the same (E24, E29).

**The BASE forms.** In the language specification **BASE** is the set of the shorthands (manual, chapter 23):
`NEVER`, `AFTER`, `BEFORE`, `AFTER … UNTIL`, `BETWEEN … AND`, `PRECEDES`, `FOR AT LEAST`,
`ACCEPTS … ONLY WHILE`, `REQUIRES`, `ENSURES`, `RESOLVES`, `ONCE`, `CHANGED`, `TRANSITION`, `FOLLOWS` (G11), the
indices (G11, G20), `FOR ALL` and `REPEAT m..n` (G47). Their meaning is the expanded form of the
manual. `check` reads them as forms in their own right and checks their names and types; it does not write the expanded form. `TRANSITION s: A
-> B ON e [WHEN c], …` is a single guarantee on a closed set of transitions of the state `s`: `s` is a `STATE`
with a list of values as its type, `A` and `B` are values of that list, `e` is an event, `c` a condition.

**`FOR ALL i IN T`.** `T` is a finite type (the same as in section 4.3 for indices: E29 otherwise); `i` holds
in the body and must not be a name of the block (E01). At the head of a formula (G55) it quantifies the whole property;
inside an expression (G59) it quantifies the condition that follows.

### 4.13 Names and types

`check` statically checks the **names** and the **types** of formulas, of the expressions of `DEFINE`s, of
declarations (G11) and of the values of scenarios. It computes no value: it knows that `COUNT(e)` is an integer, not what it
amounts to.

**Names.** A name in a formula of a CSC is, in order: a variable of a `FOR ALL` that contains it; a
parameter of the `DEFINE` that contains it; a parameter of the event of `e WITH c`, inside `c`; a name of the block
(section 5); the name of an extension of the imported and found profiles (section 4.14). Otherwise, if the block
imports a profile not found, the declaration is not recognised, with the reason (section 4.14); if not, it is error
**E24** `name not declared: X`. A name written only in an unrecognised declaration (for example `EVENT IN
pressione FACE utente`) is not a name of the block (section 4.5): a formula that uses it gives E24, as a step gives E03.
The error indicates the line to correct; the badly written declaration is in section 5 of the report. Every position
requires a **kind**:

| Position | Kind required | Error if the name is of another kind |
|---|---|---|
| an event: `AFTER`, `BEFORE`, `UNTIL`, `BETWEEN … AND`, `ON`, `COUNT( … )`, `SINCE`, `TIME SINCE`, `LAST( … )`, `ONCE`, to the left of `WITH` | an `EVENT`, a `DEFINE EVENT` or a phase of a request | **E24** `X is not an event: an EVENT, a DEFINE EVENT or a phase of a CAPABILITY is needed` |
| a request: inside a phase (`requested(X)` …), `ACCEPTS X`, `X REQUIRES`, `X ENSURES`, `RESOLVES X` | a `CAPABILITY` | **E24** `X is not a CAPABILITY` |
| a state: the state of `TRANSITION`, the argument of `PREV` and of `CHANGED` | a `STATE` (also with an index or with a field) | **E24** `X is not a STATE` |
| a value or a condition: every other position | a `STATE`, a `DEFINE` without parameters, a variable or a parameter, a value of a list of values, an event (only as a condition), a name given by an extension | **E24** `X is a CAPABILITY: it is named with a phase (requested(X), …) or in ACCEPTS, REQUIRES, ENSURES, RESOLVES`, for a request; a type, a scenario or a short name give `X is not a value` |
| a field: `x.c`, `LAST(e).c` | a field of the `Record` of `x`, or a parameter of `e` | **E24** `name not declared as a field of T: c` |
| a call `name(p: a, …)` | a `DEFINE` with parameters; every `p` one of its parameters, each once | **E24** `X is not a DEFINE with parameters`; `name not declared as a parameter of X: p`; `the argument p is missing in the call to X`. If an argument has a name that is not a parameter, the call gives only that error, without `the argument … is missing`: a wrong name is a single error. Two arguments with the same name are E01 |
| an index: `x[i]` | a value of the type of the index of `x`, or a variable of `FOR ALL` over that type | **E29** `index of X not of type T: v`, even when `v` is not declared: the message states what is needed |

Line and column of E24: those of the name. With a qualified name (in an entity, section 4.9) those of `X`.

**Types.** Every expression has a type: `Boolean`, `Integer`, `Real`, `Duration`, `String`, a list of values, a
`Record`, `Sequence of T`, `Optional T`, or an **unknown** type. An unknown type is that of an undeclared
type, of a type described in words (G30), of an `UNDECIDED` constant, of a name given by an extension, and,
in an entity formula, of every element `X.y` of a cited CSC (section 4.9). An expression of unknown type is accepted
in every position, and the result of an operation on it has an unknown type: `check` does not give errors that are not
certain.

| Expression | Type |
|---|---|
| a number without a dot, without a unit | `Integer` |
| a number with a dot, without a unit | `Real` |
| a number with `s` or `ms` | `Duration` |
| a string | `String` |
| `true`, `false`; a comparison; `NOT`, `AND`, `OR`, `IMPLIES`; `IN { … }`; `PRESENT(x)`; `CHANGED(x)`; `ONCE e`; an event used as a condition (true in the step in which it occurs) | `Boolean` |
| `ABSENT` | `Optional` of any type |
| a value of a list of values | that list |
| a state, a constant, a parameter, a field | its type; with a name given by G41, the named type; `Integer [a .. b]` and `Real [a .. b]` count as `Integer` and `Real` (the limits do not propagate) |
| `COUNT( … )`, with or without `IN LAST` | `Integer` |
| `TIME SINCE e` | `Duration` |
| `LAST(e).p` | the type of the parameter `p` |
| `PREV(x)` | the type of `x` |
| `(IF c THEN x ELSE y)` | the type of `x` and of `y`, which must have the same type (`Integer` and `Real` give `Real`) |
| `a + b`, `a - b` | `Integer` if both are `Integer`, `Real` if they are numbers, `Duration` if both are `Duration` |
| `a * b` | as `+` for two numbers; `Duration` for a duration and a number, in either order |
| `a / b` | `Real` for two numbers; `Duration` for a duration divided by a number; `Real` for two durations |
| `a ^ b`, `LOG10(a)` | `Real`; the operands are numbers |
| `- a`, `ABS(a)` | the type of `a`, number or duration |
| `ROUND(a)`, `FLOOR(a)`, `CEIL(a)` | `Integer`; the operand is a number |
| `MIN( … )`, `MAX( … )` | the common type of the arguments, all numbers or all durations |
| a call `name( … )` | the type of the expression of the `DEFINE`; every argument has the type of its parameter |
| a use of an extension of `KIND FUNCTION` | the type of the result in `PARAMS` |

| Position | Type required |
|---|---|
| condition: `WHILE`, `ALWAYS`, `EVENTUALLY`, `WHENEVER` and `THEN`, `NEVER`, the two parts of `PRECEDES`, the left part of `FOR AT LEAST`, `ONLY WHILE`, `REQUIRES`, `ENSURES`, `WHEN`, `WITH`, the condition of `IF`, the operands of `NOT`, `AND`, `OR`, `IMPLIES`, the body of `FOR ALL` inside an expression, the value of a `DEFINE EVENT` | `Boolean` |
| duration: `WITHIN`, `IN LAST`, the right part of `FOR AT LEAST`, `RESOLVES … WITHIN` | `Duration` |
| `=` and `<>` | two operands of the same type: two numbers, two durations, two strings, two `Boolean`s, two values of the same list; `Optional T` with `T` or with `ABSENT` |
| `<`, `<=`, `>`, `>=` | two numbers or two durations |
| `x IN {v, …}` | every `v` is a value of the type of `x` |
| `x[i]` | `x` has an index, and `i` is a value or a variable of `FOR ALL` of the type of the index (E29) |
| `PRESENT(x)` | `x` of type `Optional` |

In every other position an expression `Optional T` counts as `T`: `check` does not track whether the value is present. Thus, with `c`
of type `Optional Campione` and `Campione` a `Record`, `c.L` is the field `L` of the record.

An expression of the wrong type is error **E25** `inconsistent type: A needed, B found`, with `A` and `B` written
as in the table (`Boolean`, `Duration`, `a number`, `a number or a duration`, the name of a list of values, …;
an event in a value position is written `an event`). Line and column: those of the first token
of the expression. Examples: `EVENTUALLY accesa WITHIN 60` gives `inconsistent type: Duration needed, Integer found`;
`ALWAYS COUNT(pressione)` gives `inconsistent type: Boolean needed, Integer found`; `WHENEVER pressione THEN fase =
accesa`, with `accesa` from another list of values, gives `inconsistent type: Fase needed, Modo found`.

**Written values.** The same types are compared with the written values (G26) in `INITIAL` (G11), in the `GIVEN` and
in the assignments of scenarios (G20) and in the arguments of events in steps (G25):

| Declared type | Admitted values |
|---|---|
| `Boolean` | `true`, `false` |
| `String` | a string |
| `Duration` | a number with `s` or `ms` |
| `Integer [a .. b]` | a number without a dot and without a unit, between the written limits (inclusive; an omitted limit does not limit) |
| `Real [a .. b]` | a number without a unit, between the written limits |
| a list of values `E` | a value of `E` |
| `Optional T` | `ABSENT`, or a value admitted for `T` |
| `Record`, `Sequence of T` | none: in steps `_` is written |
| an unknown type | any value |

A value not admitted is error **E25** `value not of type T: V`, with `T` the type as written in the
declaration and `V` the value as written; line and column those of the value. A name that is not a value of any
list of values of the block remains error E03 (section 4.4), without an additional E25. `_` is always admitted in
arguments. In an entity scenario the rule of section 4.6 applies.

### 4.14 The use of extensions

A block uses the extensions of the profiles that it imports in its header zone (section 4.2), and only those:
an extension of a profile that is not imported does not exist for the block, even if the profile stands in the same file.

**Where a use is recognised.** A name is a use of an extension when it is the name of an extension of an imported
and found profile, and stands in the position that its `KIND` provides for:

| `KIND` | Position |
|---|---|
| `PATTERN` | the place of the pattern in a formula (G57) |
| `SCOPE` | the place of the scope in a formula (G56), followed by `:` |
| `FUNCTION` | the place of a `Primario` in an expression (G60) |
| `DECLARATION` | the first word of a declaration of the block |
| `RELATION` | the first word of a declaration of an entity |
| `SCENARIO-FORM` | the place of an element of a step (G22) |

The block must be of the `LEVEL` of the extension: `CSC` in a CSC, `ENTITY` in an entity, `BINDING` in a
`BINDING`, `VERIFICATION` in a `VERIFICATION`. An extension used in a block of another level, or in a
position of another `KIND`, is error **E37** `X has LEVEL L: it is not used in a B block` or `X has KIND K: it is not
used in this position`.

**How a use is read.** The tokens that follow the name are compared with the `FORM`: every fixed token must
be present, identical; every place of a parameter takes an argument, which is read up to the next fixed token
of the `FORM` (or, for the last place, up to the end of the position: the end of the formula, of the declaration or
of the step element; within parentheses, the `)` or the `,` at the same level that closes or separates what contains
the use). Thus `MAX(SQ r, 1.0)` and `(SQ r) > 1.0` are read, whereas `SQ r > 1.0` gives `SQ` the argument `r > 1.0`. A
`FORM` of `KIND FUNCTION` that ends with a fixed token (`"NEAR ( x , a , t )"`) does not have this problem. The argument must be of the category or of the type of the parameter:

| The parameter | The argument |
|---|---|
| `Name` | a name of the block; in a use of `KIND DECLARATION`, the first `Name` place of the `FORM` is instead the **name declared** by the line (see below) |
| `Type` | a type (G13) |
| `Event` | an event (G62) |
| `Condition` | a `Boolean` expression |
| `Expression` | an expression |
| `Duration` | a `Duration` expression |
| `Property` | a property (G55) |
| a type | an expression of that type; an undeclared type accepts any expression |

A use that does not respect the `FORM` is error **E37** `use of X that does not respect FORM "F"`, on the name; an argument of
a wrong category gives E24 or E25 as in a formula. Example, with the profile `Segnale` of section 4.11
imported: `GUARANTEE g10: WHILE modo = spenta: FADE luminosita WITHIN 2 s` uses `FADE`, with `s` = `luminosita` and
`d` = `2 s`.

**Names declared by an extension.** In a use of `KIND DECLARATION` (for example `SIGNAL needle[Ch] : Real [0.0
.. 1.0]`, with `FORM "SIGNAL nome[I] : T"`), the argument of the first `Name` place is a new name of the block: it enters
the list of names (E01 if repeated) and is used in formulas as a value or as a condition, with an unknown type and with
or without an index, without a check. It is neither an event nor a request. A use of `KIND DECLARATION` that does not respect the
`FORM` is error E37 on the name of the extension: the declaration remains recognised (section 8) but registers
no name, because it is not known which token is the name; where that name is used there is E24, as for a name written
only in an unrecognised declaration (section 4.13). The name of an extension of `KIND PATTERN`, `SCOPE` or
`FUNCTION` as the first word of a declaration is error E37 `X has KIND K: it is not used in this position`, and the
declaration remains recognised.

**The degree.** The extensions that a formula uses are all those that appear in it, also inside the argument of
another use (`DURING (NEAR r TO 1.0): …` uses `DURING` and `NEAR`), plus those used, at any depth, by the
`DEFINE`s that the formula names (constants, calls, `DEFINE EVENT`): with `DEFINE K := SQ r`, `ALWAYS K > 0.0` uses
`SQ`. This set counts for the degree, for section 15 of the report (section 9.7) and for the status (point 0a of
section 7.1). A formula that uses at least one extension without a recognised `REDUCES TO` is of degree **declared
extension**; if all the extensions it uses have a recognised `REDUCES TO` it is **formal** (section 6).

**The uses that this version does not read.** `bcdd` 1.0-beta does not read the uses of extensions of `KIND RELATION` and
`KIND SCENARIO-FORM`. An entity declaration that begins with the name of a `RELATION` extension, and a step
with an element that is a use of a `SCENARIO-FORM` extension, are not recognised and appear in section 5
of the report (with `--strict`, code 3). These uses declare no names, so they leave no errors in the lines that
follow (section 14).

**A profile not found.** If a block imports a profile that `bcdd` does not find (section 4.2), or a profile with an
extension that has errors in its file, a declaration of the block that contains a name that does not resolve otherwise (a name that
section 4.13 would give as E24, or the first word of a declaration that no rule of section 4 accepts)
**is not recognised**, with the reason in section 5 of the report: ` (profile P VERSION v not found)` or
` (EXTENSION X of PROFILE P with errors)`. It is not an error: the name might come precisely from that profile, and an
error is reported only when it is certain. With `--strict` the line makes the program exit with code 3.

**The status.** A contractual line that uses an extension of a profile **pending approval** is pending approval, even in an
approved CSC (section 7.1).

**Total: 13 rules of the words (L1-L13), 5 rules of division (U1-U5), 64 rules of declarations (G1-G64,
with G12a and the variants G20e, G23e, G24e of entity scenarios). G30, G37, G41 and G42 are in section 4.4; G36 and
G47 in 4.6; G31-G35 in 4.9; G38 in 4.10; G39 in 4.2; G40, G43-G46 and G48-G54 in 4.11; G55-G64 in
4.12. G2 serves only the report of a withdrawn block and G29 holds nowhere (section 4.8); the numbering is
preserved.**

---

## 5. Where each declaration holds

A declaration written correctly but in the wrong place is not recognised.

| Where | What is recognised there | Notes |
|---|---|---|
| **Outside a block** | G1, G31, G40, G48, G49 | `END` here is error E08; a declaration that begins with `REFINEMENT` is error E15 and opens a withdrawn block (section 4.8); one that begins with `EXTENSION` is error E32 (section 4.11); everything else is unrecognised |
| **Inside `CSC … END`** | G3, G4, G6, G7, G8, G11, G12, G16, G19, G21, G30, G37, G39, G41, G47, uses of extensions of `KIND DECLARATION` and `LEVEL CSC` | see the three following rows; a declaration that begins with `CSC`, `ENTITY`, `REFINEMENT`, `BINDING`, `VERIFICATION` or `PROFILE` closes the CSC with E07; one that begins with `EXTENSION` is E32; G32, G33 and G34 are unrecognised there. A qualified name in a scenario is E20 (section 4.6) |
| — `STATUS`, `IMPORT PROFILE` | at any point of the header zone, in any order with `PURPOSE` (section 4.2); `STATUS` at most once | a second `STATUS` in the zone is E10; after the zone they are not recognised |
| — `PURPOSE` | exactly one per CSC | if it is missing or repeated: E10 |
| — `@` steps and `REPEAT` | only after a line that begins with `SCENARIO` (even if that line is not recognised), with only steps, `REPEAT` lines (G47), comments and blank lines between the two | every other declaration closes the scenario; a `REPEAT` line outside a scenario is not recognised |
| **Inside `BINDING … END`** | G3, G4, G39 in the header zone, G51, uses of extensions of `KIND DECLARATION` and `LEVEL BINDING` | section 4.11; `CSC`, `ENTITY`, `REFINEMENT`, `BINDING`, `VERIFICATION` and `PROFILE` close the block with E07; `EXTENSION` is E32 |
| **Inside `VERIFICATION … END`** | G3, G39 in the header zone, G52, G53 with its steps G21 and the lines G47, uses of extensions of `KIND DECLARATION` and `LEVEL VERIFICATION` | `STATUS` is E39 at any point; for the rest as in a `BINDING` |
| **Inside `PROFILE … END`** | G3, G4 and G6 in the header zone, G50 which opens an extension | every other declaration is unrecognised; `CSC`, `ENTITY`, `REFINEMENT`, `BINDING`, `VERIFICATION` and `PROFILE` close the profile with E07 |
| **Inside `EXTENSION … END`** (in a profile) | G3, G43, G44, G45, G46, G54 | every other declaration is unrecognised; `CSC`, `ENTITY`, `REFINEMENT`, `BINDING`, `VERIFICATION` and `PROFILE` close the extension and the profile, with one E07 on the profile |
| **Inside a withdrawn block** (`REFINEMENT …` up to `END`) | only G3 | every other declaration is unrecognised and registers no names; `CSC`, `ENTITY` and `REFINEMENT` close the block with E07 (section 4.8) |
| **Inside `ENTITY … END`** | G3, G4 only with `STATUS HYPOTHESIS`, G39 in the header zone, G6, G32, G33, a single G28, G34, G16 with `GUARANTEE` (with every `STATUS`, as in the CSC, and with the formulas of section 4.9), G19, G21 and G47 with the qualified names (section 4.6), G38 (section 4.10), uses of extensions of `KIND RELATION` and `LEVEL ENTITY` | see the six following rows. `OFFERS` and `USES` at any point. The words that open a block close the entity there with E07, as in the CSC; `EXTENSION` is E32 |
| — `VARIANT` segments | from a G38 line to the next one or to `END`: G32, G33, one G28 per segment, G34, G16 with `GUARANTEE`, G19 and G21 | `PURPOSE` is E21; the other cases are in section 4.10. In a `CSC` block a declaration that begins with `VARIANT` is E21 |
| — `STATUS` | only `STATUS HYPOTHESIS`, at any point of the header zone (section 4.9); a second `STATUS HYPOTHESIS` in the zone is E10 | every other `STATUS`, including a valid `STATUS RATIFIED BY D-n` and `STATUS RATIFIED` without a decision, is not recognised, **without** E04; the status of the block remains `without STATUS`: the header of an entity is never approved. **Inside a `GUARANTEE`** the `STATUS`es of the CSC hold: `STATUS HYPOTHESIS`, `STATUS RATIFIED BY D-n`, and `STATUS RATIFIED` without a decision with E04 (the guarantee remains recognised and pending approval) |
| — `PURPOSE` | exactly one per entity | if it is missing or repeated: E10 |
| — G34 parts | at any point of the entity, also without `COMPOSED OF` | every declaration that respects G34 is a part; `COMPOSED OF` is written only once, wherever one wishes, and a second one is not recognised, without effect. The rules, the reasons and the edge cases are immediately below the table |
| — `SCENARIO`, `@` steps | recognised with G19, G21 and the variants G20e, G23e, G24e (section 4.6) | as in the CSC: the steps only after a line that begins with `SCENARIO`, with only steps, comments and blank lines between the two |
| — `ASSUME`, `CAPABILITY`, `EVENT`, `STATE`, `DEFINE`, `TYPE` | **not** recognised, and **error E18** on the keyword, whatever follows it | an entity has no elements of its own. They register no name, not even `ASSUME` with a valid line header nor `DEFINE Nome :=`, and they do not appear in section 2. The `VERIFY` and `VERBAL` lines that continue an `ASSUME` (U4) remain unrecognised with it, without another E18. Cases below the table |

**Error E18.** An entity has no `CAPABILITY`, `EVENT`, `STATE`, `DEFINE`, `TYPE` or `ASSUME` of its own: `bcdd` reads
the keyword and knows that it is out of place, so it is an error, like E15. Edge cases:
- `ASSUME` with an invalid line header (`ASSUME : …`), or with a property written as a formula: E18,
  because the keyword at the head is enough;
- `assume` in lower case is not the keyword (2.2): it remains unrecognised, without E18;
- inside a withdrawn block no E18: there every declaration is unrecognised (4.8);
- in an entity with an invalid header (E09) E18 holds all the same: the block opens in any case;
- a `DETAILS` that names the short name of an `ASSUME` with E18 gives E02: the `ASSUME` does not register its short name;
- `SCENARIO` and the steps are not in E18: an entity has scenarios.

What a guarantee of the entity takes for granted about the other side of a boundary is written as an assumption
(`ASSUME`) in the CSC of that boundary. A guarantee of the entity is written as a `GUARANTEE` of the entity or in the CSC
that the entity provides.

**The parts of an entity.** In an entity **every declaration that respects G34 is a part, wherever it stands**: before or
after `COMPOSED OF`, among the guarantees, after `OFFERS` and `USES`, after unrecognised lines, after a second
`COMPOSED OF`, and also in an entity that has no `COMPOSED OF`. There is no list that opens and closes: the parts
stand wherever one wishes, like `OFFERS` and `USES`.

- **`COMPOSED OF`** (G28), the parts list, is written only once: it tells the reader that the entity is made of
  parts. `bcdd` does not need it: a part without `COMPOSED OF` is checked like the others. The reason: no correctly written part
  must remain unchecked, and if `COMPOSED OF` were necessary, forgetting it would remove the check from
  all the parts of the entity. The other option, an error for a part without `COMPOSED OF`, would give an error on a
  line that `bcdd` reads in full and checks in any case.
- **A second `COMPOSED OF`** is not recognised, and has no effect on the parts. It is not an error: it states
  nothing wrong, it only repeats.
- **A declaration that does not respect G34** is not a part: if it is not another declaration of the entity
  (table above), it is not recognised. It registers no name, it is not looked for, it does not appear under the entity or in
  section 7, it does not count among the parts not found (so it does not suspend E14) and it does not change the way in which
  any other declaration is read. Of this type are, for example: `pulsante-uno : Pulsante`, `p : X VERSION v1`,
  `pulsante Pulsante`, `pulsante uno : X`, `pulsante := X`, `"pulsante" : X`, `FOO bar`, `offers Luce`, `OFFERS :
  Pulsante`, `VERSION 0.1`, `LINK a b`, `END X`, and `VERIFY` or `VERBAL` after a part (U4: they continue only a
  `GUARANTEE` or an `ASSUME`).

**Why no case remains** in which a G34 declaration inside an entity does not become a checked part,
or an unrecognised line removes the check from a part. A declaration is a part if and only if (1) it is a
declaration (section 3), (2) it stands in an `ENTITY` block (section 5), (3) it respects G34 and (4) its name does not have E01.
None of these four conditions depends on whether another declaration is recognised or not, except in the cases
below, each with a signal outside section 5 or excluded from entities by construction:

| Case | What happens | Signal |
|---|---|---|
| the text `p : X` stands **inside a string** that breaks across lines | it is not a declaration (L2, U3): it is text | none, as a matter of principle: a string can contain any text. With a single quotation mark too many or too few in the file, the quotation marks outside comments are odd in number and `bcdd` signals E06. A stretch of lines becomes a string without errors only with **two** wrong quotation marks. Known limitation |
| the name of the part is repeated, or is the short name of a guarantee (also of an unrecognised guarantee with a valid G16 line header, section 4.5) | the part is not looked for | **E01**, code 1 |
| an `END` on its own before the part | the entity has ended: the line is outside a block | if the `END` of the entity comes afterwards, **E08** |
| a `CSC`, a `REFINEMENT` or an `ENTITY` before the part | it closes the entity and opens another block | **E07** (and **E09** if the header is badly written; with `REFINEMENT`, **E15**) |
| a part not found | it suspends E14 for its entity | it is in **section 7**, with the reason if there is one |
| `p : X` in a CSC or in a withdrawn block | it is not an entity: it is not recognised (a CSC has no parts; a withdrawn block has no parts, section 4.8) | outside entities, by construction |

The case that remains: an entity in which no line is a part has no entries in section 8 and no E14, and without
`--strict` an unrecognised line does not change the code.

Other rules on blocks:
- `END` must stand alone on its line (a comment after it is acceptable). `END` followed by anything else is not
  recognised and the block remains open.
- A `CSC`, a `REFINEMENT`, an `ENTITY`, a `BINDING`, a `VERIFICATION` or a `PROFILE` inside an open block
  (also inside an extension, which closes with its profile) closes that block with error E07 and opens the new one.
- A badly written block header (error E09) opens the block all the same, so the lines that follow
  are read normally instead of all becoming foreign. This holds for `ENTITY`, `BINDING`, `VERIFICATION`, `PROFILE`
  and `EXTENSION` as for `CSC`. A declaration that
  begins with `REFINEMENT` (E15) opens the withdrawn block, well written or not (section 4.8).
- A file can contain several blocks. The names of the `CSC`, `ENTITY` and `PROFILE` blocks of a file are not repeated,
  whatever the type: a CSC and an entity with the same name in the same file are E01. A withdrawn block, a
  `BINDING` and a `VERIFICATION` do not register their name (their name is that of the bound CSC).
- **Names in an entity.** The names of the parts and the short names of guarantees and scenarios stand in a single list:
  a repeated name is E01. The names of the `OFFERS` lines stand in a list of their own, and so do those of the `USES` lines.
  **Several versions**: two `OFFERS` lines with the same name are E01 on the second **unless** both write
  `VERSION` and the versions differ as text; the same for `USES`. Hence `OFFERS Pulsanti VERSION 0.1` and
  `OFFERS Pulsanti VERSION 0.2` are admitted; `OFFERS Pulsanti VERSION 0.1` twice is E01; `OFFERS Pulsanti` and
  `OFFERS Pulsanti VERSION 0.2` are E01 on the second (the line without a version holds for every version, so it
  repeats it), in either order. The entity provides each version in full; how the versions coexist is stated by
  no line. `OFFERS X` and `USES X` in the same entity are admitted (for example a device on a bus).
  **With `VARIANT` segments** (section 4.10): two parts with the same name, and two `OFFERS` (or two `USES`) with the
  same name, are compared with the rules above only if they **can stand together**, that is if they do not stand in two
  different choices of the same group: `microfono` in `sensore = di` and in `sensore = microfono` is acceptable, `OFFERS X`
  among the common lines and again in a segment is E01. The short names of guarantees and scenarios, and a part with the same
  name as a short name, are E01 in any segment. The message names the first line of the file with that name that
  can stand together with the line of the error.
- **A line with E01 in an entity** (an `OFFERS`, a `USES` or a part) neither provides nor requires anything:
  it is not looked for, it does not appear under the entity, in section 7 or in section 8, and it does not count in the match (section
  9.4), either in the checked file or in the found block of a part. The first line with that name always holds.
- Rule U4 also holds in the entity: `VERIFY` and `VERBAL` continue a `GUARANTEE` or an `ASSUME` (and
  the `ASSUME` remains unrecognised with its continuations).
- An entity `GUARANTEE` with a valid G16 line header and a non-`VERBAL` property registers its short
  name and is of degree `unrecognised`, as in the CSC; E13 also holds in the entity.
- The names declared in a block hold only in that block. In a CSC block requests, events, states,
  constants, types, guarantees, assumptions, scenarios and the values of the lists of values share **a single list of
  names**: two different elements with the same name are error E01. The names of the parameters hold only in their
  line.
- A declaration can name an element declared further on in the block.

---

## 6. The degree of a guarantee

**Rule.** The degree of a `GUARANTEE` or of an `ASSUME` is read from its form; no line carries a degree
label:

| Degree | When |
|---|---|
| `verbal` | the property is `VERBAL "…"` with its verification (G17), or `VERBAL "…"` without verification, with error E13 |
| `formal` | the property is a recognised formula (G55) that uses no extensions, or uses only extensions with `REDUCES TO` |
| `declared extension` | the property is a recognised formula that uses at least one extension without `REDUCES TO` |
| `unrecognised` | the property is not recognised: a formula in a form that section 4.12 does not provide for, or a line with a name that only a profile not found could supply (section 4.14). The short name exists if the line header is valid |

A formula with an error (E24-E30, E37) remains recognised and has its degree: the form has been read, a name or a type is
wrong, and the error states it.

**What “formal” means.** The degree states how the guarantee can be verified, not that it has been verified.
`check` reads the formula and checks its form, names and types; it does not evaluate it on the scenarios, and it does not check that the guarantees
are consistent with one another or with the details. These checks are declared “not executed” in the report (section
9.7). No outcome is worth more than what has actually been checked.

**Why the short name remains even in an unrecognised line.** If the short name were not registered, for a detail of that
line (`GUARANTEE g5 DETAILS g1`) `bcdd` would signal E02 (`DETAILS names an id that is neither a GUARANTEE nor an ASSUME of
this CSC: g1`), a spurious error. Moreover two lines with the same short name would not give E01.

**A formula over several lines** is written by leaving the line open (U5): `WHENEVER pressione THEN` at the end of a line, and
`accesa WITHIN 1 s` on the following line, form a single declaration. A line that begins with `THEN` does not continue the
previous one: it opens a new declaration (U2), and the formula is unrecognised.

## 7. Approved lines and lines pending approval

Section 7.1 defines the status of every contractual line. Sections 7.2-7.4 state how a CSC changes over
time: a new version, the levels of details, a replaced line.

### 7.1 The effective status of a line

Every contractual line (a `GUARANTEE` or `ASSUME` with a recognised line header) has an **effective
status**: approved or pending approval. It is decided as follows, in this order:

0. if the line is in a block, **CSC or entity**, whose header is not valid (it does not respect G1 or G31: error
   E09), it is **pending approval**, whatever `STATUS` the line and the header have;
1. if the line has its own valid `STATUS RATIFIED BY D-nnn`, it is **approved**;
2. if the line has its own `STATUS HYPOTHESIS`, or a `STATUS RATIFIED` without a valid decision (error E04),
   it is **pending approval**;
3. if the line has no `STATUS` and is a detail (`DETAILS`), it is **pending approval**: a detail does not inherit
   the approval of the CSC;
4. otherwise the `STATUS` of the CSC header applies: approved if it is a valid `RATIFIED BY D-nnn`; **pending
   approval** in every other case, including when there is no `STATUS`. (After point 0 the header here is always valid.)

Point 3 exists so that a detail added after the approval of a CSC does not silently become approved.

**A profile pending approval.** Point **0a** applies before point 1: a contractual line that uses an extension of
a profile that is found and **pending approval** (its `STATUS` is not a valid `RATIFIED BY D-nnn`) is pending approval, whatever
`STATUS` the line and the header have. The meaning of the extension has not been approved, and therefore neither
has the line that uses it. Once the profile is approved, the line returns to the status given by points 1-4. In the JSON the `stato_di` of
this line is `profilo`: the status does not come from the line, from the detail or from the header.

**The other lines with a status.** The same rules apply to:
- the details of `DEFINE` and of `SCENARIO` (G12, G19 with `DETAILS`): they are always details, so without their own
  `STATUS` they are pending approval (point 3). A `DEFINE` or a scenario without `DETAILS` has no status of its own and does not
  appear in section 4 of the report;
- a `BINDING`: its header has the status of its `STATUS` (point 4), and every `BIND` line follows points 0, 1, 2
  and 4 (a `BIND` line has no `DETAILS`). A `BINDING` with an invalid header (E09) has all its lines pending
  approval (point 0);
- a `PROFILE`: it has the status of its `STATUS`; its extensions have no status of their own and follow it. The
  extensions of a profile pending approval are listed in section 4 of the report;
- a `VERIFICATION` has no status: it is neither approved nor pending approval, and it does not appear in section 4.

The lines pending approval are in section 4 of the report (`HYPOTHESIS, NOT CONTRACT`). `check` never approves:
it only reads.

**The invalid header (point 0).** A header that does not respect G1 or G31 (error E09, for example `CSC
Rotta VERSIONE 0.1`, `CSC Rotta 0.1` or `ENTITY Rotta VERSIONE 0.1`) does not state which CSC or entity, nor which version:
no line of the block is approved, neither those that follow the header nor those with their own `STATUS RATIFIED BY
D-nnn`. The block is opened all the same (section 5) and the `STATUS` lines remain recognised and written as they are: once
the header is corrected, every line returns to the status given by points 1-4. The rule looks at the block of the line, not at the
file. The edge cases:

| Case | Effective status | Reason |
|---|---|---|
| CSC with E09, then `STATUS RATIFIED BY D-1`: line without `STATUS` and without `DETAILS` | **pending approval**: in section 4 of the report, `stato` `ipotesi` and `decisione` `null` in the JSON | point 0 |
| the same CSC, line with its own `STATUS RATIFIED BY D-2` | **pending approval**, in section 4; `decisione` `null` | point 0 |
| the same CSC, line with `STATUS HYPOTHESIS`, or a detail without `STATUS` | pending approval | point 0 (they would also be so by points 2 and 3) |
| CSC with E09, then `STATUS RATIFIED` without `BY` (E04) | **all pending approval**; E09 and E04 remain | point 0 |
| CSC with E09, without `STATUS` or with `STATUS HYPOTHESIS` | all pending approval | point 0 |
| entity with E09 (`ENTITY Rotta VERSIONE 0.1`), even with `STATUS RATIFIED BY D-1` | **all pending approval**, including the guarantee with its own `STATUS RATIFIED BY` | point 0; the lines without `STATUS` would be so in any case (in an entity point 4 always gives “pending approval”) |
| two blocks: the first with E09 and `STATUS RATIFIED BY D-1`, the second valid with `STATUS RATIFIED BY D-5` | all pending approval in the first; in the second points 1-4 apply | the rule looks at the header of the block of the line |
| valid header with the name already used by another block (E01), then `STATUS RATIFIED BY` | approved | E01 is not an invalid header: G1 is respected. Point 0 applies only to E09 |
| `--strict` | the code remains 1 (E09 is an error) and section 4 is the one without `--strict` | the effective status does not depend on `--strict` (section 9.2, “Rest of the report with `--strict`”; section 10, “What prevails”) |

Point 0 does **not** change: the block line in the report (`line N: CSC (invalid header), STATUS RATIFIED
BY D-1`) and, in the JSON, the `stato` and the `decisione` of the block, which report the `STATUS` written in the header and
not the effective status of the lines; the number of errors, the `outcome` line and the exit code; sections 2, 3,
5, 6, 7 and 8; the levels of `DETAILS` (7.3). In the JSON the field `stato_di` of every line of a block with E09 is
`intestazione_non_valida`, whatever is written in the line. `ratify` and `refine` do not work on a file with
errors, so they never see a line of this kind.

**The remaining case** (declared limitation, like that of 7.2). If the author corrects an invalid header by hand,
the lines that were approved before the header was damaged become approved again without `ratify`, with their
`STATUS RATIFIED BY` and that of the header: “once the header is corrected, the line is approved again”. `check`
reads one file at a time and does not know what was there before; the case is covered by comparing the file with the previous
version.

**The guarantees of an entity.** Points 0, 1, 2 and 3 apply as in the CSC. Point 4 in an entity **always gives “pending
approval”**: the header of an entity is never approved (`STATUS RATIFIED` is unrecognised there, section 5).
Therefore an entity guarantee is approved if and only if it has its own valid `STATUS RATIFIED BY D-nnn`, and it becomes approved with
`bcdd ratify` (section 12), only if the boundaries of the entity have been read. Example: in an entity `Ratificata` with
`STATUS RATIFIED BY D-1` as its first declaration, the status of the block is `without STATUS` and the `STATUS` line is in
section 5; `r1` (without `STATUS`) is pending approval; `r2` (`STATUS RATIFIED BY D-2`) is approved; `r3` (`STATUS RATIFIED`
without a decision) gives E04 and is pending approval.

As in the CSC, `check` does not know who wrote a `STATUS RATIFIED BY`: written by hand, it makes an entity guarantee approved
even if one of its boundaries is not found (the search does not change the outcome). The rule is that `STATUS RATIFIED BY`
is not written by hand (section 7.2); `ratify` enforces it by checking the boundaries (section 12.2, step 7).
Declared limitation.

**A linear example** (the file is valid: `check --strict` gives code 0):

```
CSC LuceScale VERSION 0.1
  STATUS RATIFIED BY D-135
  ...
  GUARANTEE g1: VERBAL "A press switches the light on"
  GUARANTEE g1a DETAILS g1: VERBAL "Within 1 second of a press the light is on"
  GUARANTEE g2 STATUS HYPOTHESIS: VERBAL "The light switches off by itself after DURATA_LUCE"
  GUARANTEE g2a DETAILS g2 STATUS RATIFIED BY D-200: VERBAL "A press while the light is on restarts the time"
```

(the `VERIFY` lines are omitted here for brevity; they are present in the file; `D-135` and `D-200` are example references).

| Line | What it has | Point | Effective status |
|---|---|---|---|
| `g1` | no `STATUS`, no `DETAILS` | 4: inherits from the header, which is `RATIFIED BY D-135` | approved |
| `g1a` | no `STATUS`, but `DETAILS g1` | 3: a detail does not inherit | pending approval |
| `g2` | its own `STATUS HYPOTHESIS` | 2 | pending approval, even though the header is approved |
| `g2a` | its own `STATUS RATIFIED BY D-200` | 1 | approved, even though it details a line pending approval |

With the header `STATUS HYPOTHESIS`, or without `STATUS`, `g1` would also be pending approval (point 4); `g2a`
would remain approved (point 1).

**Who uses the effective status** (the rule is the same for all):

| Command | What it does with it | Where |
|---|---|---|
| `bcdd check` | lists the lines pending approval in section 4 of the report | section 9 |
| `bcdd ratify FILE ID D-nnn` | refuses a line that is already approved, even if it is so because it inherits (point 4); in an entity, a guarantee with its own `STATUS RATIFIED BY`. A file with an invalid header has E09 and `ratify` refuses it before looking at the line (section 12.2): point 0 does not change `ratify` | section 12 |
| `bcdd ratify FILE --all D-nnn` | changes only the header, if it is pending approval, and the lines that remain pending approval **afterwards** (points 2 and 3): the lines of point 4 follow the header and are not touched | section 12 |
| `bcdd refine` | can propose replacing only a line pending approval; an approved line is never replaced | section 7.4 |

### 7.2 A new version of an approved CSC

1. An approved CSC **is not modified**. To change it, the author writes a **new VERSION** in the same
   file, in place of the old one (the same name twice in the same file is E01), with `STATUS HYPOTHESIS`
   in the header and a leading comment stating what changes and on the basis of which decisions.
2. In the new version:
   - a line whose **text does not change** keeps its `STATUS RATIFIED BY D-mmm`, if it had one: it remains approved, with the
     earlier decision;
   - a line whose **text changes** returns to pending approval: if it had its own `STATUS RATIFIED BY D-mmm`, the author
     changes it to `STATUS HYPOTHESIS`. A line without `STATUS` and without `DETAILS` is already pending approval, because it follows the header
     (section 7.1, point 4), and `STATUS` need not be added. It follows the status of the header,
     like the other lines that follow it, including when the header is approved;
   - a new line is pending approval: with `STATUS HYPOTHESIS`, or without `STATUS` (section 7.1, points 3 and 4).

   Until the new version is approved, the contract in force remains the previously approved version; of the
   new version only the lines that have not changed and have their own `STATUS RATIFIED BY` are approved.
3. The new version becomes approved **only** with `bcdd ratify FILE D-nnn` or `bcdd ratify FILE --all D-nnn`, with
   the decision reference of the approval. `STATUS RATIFIED BY` is not written by hand.

Example: the approved staircase light is `VERSION 0.1`. To add flashing, the following is written:

```
-- VERSION 0.2 (D-nnn): flashing before switch-off. Pending approval.
CSC LuceScale VERSION 0.2
  STATUS HYPOTHESIS
  ...
```

What `check` sees: the header `STATUS HYPOTHESIS`, and in section 4 of the report the lines without `STATUS`
(point 4 of 7.1), the details without `STATUS` and the lines with `STATUS HYPOTHESIS`. **A line with its own `STATUS
RATIFIED BY` remains approved** in the new version too (point 1 of 7.1): this is point 2 above. Example: a
staircase light approved with `--all`, with four base lines `g1`, `g2`, `g3`, `a1` without `STATUS` and six details
(`g1a`…`g1c`, `g3a`…`g3c`) with their own `STATUS RATIFIED BY`, brought to `VERSION 0.2, STATUS HYPOTHESIS` without
changing anything else: section 4 of the report contains the four base lines, which follow the header; the six
details remain approved.

**The remaining risk.** If the author changes the text of a line and forgets to set it to `STATUS
HYPOTHESIS`, the line remains approved with a text that the approver has not seen, and `check` does not notice (section
14). This is covered by the comparison with the previous version before approval, not by `bcdd`. `bcdd refine` does not create
this case: it never replaces an approved line (section 7.4).

**A comment is not contract.** The rule “an approved CSC is not modified” applies to what is approved:
header, declarations, contractual lines. A comment (`-- …`) can be corrected without a new VERSION, if
no recognised line changes.

`check` reads one file at a time and does not know the previous version: it cannot tell whether a VERSION is new, nor what
has changed. The comparison between two versions is made with file version-control tools, not with
`bcdd`.

### 7.3 The levels of `DETAILS`

- A **base line** is a `GUARANTEE` or an `ASSUME` without `DETAILS`: its **level** is 0.
- For `X DETAILS Y` the level of `X` is that of `Y` plus 1.

Example, under `g2` of the staircase light (the file is valid):

```
GUARANTEE g2: …                      -- level 0, base line
GUARANTEE g2a DETAILS g2: …          -- level 1
GUARANTEE g2a1 DETAILS g2a: …        -- level 2
GUARANTEE g2a1a DETAILS g2a1: …      -- level 3
```

| Command | What it does with the levels |
|---|---|
| `bcdd check` | **nothing**: it accepts `DETAILS` at any depth, without errors or warnings, and the report does not show the levels. A file with lines at level 3 or 4 passes `check --strict` with code 0 |
| `bcdd refine` | **proposes at most two levels**: a proposal that details a line already at level 2 or deeper is discarded; therefore a line added by `refine` reaches at most level 2. Replacements (section 7.4) apply at every level. Lines already deeper remain: `refine` does not touch them and does not detail them |
| `bcdd ratify` | nothing: it approves a line at any level |

The level is counted only in a file without E02 or E05, where every chain of `DETAILS` ends in a base
line. This is the case of `refine`, which works only on files without errors.

### 7.4 The replaced line

`bcdd refine` can propose to **replace** a line pending approval (section 7.1) written in words; the person sees
the current line and the new one, and accepts or discards.

What remains and what changes when the person accepts:
- **what remains**, byte for byte, is the first line of the declaration **from its first character up to and including the first
  `:`**: the indentation, the type (`GUARANTEE` or `ASSUME`), the short name, the `DETAILS` and the `STATUS`, with the
  spaces that were there. The first `:` is always that of the line header, because a short name, a name and a
  decision contain no `:` (rules L7-L9), and the line header is always on one line (rule U2);
- **what changes** is the text after `VERBAL` and the verification; the `VERIFY` line is aligned under `VERBAL`;
- **what remains** where it is, identical, is every other line of the file, including the details of the replaced
  line.

Example, `g2` of the staircase light, a base line under a `STATUS HYPOTHESIS` header:

```
before:
  GUARANTEE g2: VERBAL "The light switches off by itself after a while"
                VERIFY BY JUDGEMENT "the operator, with a clock"
after:
  GUARANTEE g2: VERBAL "The light switches off by itself between 59 and 61 seconds after the last press"
                VERIFY BY JUDGEMENT "the operator, with a stopwatch"
```

What remains is `  GUARANTEE g2:`. Since the `STATUS` does not change, the line remains pending approval: `g2` continues to inherit
from the header, and if the header is then approved the line follows it like the other lines. A detail `g2a DETAILS
g2` remains valid, because the short name `g2` does not change; `refine` lists it as “to be re-read”. For `check` the replaced
line is a line like any other: it does not know that it has been replaced.

---

## 8. Errors

An error is a construct that `bcdd` recognises in its form but that violates a rule of the language. There are forty
errors (E01-E40).

| Code | When | Line indicated | Exact text of the message |
|---|---|---|---|
| E01 | two elements with the same name or short name in the same block; two parameters or two arguments with the same name in the same line; two blocks with the same name in the same file, whatever their type. In the entity: two parts, a part and a guarantee, or a scenario and a part or a guarantee, with the same name; two `OFFERS` with the same name, unless both write `VERSION` with different versions (section 5); likewise for two `USES`. In a CSC, also a value of a list of values equal to another name of the block | the second | `name already used at line N: X` |
| E02 | `DETAILS X` where X is neither a `GUARANTEE` nor an `ASSUME` of the same block; in a `DEFINE`, X is not a `DEFINE` of the same block; in a scenario, X is not a scenario of the same block | that of the `DETAILS` | `DETAILS names an id that is neither a GUARANTEE nor an ASSUME of this CSC: X`; in an entity `DETAILS names an id that is not a GUARANTEE of this ENTITY: X`; `DETAILS names a name that is not a DEFINE of this CSC: X`; `DETAILS names an id that is not a SCENARIO of this block: X`. Also: in an entity with `VARIANT` segments, the line named stands in a choice that does not hold in all the compositions of the detail (section 4.10): `DETAILS names a GUARANTEE that does not hold in all the compositions of this line: X (it is in VARIANT D = S)` |
| E03 | a step or a `GIVEN` names as an event something that is not an `EVENT`, as a request something that is not a `CAPABILITY`, as a state something that is not a `STATE`, or an argument that the event does not have among its parameters. Also: in an entity scenario, a qualified name `X.y` in which `X` is a connector of the entity (`OFFERS` or `USES`) and its CSC is found, but `y` is missing or of the wrong kind, or an argument that `X.y` does not have; a simple name used as an event, a request or a state, because an entity has no elements of its own (section 4.6); in a CSC block, a name used as a value (G26) that is not a value of a list of values of the block | that of the name (for a qualified name, that of `X`) | `name not declared as EVENT: X` (and likewise `CAPABILITY`, `STATE`), or `name not declared as a parameter of E: X`; with a qualified name `name not declared as EVENT: X.y`, `name not declared as a parameter of X.y: a`; for a value `name not declared as a value of TYPE: X` |
| E04 | `STATUS RATIFIED` not followed exactly by `BY` and a Decision | that of `RATIFIED` | `STATUS RATIFIED without a decision: BY D-number is needed` |
| E05 | the `DETAILS` form a cycle (including a line that details itself), among contractual lines, among `DEFINE`s or among scenarios | that of the member of the cycle that comes first in the file | `circular DETAILS: A -> B -> A`, starting from that member and following the `DETAILS` |
| E06 | an open string is not closed before the end of the file | that where the string opens | `unclosed string: the file ends inside the string opened here` |
| E07 | a block without `END` (the file ends, or another block begins), including a `BINDING`, a `VERIFICATION`, a profile or an extension (section 4.11) | the header of the block | `unclosed block: END of CSC X is missing` or `… of REFINEMENT VIEW X` or `… of ENTITY X`; `… of BINDING X`, `… of VERIFICATION X`, `… of PROFILE X`, `… of EXTENSION X`, with `X` the second word of the header if it is a Nome; `?` if the name cannot be read. An extension without `END` inside a profile without `END` gives a single E07, on the profile |
| E08 | `END` without an open block (an extension is an open block inside its profile, and so is the misplaced one of E32: its `END` does not give E08) | that of `END` | `END without an open block` |
| E09 | a line that begins with `CSC`, `ENTITY`, `BINDING`, `VERIFICATION`, `PROFILE` or `EXTENSION` (inside a profile) and does not respect G1, G31, G40, G48, G49 or G50 | that line | `invalid header: CSC Name VERSION number expected` or `invalid header: ENTITY Name VERSION number expected`, `… BINDING CSCName VERSION number [AS name] expected`, `… VERIFICATION CSCName VERSION number expected`, `… PROFILE Name VERSION number expected`, `… EXTENSION Name expected`. For `EXTENSION` with a keyword or a reserved word as its name, E34 applies instead |
| E10 | a CSC, an entity or a profile without a recognised `PURPOSE`; a second `PURPOSE`; a second recognised `STATUS` in the header zone (sections 4.2, 4.9 and 4.11, including in a `BINDING`) | the header of the block; the second `PURPOSE`; the second `STATUS`, column of `STATUS` | `PURPOSE missing in CSC X` or `PURPOSE missing in ENTITY X`, `PURPOSE missing in PROFILE X`; `PURPOSE repeated: the first is at line N`; `STATUS repeated: the first is at line N` |
| E11 | the file contains no CSC, no entity, no `BINDING`, no `VERIFICATION` and no `PROFILE` (a block with an invalid header counts; a withdrawn block and an extension outside a profile do not) | none | `the file contains no CSC` |
| E12 | in a scenario a step has a time smaller than the largest of the previous steps; or the scenario mixes steps with units and steps without | that of the step | `the time of the step decreases: @T after @M`; `steps with and without a time unit in the same SCENARIO` |
| E13 | a `GUARANTEE` or `ASSUME` with a valid line header whose property is only `VERBAL` and a string, without `VERIFY` (section 4.5) | that of the word `VERBAL` | `VERBAL without VERIFY: VERIFY BY JUDGEMENT or INSPECTION and a string are needed` |
| E15 | a declaration that begins with `REFINEMENT`, in a position where a block begins (section 4.8) | that of `REFINEMENT`; column of `REFINEMENT` | `REFINEMENT VIEW has been withdrawn: a decomposition is written with ENTITY` |
| E14 | inside an entity E with **all** parts found, a part P uses a CSC X that no other part of E provides and that E does not use from outside, with the match rule of section 9.4 | that of part P in the checked file; column of the name P | `the part P uses connector X: no other part of E provides it, nor does E use it from outside`, with `X` written as in the `USES` line of P, followed by ` VERSION w` if present; `E` is the name of the entity, `?` if it cannot be read |
| E16 | in an entity E with at least one part (G34), with or without `COMPOSED OF`, and **all** parts found; with compositions (4.10), in each one that has at least one part present: a public CSC of E (`OFFERS X` or `USES X`) that no part exposes on the same side, with the match rule of section 9.4 | that of the `OFFERS` or `USES` line of E; column of the name | `the public connector X of E (provided) is not assigned to any part` (or `(used)` for `USES`), with `X` written as in the line, followed by ` VERSION w` if present |
| E17 | under the same condition, a part P provides X, no other part of E uses it and E does not provide it, with the match rule of section 9.4 | that of part P; column of the name P | `the part P provides connector X: no other part of E uses it, nor does E provide it from outside`, with `X` followed by ` VERSION w` if the part states it |
| E18 | inside an `ENTITY` block, a declaration that begins with `ASSUME`, `CAPABILITY`, `EVENT`, `STATE`, `DEFINE` or `TYPE` (section 5) | that of the keyword; column of the keyword | `K cannot appear in an entity: write it in the CSC of one of its connectors`, with `K` the keyword |
| E19 | a part with the form G35 but wrong bounds: a bound with a decimal point, or `m` > `n`, or `n` = 0 (section 4.9) | that of the part; column of `[` | `the part P has an invalid number of copies: [m .. n]. Write [minimum .. maximum] with two integers: the minimum 0 or more, the maximum at least 1 and not smaller than the minimum`, with `P` the name of the part and `m` and `n` written as in the file |
| E20 | a qualified name `X.y` in a scenario or in an entity formula with `X` that is not among the `OFFERS` and `USES` of the entity; or a qualified name in a scenario of a CSC or in a phase of a formula of a CSC (sections 4.6, 4.12) | that of `X`; column of `X` | in the entity `X.y: E neither provides nor uses connector X; a scenario can cite only the connectors of E`; in the CSC `X.y: in a CSC, names are not written with the connector in front. The order of two connectors is written in a SCENARIO of the entity`. In an entity with several compositions, `X` is checked per composition and the message has the suffix `(in: …)` (sections 4.10 and 9.5) |
| E21 | a declaration that begins with `VARIANT` in a `CSC` block; in an entity, one that begins with `VARIANT` and does not respect G38; one that begins with `PURPOSE` inside a segment (section 4.10) | that of the keyword; column of the keyword | `VARIANT cannot appear in a CSC: variants are written in an entity`; `VARIANT badly written: VARIANT group = choice is needed`; `PURPOSE cannot appear in a VARIANT segment: write it before the first VARIANT` |
| E22 | a choice group with a single choice; the same choice written twice; a segment without recognised declarations (section 4.10) | that of the `VARIANT` (for the repeated choice, the second); column of `VARIANT` | `choice group D has a single choice (S): at least two are needed; a part that may be missing is written with [0 .. 1]`; `the choice D = S is already written at line N`; `the VARIANT segment D = S is empty: a choice without lines is written with a part [0 .. 1]` |
| E23 | an entity with more than 64 compositions (section 4.10) | that of the header; column 0 | `entity E has more than 64 compositions: bcdd does not check them one by one. Remove a choice, or divide the entity into smaller entities`, with `E` the name of the entity (`?` if it cannot be read) |
| E24 | in a formula, in a `DEFINE`, in a `STATE … FOLLOWS` line or in a use of an extension: a name that is not declared, or that is not of the kind the position requires (section 4.13); a field that does not exist; a call with wrong arguments; in an entity, a simple name where an element of a CSC is required (section 4.9) | that of the name; column of the name (of `X` for `X.y`) | `name not declared: X`; `X is not an event: an EVENT, a DEFINE EVENT or a phase of a CAPABILITY is needed`; `X is not a CAPABILITY`; `X is not a STATE`; `X is a CAPABILITY: it is named with a phase (requested(X), …) or in ACCEPTS, REQUIRES, ENSURES, RESOLVES`; `X is not a value`; `name not declared as a field of T: c`; `X is not a DEFINE with parameters`; `name not declared as a parameter of X: p`; `the argument p is missing in the call to X`; `in an entity the names of the CSCs are written with the connector in front: x`; with a qualified name `name not declared as EVENT: X.y` (and likewise `STATE`, `CAPABILITY`) |
| E25 | an expression of the wrong type for its position; a value written in `INITIAL`, `GIVEN`, in an assignment or in an argument that is not of the declared type (section 4.13) | that of the first token of the expression or of the value | `inconsistent type: A needed, B found`; `value not of type T: V` |
| E26 | `AND` and `OR` at the same level without parentheses; `IMPLIES`, a comparison or `^` chained without parentheses (section 4.12) | that of the second operator; column of the operator | `AND and OR together without parentheses: write (a AND b) OR c, or a AND (b OR c)`; `IMPLIES after IMPLIES without parentheses: write a IMPLIES (b IMPLIES c)`; `chained comparisons: write a <= b AND b <= c`; `^ after ^ without parentheses: write (a ^ b) ^ c` |
| E27 | a nested pattern; two scopes; `WITHIN` and `AT ONCE` together; `REQUIRES` in a `GUARANTEE` (section 4.12) | that of the word; column of the word | `K inside another form: the language does not nest ALWAYS, EVENTUALLY, WHENEVER and their shorthands`; `a property has a single scope: K is the second`; `WITHIN and AT ONCE in the same property: choose one`; `REQUIRES is used only in an ASSUME: in a GUARANTEE write ALWAYS (requested(X) IMPLIES c)` |
| E28 | `DEFINE`s that refer to one another circularly; named types (G41) that refer to one another circularly | that of the member of the cycle that comes first in the file; column of the name | `circular DEFINE: A -> B -> A`; `circular TYPE: A -> B -> A` |
| E29 | the type of the index of a state (G11) or of `FOR ALL` is not finite; an index on a name that has none; an indexed state without an index; an index of the wrong type (sections 4.3, 4.6, 4.12) | that of the name or of the index | `the type of the index of X is not finite: T`; `X has no index`; `X has an index: write X[value of T]`; `index of X not of type T: v` |
| E30 | a repetition written incorrectly (section 4.6) | that of the `REPEAT` line or of the step; column of `REPEAT` or of `@` | `REPEAT repeated in the scenario: the first is at line N`; `invalid repetitions: m..n. Write REPEAT minimum..maximum, with the maximum at least 1 and not smaller than the minimum`; `the step @t is not shorter than the period of REPEAT: every repeated step has a time smaller than EVERY d`; `REPEAT without steps: the repeated steps are written after the REPEAT line`; `REPEAT … EVERY requires a scenario with time units` |
| E31 | in a `BINDING` or in a `VERIFICATION` whose bound CSC is found with the written version: a `BIND` or `MEANS` line names an element that the CSC does not have; a translated scenario names a scenario that the CSC does not have (section 4.11) | that of the element or of the short name; column of the element | `X is not an element of CSC N VERSION v`; `TRANSLATES names a scenario that CSC N VERSION v does not have: id` |
| E32 | an `EXTENSION` outside a `PROFILE` (section 4.11) | that of `EXTENSION`; column of the word | `EXTENSION outside a PROFILE: an extension is declared in a profile` |
| E33 | a missing or repeated field of an extension, or one with a value that is not admitted; a `FORM` that does not begin with the name; a parameter that does not appear exactly once in `FORM`; `KIND FUNCTION` without a result type; `VERIFY V1` with a check that does not exist (section 4.11) | for a missing field that of `EXTENSION`, column 0; otherwise that of the field, column of the field | the messages of the table in section 4.11 |
| E34 | two extensions with the same name in the same profile; an extension whose name is a keyword or a reserved word | that of the second `EXTENSION`, or of the one with the reserved name; column of the name | `extension name already used at line N: X`; `the name of the extension is a word of the language: X` |
| E35 | `REDUCES TO` names something that is not part of the language, nor a parameter, nor an extension of the same profile; extensions that refer to one another circularly through `REDUCES TO` | that of the name; for the cycle, that of the member that comes first | `REDUCES TO names X: it is not a word of the language, a parameter or an extension of PROFILE P`; `circular REDUCES TO: A -> B -> A` |
| E36 | an extension whose `REDUCES TO` repeats a form of the language or another extension (section 4.11) | that of `REDUCES`; column of `REDUCES` | `EXTENSION X repeats a form that the language already has: F`; `EXTENSION X repeats EXTENSION Y` |
| E37 | a use of an extension that does not respect its `FORM`, its `KIND` or its `LEVEL` (section 4.14) | that of the name of the extension; column of the name | `use of X that does not respect FORM "F"`; `X has KIND K: it is not used in this position`; `X has LEVEL L: it is not used in a B block` |
| E38 | a `BINDING` or a `VERIFICATION` imports a profile with a version different from the one with which the bound CSC, found, imports it | that of the `IMPORT PROFILE` line of the bound block; column of `IMPORT` | `PROFILE P imported with VERSION v, but CSC N imports it with VERSION w` |
| E39 | a `STATUS` in a `VERIFICATION` | that of `STATUS`; column of `STATUS` | `STATUS cannot appear in a VERIFICATION: a verification plan is not approved` |
| E40 | two `BINDING`s for the same CSC and the same version without a name, or with the same name, in the checked file (section 4.11) | that of the second; column 0 | `second BINDING without a name for CSC N VERSION v: the first is at line M. With two or more BINDINGs, each has a name: AS name`; `BINDING name already used at line M: x` |

In the messages, `id` is the short name, “connector” a CSC cited by an entity, “choice group” a group and
`SCENARIO` a scenario.

Clarifications:
- **What is not an error**: an unrecognised line; an undeclared type; a CSC without guarantees; an empty
  `PURPOSE`. Nor, because they are not wrong elements written in the checked file: a citation not
  found, a cited file that cannot be read or has errors, a version different from the one expected; and a part that is not
  found **suspends** E14 for its entity.
- **E16 and E17** complete the closure of an entity: E14 looks at the `USES` lines of the parts, E17 at their `OFFERS`,
  E16 at the public boundaries. Like E14 they are errors (code 1), they prevent `ratify`, and a part not found suspends them
  for its entity.
- **E14** is an error like the others (code 1) and prevents `ratify`. A part uses a CSC when **its own**
  block, found elsewhere, says so: the error is in the checked file because that is where the parts are put together.
- **E03** concerns only steps, `GIVEN`s and recognised values. Arguments are checked only if the event is
  declared as an `EVENT`. In an entity scenario, if the CSC `X` is not found, `X.y` and its arguments are not
  checked (section 4.6).
- **E18, E19, E20** are errors like the others (code 1) and prevent `ratify`. A declaration with E18 is also
  unrecognised and appears in section 5; a part with E19 remains a part; a declaration with E20 remains
  recognised.
- **E21, E22, E23** are errors like the others (code 1) and prevent `ratify`. A declaration with E21 is also
  unrecognised; a segment with E22 remains a segment; with E23 the closure of the entity is not checked.
- **E14, E16, E17 with compositions**: in a composition with an optional part absent, those that
  disappear when the part is put back are not errors but declared absences (sections 4.10 and 9.5): they do not count in the
  `outcome` line and do not change the code. With several compositions they carry the suffix `(in: …)`.
- **E06, E08, E09, E15, E18, E21, E32**: the line is also unrecognised, so it also appears in section 5 of the
  report. A declaration with an unclosed string declares nothing. With E32 the
  lines of the misplaced extension, up to its `END`, are also unrecognised.
- **E24-E31 and E33-E40** are errors like the others (code 1) and prevent `ratify`. The declaration that carries them
  remains recognised: `bcdd` has read its form in full, and the error states what is wrong. The exception is a
  field of an extension whose line is not recognised: E33 `field … is missing` is on the `EXTENSION` line.
- **An error is reported only when it is certain.** When a check depends on a cited file that is not found (a bound CSC, the block of
  `X` in a qualified name, a profile), the check is suspended and gives no errors; the citation is in section 7.
- **E12**: a step without a unit counts as a pure number; `s` is worth 1000 `ms`. The first step of the scenario decides whether
  the scenario uses units. In the message, times are written `@` + number + (space + unit, if present): `@3 s after @5
  s`, `@4000 ms after @5 s`. Two steps with the same time are admitted.
- **E12 with mixed units**: “with units” means with `s` or with `ms`; `s` and `ms` in the same scenario are not
  a mixture. Every step that does not follow the choice of the first step gives **its own** E12, on its own line: whoever
  corrects sees all the steps to be fixed, not only the first. That step **is excluded from the comparison of times**: it cannot
  also give “the time decreases” and does not change the largest time against which the following steps are compared. A
  pure number and a time with a unit cannot be compared without inventing a unit. Example: after `@0 s`, the
  step `@5` gives E12 for the units, and the `@3 s` that follows does **not** give an error, because the largest remains `@0 s`.
- **E13**: in an assumption written over several lines the line indicated is the one where `VERBAL` is, which may be
  different from that of `ASSUME`. The line goes in section 2 as `verbal` and, if it is pending approval, in section 4; it does not go
  in section 5.
- **A forgotten quotation mark** shifts the pairing of the quotation marks that follow: the lines in between become
  string text or unrecognised lines. As a rule the last string of the file remains open, and `bcdd` signals E06
  on the line where that string opens, which can be far from the missing quotation mark. A stretch of lines becomes a
  string without errors only with two wrong quotation marks (section 5, “The parts of an entity”).

---

## 9. The report of `bcdd check`

The report is the exact content of standard output, defined in this section down to the character.

### 9.1 Structure

```
bcdd check FILENAME      (with the options: bcdd check --strict --dir ARG FILENAME, see 9.2)
lines: T (recognised R, comments C, blank V, unrecognised U)
blocks: B
  line N: CSC Nome VERSION v, BLOCKSTATUS
    line N: IMPORT PROFILE P in PATH at line M: VERSION v, BLOCKSTATUS, OUTCOME   (profiles found, 9.6)
  line N: REFINEMENT VIEW Nome
  line N: ENTITY Nome VERSION v, BLOCKSTATUS
    line N: OFFERS X in PATH at line M: VERSION v, BLOCKSTATUS, OUTCOME      (citations found, 9.4)
  line N: BINDING Nome VERSION v AS nome, BLOCKSTATUS
    line N: CSC Nome in PATH at line M: VERSION v, BLOCKSTATUS, OUTCOME      (bound CSC, 9.6)
  line N: VERIFICATION Nome VERSION v
  line N: PROFILE Nome VERSION v, BLOCKSTATUS

1. ERRORS: E
  line N: [Exx] message

2. DEGREE OF THE CONTRACTUAL LINES
  verbal: a
  formal: f
  declared extension: x
  unrecognised: b
  line N: GUARANTEE id degree

3. UNDECIDED: c
  line N: NAME

4. PENDING APPROVAL, NOT CONTRACT: d
  line N: GUARANTEE id
  line N: BIND element
  line N: EXTENSION Nome

5. UNRECOGNISED LINES: e
  line N: text of the line
  line N: text of the line (profile P VERSION v not found)

6. UNDECLARED TYPES: f
  Nome: line N            (or: lines N, M, …)

7. CSCs NAMED BUT NOT CHECKED: g
  line N: Nome
  line N: Nome (REASON)
  line N: PROFILE Nome (REASON)

8. USES WITHIN ENTITIES: n          (only if the file has at least one ENTITY block, 9.4)
  line N: P uses X: it is provided by Q (line M)

9. COMPOSITIONS: c                  (only if an entity has more than one composition or E23, 9.5)
  line N: ENTITY Nome: k
    name of a composition

10. DECLARED ABSENCES: a           (together with section 9, 9.5)
  line N: without P: message

12. MISSING CONCRETE FORMS: k     (only if the file has at least one BINDING, 9.6)
  line N: BINDING Luce VERSION 0.1: STATE modo, EVENT IN pressione

13. VERIFICATION PLAN COVERAGE: k (only if the file has at least one VERIFICATION, 9.6)
  line N: VERIFICATION Luce VERSION 0.1
    telecamera (line M): g1, g3
    not executed: g2

14. TO BE JUDGED: k                 (only if there is at least one entry, 9.7)
  line N: GUARANTEE g1a DETAILS g1: consistency between the line and the line that details it, one of the two in words

15. CHECKS NOT EXECUTED: k       (only if there is at least one entry, 9.7)
  scenarios: lines N, M

outcome: no errors      (or: 1 error, or: E errors; with unrecognised lines and with --strict see 9.2)
```

The parenthesised notes in the block are annotations of this document, not output. Placeholders: `FILENAME` the name
of the checked file; `Nome`, `NAME` a name; `BLOCKSTATUS` the status of the block (9.2); `OUTCOME` the outcome of the cited file
(9.4); `PATH` the path of the file found; `REASON` the reason.

Sections 1 to 5 are, in order: errors, degree, undecided numbers (`UNDECIDED`), lines pending approval
(`HYPOTHESIS, NOT CONTRACT`), unrecognised lines. Sections 6, 7, 8, 9, 10, 12, 13, 14 and 15 come after. The
number 11 is not used: it was the section of unread blocks, which no longer exist. A file without entities has no lines
of entity citations and no section 8.

### 9.2 Format rules

| What | Rule |
|---|---|
| First line | `bcdd check`, then ` --strict` if present, then ` --dir ARG` for each folder in the order in which it is written (`ARG` as written), then ` FILENAME`; always in this order, wherever the options were written. Example: `bcdd check --strict --dir comuni Uso.csc` |
| File name | the name only, without folders, as it is written on disk |
| Indentation | two spaces for each entry under a title; four for a citation under its block (9.4, 9.6) and for the entries of a block in section 13 |
| Blank lines | one blank line after the `blocks` section and after each section from 1 to 7, and after sections 8, 9, 10, 12, 13, 14 and 15 when they are present |
| Trailing spaces | no line of the report ends with a space |
| End | the report ends with an LF after the `outcome` line |
| Empty sections | the title is always present, with the count 0 and no entries |
| Order of entries | by line number; errors on the same line by column of the token that causes them, then by code; error E11 (without a line) comes before all others and is written `file: [E11] …`. The column is counted from the beginning of the line, from 0. Some errors do not have a single token and have **column 0**: E06 (unclosed string), E07 (unclosed block), E10 for missing `PURPOSE`, E23, E33 for a missing field and E40; they therefore come before the other errors on the same line, and among themselves by code. E10 for repeated `PURPOSE` has the column of that `PURPOSE`. Example: an indented, wrongly written header, without `PURPOSE` and without `END`, gives E07, E10, E09 in that order |
| Status of the block | `STATUS HYPOTHESIS`, `STATUS RATIFIED BY D-nnn`, `without STATUS`, or `invalid STATUS` (error E04 in the header); for a `CSC`, an `ENTITY`, a `BINDING` and a `PROFILE`. A `VERIFICATION` has no status: its line ends after the version |
| Invalid header | `CSC (invalid header), BLOCKSTATUS`; `REFINEMENT VIEW (invalid header)`; `ENTITY (invalid header), BLOCKSTATUS`; `BINDING (invalid header), BLOCKSTATUS`; `VERIFICATION (invalid header)`; `PROFILE (invalid header), BLOCKSTATUS`. `BLOCKSTATUS` is the written `STATUS`, including `STATUS RATIFIED BY D-nnn`: no line of the block is approved (section 7.1, point 0), but the block line reports the written `STATUS`. For `ENTITY` the `STATUS RATIFIED` is not recognised and `BLOCKSTATUS` is `without STATUS` (section 5) |
| Section 2 | the four counts (`verbal`, `formal`, `declared extension`, `unrecognised`) are separate and **are not summed**: there is no total line. Then one entry for each `GUARANTEE` and `ASSUME` of a CSC block and for each `GUARANTEE` of an entity, in line order among all the lines of the file, with degree `verbal`, `formal`, `declared extension` or `unrecognised` (section 6). If the line header is not recognised, the short name is `?` and the degree is `unrecognised`, counted in the fourth count: this happens when the line header does not respect G16, in the CSC as in the entity (for example `GUARANTEE r3 STATUS PIPPO: …` gives `GUARANTEE ? unrecognised`). An entity guarantee with `STATUS RATIFIED BY D-nnn` or `STATUS RATIFIED` without a decision (E04) has its short name and degree `verbal`, as in the CSC: for example `line 6: GUARANTEE r2 verbal` (section 7.1). An `ASSUME` in an entity has no entry (section 5) |
| Section 3 | every recognised `DEFINE` with the value `UNDECIDED` |
| Section 4 | every contractual line with a recognised line header and effective status “pending approval” (section 7); **every** contractual line of a block, CSC or entity, with an invalid header (E09), whatever `STATUS` the line and the header have (section 7.1, point 0). In addition, in file order: the details of `DEFINE` (`line N: DEFINE NAME`) and of scenarios (`line N: SCENARIO id`) pending approval; the `BIND` lines pending approval (`line N: BIND element`, with the element as written); the extensions of a profile pending approval (`line N: EXTENSION Nome`) |
| Section 5 | every line classified as unrecognised, with its text without leading and trailing spaces. A blank line inside a string is written `line N:`. If the declaration is unrecognised because of a profile not found or of an extension with errors (section 4.14), its first line ends with ` (profile P VERSION v not found)` or ` (EXTENSION X of PROFILE P with errors)` |
| Section 6 | the undeclared types of the recognised declarations, in order of first appearance; for each, the lines, without repetitions. A type described in words (G30) or a list of values (G37) in the same block is not an undeclared type |
| Section 7 | in line order, the citations **not found**, with the reason if there is one (9.4): the citations of the entities, the bound CSC of a `BINDING` or of a `VERIFICATION` (`line N: Nome`), the `BINDING`s named with `USING` (`line N: BINDING Nome AS b`), the imported profiles (`line N: PROFILE Nome`, with the reason `only VERSION w found in PATH` if there is only another version). A withdrawn block has no citations (4.8). The title says “CSC” also for the cited entities, blocks and profiles |
| Section 8 | only if the file has at least one `ENTITY` block (9.4); a file with entities and no entries has `8. USES WITHIN ENTITIES: 0`. For an entity with several compositions, entries per composition with the suffix `(in: …)` (9.5) |
| Sections 9 and 10 | only if at least one entity of the file has more than one composition or E23; section 10 also with 0 entries (9.5) |
| Counts of the second line | R + C + V + U = T: every line is in exactly one place |
| Sections 12, 13, 14 and 15 | section 12 only if the file has at least one `BINDING`, section 13 only if it has at least one `VERIFICATION`, also with 0 entries; sections 14 and 15 only if they have at least one entry. The number is the name of the section: it remains the same even when earlier sections are missing. The rules are in 9.6 and 9.7. The `outcome` line does not change: the entries of these sections are not errors |
| `outcome` line | counts the errors, E14 included. If U is at least 1, even without `--strict`, `; unrecognised lines: U (see section 5)` is added, with U the number of the second line and section 5 the one of unrecognised lines: `outcome: no errors; unrecognised lines: 1 (see section 5)`, `outcome: 2 errors; unrecognised lines: 3 (see section 5)`. The exit code without `--strict` does not change: the line reports the unrecognised lines, it does not count them as errors. If U is 0 the added part is absent. Citations change nothing else: `U` is always that of the checked file, never that of the cited files |
| `outcome` line with `--strict` | if U is 0, it is identical to the one without the option. If U is at least 1, the line with the option carries ` (--strict)` in place of ` (see section 5)`: `outcome: no errors; unrecognised lines: 16 (--strict)`, `outcome: 1 error; unrecognised lines: 1 (--strict)`. The label remains `lines` even for U = 1 |
| Rest of the report with `--strict` | identical, byte for byte, to the report without the option: the option changes only the first line, the `outcome` line (for the ` (--strict)` in place of ` (see section 5)`) and the exit code |

### 9.3 A complete report

For a file `05_ratified_senza_decisione.csc` with a CSC whose header has `STATUS RATIFIED` without a decision:

```
bcdd check 05_ratified_senza_decisione.csc
lines: 13 (recognised 9, comments 2, blank 2, unrecognised 0)
blocks: 1
  line 4: CSC Ratifiche VERSION 0.1, invalid STATUS

1. ERRORS: 3
  line 5: [E04] STATUS RATIFIED without a decision: BY D-number is needed
  line 9: [E04] STATUS RATIFIED without a decision: BY D-number is needed
  line 10: [E04] STATUS RATIFIED without a decision: BY D-number is needed

2. DEGREE OF THE CONTRACTUAL LINES
  verbal: 4
  formal: 0
  declared extension: 0
  unrecognised: 0
  line 8: GUARANTEE g1 verbal
  line 9: GUARANTEE g2 verbal
  line 10: GUARANTEE g3 verbal
  line 12: GUARANTEE g4 verbal

3. UNDECIDED: 0

4. PENDING APPROVAL, NOT CONTRACT: 3
  line 8: GUARANTEE g1
  line 9: GUARANTEE g2
  line 10: GUARANTEE g3

5. UNRECOGNISED LINES: 0

6. UNDECLARED TYPES: 0

7. CSCs NAMED BUT NOT CHECKED: 0

outcome: 3 errors
```

`g1` has no `STATUS`, and the `STATUS` of the header is not valid (E04): `g1` is pending approval (section 7.1, point
4). `g4` has a valid approval (`D-7`) and is approved.

### 9.4 Entities and citations

The **citations** of an entity are its recognised lines G32 (`OFFERS`), G33 (`USES`) and G34 (the parts, including with
E19). `check` always searches for them, for every entity of the file, including one with an invalid header, except
those with E01. A withdrawn block has no citations (section 4.8).

**A single depth.** Of an entity cited as a part only its `OFFERS` and `USES` lines are read (and the
`VARIANT` lines, with the segment of each line: 9.5): not its parts, nor the CSCs it cites. Of a cited CSC only
header, version, status and outcome are used; **only if the entity of the checked file has at least one qualified name**
in a scenario or in a formula (sections 4.6 and 4.9), also the recognised declarations `CAPABILITY`, `EVENT` (with
the parameters) and `STATE` (with the type) of the block found. Of the CSC bound to a `BINDING` or to a `VERIFICATION`
the following are also used: the recognised `STATE`, `EVENT`, `CAPABILITY` and `DEFINE` declarations, the short names of the scenarios, the
degree and the names of its guarantees and assumptions (for coverage, 9.6) and its `IMPORT PROFILE` lines
(for E38). Of a profile found, the extensions and their errors are used (section 4.14). The depth remains one:
the citations of the cited CSC are not searched for. “Checked” means
that `bcdd` has read the cited block and reports its version, status and outcome; not that the guarantees are consistent with
one another, which remains a judgement.

#### The search

For a citation with the name `N` the search looks for the block `CSC N` with a valid G1 header (for `OFFERS` and `USES`, and for
the CSC bound to a `BINDING` or to a `VERIFICATION`, which counts as a `USES N VERSION v`), or `ENTITY N` with a
valid G31 header (for a part), `PROFILE N` with a valid G49 header (for `IMPORT PROFILE`), or the block
`BINDING N VERSION v AS b` (for `USING b`). The rules below apply to all; for a profile the version must
be the written one, and a fallback is not found (section 4.2). In order:

1. **Same file**: the first block of the type searched for with that name. If there is one, the search ends here, except for the
   version case below. This step never gives a reason.
2. **Same folder**: the file `N.csc` in the folder of the path written by the person (the part
   of the argument before the last `/`, or the current folder if there is no `/`), even if the argument is a
   symbolic link. `N` is used byte for byte.
3. **`--dir` folders**: the file `N.csc` in each, in the order in which they are written.

A candidate may be the checked file itself: it is read like the others.

| The candidate `N.csc` | The search |
|---|---|
| does not exist: the name is not there, a part of the path is not a folder, or it is a link to a file that does not exist | moves on to the next |
| exists, can be read, is valid UTF-8, but does not contain the block searched for | moves on to the next |
| exists, can be read, is valid UTF-8 and contains the block searched for | **found** |
| is a folder or is not a regular file | **stops**, reason `not a file: PATH` |
| cannot be read (permissions, read error, any other reason) | **stops**, reason `not readable: PATH` |
| it is not known whether it exists: the query to the system fails for a reason other than “not there” and “a part of the path is not a folder” (for example a folder of the path without traverse permission) | **stops**, reason `not readable: PATH` |
| is not valid UTF-8 | **stops**, reason `not UTF-8: PATH` |

**A different version does not stop the search.** For a citation with `VERSION w`, a candidate (including the same file,
step 1) that contains the block searched for with another version is not found immediately: it is remembered as a **fallback**, only
the first one, and the search moves on to the next. If a later candidate has version `w`, the citation is found there, without
`expected`. If none has it, the citation is found in the first fallback, with `, expected VERSION w`. A candidate that
stops the search (`not a file`, `not readable`, `not UTF-8`) stops it even when there is a fallback: the citation
is found in the fallback. Without `VERSION` in the citation the first candidate with the block is found. The rule exists
because a file `N.csc` contains a single version (two blocks with the same name are E01): two versions can both be found
only in different files, for example in two `--dir` folders.

**If it is not found**, the reason is, in order: that of the candidate that stopped the search; otherwise
`PATH does not contain CSC N` (PATH does not contain CSC N; or `… does not contain ENTITY N`) for the **first** candidate that did not contain the
block; otherwise no reason.

**`PATH`** (PATH). For the same folder only `N.csc`, without folders. For a `--dir`, the argument as
written, followed by `/` if it does not already end with `/`, and by `N.csc`.

**What is used of the file found.** It is read with the rules of `check` (BOM, CR LF, UTF-8) and examined in
full, **without** searching for its citations (so E14 is never counted in it). The following are used: the
header line of the block found, its version and its status (rule “Status of the block” of 9.2);
the number of errors of the whole file and the number `U` of its unrecognised lines; for an entity, its
recognised `OFFERS` and `USES` lines, in order, except those with E01 in that file.

**Versions between a citation and the block found.** They are compared as text (`0.1` and `0.10` are
different). A citation without a version matches any version of the block found, which always has
a version (G1 and G31 require it). A different version is not an error: the report signals it.

**Determinism.** `bcdd` may keep in memory a file already read; the report is the one that would be obtained by reading each
candidate only once, in the order above.

#### The lines of the citations found

The count `blocks: B` also counts the entities. Under the line of an entity, indented by **four**
spaces, there is one line for each citation **found**, in line order:

```
    line N: OFFERS X in this file at line M
    line N: USES X in PATH at line M: VERSION v, BLOCKSTATUS, OUTCOME
    line N: p : X in PATH at line M: VERSION v, BLOCKSTATUS, OUTCOME
```

- `N` is the line of the citation in the checked file; `M` the line of the header found.
- The citation is written without its version and without the multiplicity: `OFFERS X`, `USES X`, `p : X` (name of the
  part, space, colon, space, name of the entity).
- `BLOCKSTATUS`: rule “Status of the block” of 9.2. `OUTCOME`: `no errors`, `1 error` or `E errors`,
  followed by `, unrecognised lines: U` if `U` > 0, with or without `--strict`.
- In the same file only `in this file at line M` is written: version, status and errors of that block
  are already in the report.
- If the citation declares `VERSION w` and the block found has a different `VERSION v`, the line ends with
  `, expected VERSION w`. In the same file: `line N: OFFERS X in this file at line M: VERSION v, expected
  VERSION w`.

Every citation is in exactly one place: under its entity, if found, or in section 7, `line N: X` or
`line N: X (REASON)`, with `X` the cited name without version. A citation with E01 is in neither of the
two: its error is there.

#### Section 8 and error E14

Section 8 is present **only if the file contains at least one `ENTITY` block**, after section 7 and before the
`outcome` line, followed by a blank line.

```
8. USES WITHIN ENTITIES: n
  line N: P uses X: it is provided by Q (line M)
  line N: P uses X: it is provided by Q (line M), R (line K)
  line N: P uses X: E uses it from outside (line M)
  line N: P uses X: nobody provides it
  line N: P uses X: no part found provides it (parts not checked: k)
```

**The entries.** For each entity `E` of the file, in line order; for each of its parts `P` that is **found**, in line order
(`N` is the line of `P` in the checked file); for each `USES` line of the block found for `P`,
in the order in which `P` writes them. `X` is written as in the `USES` line of `P`, with ` VERSION w` if present; the
parts are written with their name in the entity (`lampada`, not `Lampada`). `n` is the number of entries.

**The match (it is not symmetric).** The `USES X [VERSION w]` line of `P` is a **demand**. It matches an
`OFFERS Y [VERSION v]` line of another part found, or a `USES Y [VERSION v]` line of `E` itself, if `X` and `Y`
are equal byte for byte **and**:

| The `USES` line of `P` | The other line | Match |
|---|---|---|
| `USES X` (without version) | `OFFERS X` or `OFFERS X VERSION v`, any `v` | yes |
| `USES X VERSION w` | `OFFERS X VERSION w` (same text) | yes |
| `USES X VERSION w` | `OFFERS X VERSION v` with `v` different from `w` | no |
| `USES X VERSION w` | `OFFERS X` (without version) | **no**: a provider that does not declare a version does not guarantee `w` |

The same applies with `USES X [VERSION v]` of `E` in place of `OFFERS`. Lines with E01 never count.

| Case, in order | Entry | Error |
|---|---|---|
| one or more **other** parts found of `E` have an `OFFERS` line that matches | `it is provided by Q (line M)`, or `it is provided by Q (line M), R (line K)` in line order, separated by `, `; `M`, `K` are the lines of the parts in the checked file | no |
| none, but `E` has a `USES` line that matches | `E uses it from outside (line M)`, with `M` the line of that `USES` | no |
| neither of the two, and **all** parts of `E` are found | `nobody provides it` | **E14** on line `N` |
| neither of the two, and at least one part of `E` is not found | `no part found provides it (parts not checked: k)`, with `k` the number of parts of `E` in section 7 | no: E14 is suspended |

- “Other part” means another part line, even if it names the same entity (two parts `a : Nodo` and
  `b : Nodo` satisfy each other). The `OFFERS X` of `P` does not satisfy its own `USES X`, even if `P`
  has a multiplicity with `m` >= 2 (section 4.9).
- **Several versions** (section 5): every `OFFERS` or `USES` line counts on its own, with the match rule above. If a part
  `Q` has two lines that match the same `USES` line (`USES Pulsanti` without version and the two lines `OFFERS
  Pulsanti VERSION 0.1` and `0.2`), `Q` appears **once** in the entry. E16 and E17 are counted line by line: an
  `OFFERS X VERSION 0.1` of a part that nobody uses any longer gives its own E17.
- A part found with errors or with unrecognised lines gives the entries of its recognised `USES` lines and
  provides through its recognised `OFFERS` lines.
- A part that names the very entity that contains it is treated like the others: the depth is one.
- It is not checked that the CSCs that `E` provides are provided by some part (section 14).

#### The complete report on the staircase light

`bcdd check LuceScale.csc` on the file of section 4.9, with the cited CSCs and entities in the same folder, gives
exactly this, code 0:

```
bcdd check LuceScale.csc
lines: 10 (recognised 10, comments 0, blank 0, unrecognised 0)
blocks: 1
  line 1: ENTITY LuceScale VERSION 0.2, without STATUS
    line 3: OFFERS Pressione in Pressione.csc at line 1: VERSION 0.1, without STATUS, no errors
    line 4: OFFERS Luce in Luce.csc at line 1: VERSION 0.1, without STATUS, no errors
    line 6: pulsante : Pulsante in Pulsante.csc at line 1: VERSION 0.1, without STATUS, no errors
    line 7: lampada : Lampada in Lampada.csc at line 1: VERSION 0.1, without STATUS, no errors

1. ERRORS: 0

2. DEGREE OF THE CONTRACTUAL LINES
  verbal: 1
  formal: 0
  declared extension: 0
  unrecognised: 0
  line 8: GUARANTEE g1 verbal

3. UNDECIDED: 0

4. PENDING APPROVAL, NOT CONTRACT: 1
  line 8: GUARANTEE g1

5. UNRECOGNISED LINES: 0

6. UNDECLARED TYPES: 0

7. CSCs NAMED BUT NOT CHECKED: 0

8. USES WITHIN ENTITIES: 1
  line 7: lampada uses Comando: it is provided by pulsante (line 6)

outcome: no errors
```

`pulsante` has no `USES` lines, so it gives no entries; `Pulsante` provides `Comando` in its file, and the entry cites
the line of the part `pulsante` in the checked file (6). Without the button (an entity `SenzaPulsante` with the single
part `lampada` at line 5) the entry becomes `line 5: lampada uses Comando: nobody provides it`, with `line 5: [E14] the
part lampada uses connector Comando: no other part of SenzaPulsante provides it, nor does SenzaPulsante use it from
outside` and code 1. If instead the lamp writes `USES Comando VERSION 0.2` and the button writes only `OFFERS Comando`,
the entry is `nobody provides it` and E14: the button has not guaranteed 0.2.

### 9.5 Compositions and declared absences

The rules of compositions are in section 4.10; this section describes how they are written in the report.

**The suffix `(in: …)`.** Given a universe of compositions (for an error and for an entry of section 8: all
those of the entity; for an entry of section 10: those without the named part) and the set `S` of the
compositions where the fact occurs:
1. `S` is the whole universe: no suffix;
2. otherwise, the first value `a` of a factor (factors and values in the order of section 4.10) such that `S` is
   exactly the set of the compositions of the universe that have `a`: ` (in: a)`;
3. otherwise ` (in: N1; N2; …)`, with the names of the compositions of `S` in their order, separated by `; `.

The suffix is written after the message of an error (section 1), after an entry of section 8 and after an entry
of section 10. The message remains the one defined in section 8 of this document, with the name of the entity of the file.

**Section 1.** The same error found in several compositions (equal code, line, column and message) is written
once, with the suffix. The order of the entries does not change (9.2).

**Section 8.** For an entity with more than one composition, the entries are computed in each composition; entries with the
same text are written once, with the suffix. Order: line of the part, order of the `USES` lines of the part,
first composition in which the entry appears. `n` counts the entries written. Example, for a measurement kit with a choice group
`sensore` and an optional part `di`:

```
  line 18: cattura uses SegnaleLivello: it is provided by di (line 46) (in: with di)
  line 18: cattura uses SegnaleLivello: nobody provides it (in: without di)
  line 18: cattura uses SegnaleLivello: it is provided by microfono (line 88) (in: sensore = microfono)
```


**Section 9.** `9. COMPOSITIONS: c`. One entry for each entity with more than one composition or with E23, in line
order: `line N: ENTITY Nome: k`, with, below it, indented by four spaces, the names of the `k` compositions in their
order; for an entity with E23 only the line `line N: ENTITY Nome: more than 64, not checked`. `c` is the sum of the
`k` (an entity with E23 counts 0). An entity with E21 on a `VARIANT` line has no entry.

**Section 10.** `10. DECLARED ABSENCES: a`. One entry for each declared absence (section 4.10), grouped like
the errors: `line N: without P: message`, with the suffix on the universe of the compositions without `P`. Order: line,
column, code (as in section 1), then first composition. Absences do not count in the `outcome` line and do not change
the exit code. Example, for the same kit (code 0):

```
9. COMPOSITIONS: 3
  line 5: ENTITY Kit1b: 3
    sensore = di, with di
    sensore = di, without di
    sensore = microfono

10. DECLARED ABSENCES: 2
  line 18: without di: the part cattura uses connector SegnaleLivello: no other part of Kit1b provides it, nor does Kit1b use it from outside
  line 43: without di: the public connector Morsetti of Kit1b (used) is not assigned to any part
```

**The parts with variants** (9.4, “A single depth”). Of an entity cited as a part, its recognised
`VARIANT` lines are also read, and for every `OFFERS` and `USES` line the segment where it is; not its parts.

### 9.6 Concrete forms, verification plan and profiles in the report

**The block lines.** In the `blocks` section a `BINDING` is written `line N: BINDING Nome VERSION v, BLOCKSTATUS`,
with ` AS b` after the version if present; a `VERIFICATION` `line N: VERIFICATION Nome VERSION v`; a profile `line N:
PROFILE Nome VERSION v, BLOCKSTATUS`. Under the line of a block, indented by four spaces and in line order, are its
citations found, in the form of 9.4: the bound CSC (`line N: CSC Nome in PATH at line M: …`, where
`N` is the line of the header of the block), the imported profiles (`line N: IMPORT PROFILE P in PATH at line M:
VERSION v, BLOCKSTATUS, OUTCOME`, also under a CSC or an entity), the `BINDING`s named with `USING` (`line N: USING b in
PATH at line M`). In the same file: `in this file at line M`.

**Section 12, missing concrete forms.** `12. MISSING CONCRETE FORMS: k`. One entry for each `BINDING` of the file whose
bound CSC is found with the written version, in line order: `line N: BINDING Nome VERSION v[ AS b]: ` followed
by the elements of the CSC that no `BIND` line of the block names, in the order of the CSC block, each with its
keyword (`STATE modo`, `EVENT IN pressione`, `EVENT OUT accendi`, `CAPABILITY Pulizie`), separated by `, `;
or `none` if every element has a form. A `BINDING` whose CSC is not found has the entry `line N: BINDING Nome
VERSION v: CSC not found, elements not checked`. `k` is the number of elements listed. No entry is an
error.

**Section 13, verification plan coverage.** `13. VERIFICATION PLAN COVERAGE: k`. For each `VERIFICATION` of the file,
in line order, the line of the block and below it, indented by four spaces:
- one line for each instrument, `NAME (line M): id, id, …`, with the guarantees and assumptions of the bound CSC of degree
  formal or declared extension **observed** by that instrument, in the order of the CSC, or `none`. A contractual
  line is observed by an instrument if every state, event and request it names is among the `OBSERVES` elements
  of the instrument. Coverage considers the elements, not their parameters: an instrument that observes `e.p` counts as
  an instrument that observes the event `e`;
- one line `not executed: id, id, …` with the formal or declared-extension lines that no instrument observes,
  or `not executed: none`.

Verbal lines have no entry: they are verified by judgement or by inspection. If the bound CSC is not found, under the
line of the block there is only `CSC not found: coverage not computed`. `k` is the number of short names listed
in the `not executed` lines of all blocks (`not executed: l2, l3` counts 2; `none` counts 0). Example, for a plan of the staircase light with an instrument that observes only `accesa`:

```
13. VERIFICATION PLAN COVERAGE: 1
  line 20: VERIFICATION Luce VERSION 0.1
    telecamera (line 21): l1
    not executed: l2
```

### 9.7 To be judged and checks not executed

**Section 14, to be judged.** `14. TO BE JUDGED: k`. One entry for each rule of the language that only a person
can apply, in line order and, on the same line, in the order of the table:

| Entry | When | Text |
|---|---|---|
| a detail with a line in words | a line with `DETAILS` (contractual or scenario) of which the line itself or the one it details is in words | `line N: KEYWORD id DETAILS p: consistency between the line and the line that details it, one of the two in words` |
| the meaning of an extension | every extension without E33 errors | `line N: EXTENSION X: the MEANING neither describes the implementation nor gives authority or precedence between parts` |
| an extension without reduction | every extension without a recognised `REDUCES TO` | `line N: EXTENSION X: does not repeat a form that the language already has` |
| meaning and reduction | every extension with a recognised `REDUCES TO` | `line N: EXTENSION X: MEANING and REDUCES TO say the same thing` |

`N` is the line of the declaration with `DETAILS` or of the `EXTENSION` line; `KEYWORD` is `GUARANTEE`, `ASSUME` or
`SCENARIO`.

**When a line is “in words”.** A guarantee or an assumption is in words if its degree is `verbal`. A `DEFINE`
is never in words: its value is an expression or `UNDECIDED`. A scenario is in words if at least one of its steps has a
`VERBAL` element. A detail of a `DEFINE` details another `DEFINE` (E02 otherwise): it therefore always goes in the entry `consistency of the details` of section 15; a
detail of a scenario goes in section 14 if the scenario or the one it details is in words, otherwise in section 15.
An unrecognised line is neither in words nor formal: a detail in which one of the two lines is unrecognised goes
in section 14 only if the other is in words, and never in section 15. The entries of section 14 are not errors, are not outcomes and do not change the exit code: they state what
remains to be judged.

**Section 15, checks not executed.** `15. CHECKS NOT EXECUTED: k`. `check` does not evaluate formulas: it does not check
whether the scenarios have the outcome they declare, whether every trigger occurs in a scenario, whether the guarantees and the assumptions
can hold together, nor whether a formal detail is consistent with the line it details. The section lists, for
each of these checks, the lines to which it would apply, in this order:

| Entry | Lines listed |
|---|---|
| `scenarios` | the scenarios (`SCENARIO`) of CSC and entity blocks that have at least one guarantee or assumption of formal degree, or of declared-extension degree with `C3` in the `VERIFY V1` of the extension |
| `coverage of the triggers` | the guarantees of formal degree that have a trigger (`WHENEVER p THEN q`; `ALWAYS (p IMPLIES q)`; a scope, including a use of an extension of `KIND SCOPE` with `REDUCES TO`; a BASE form with a trigger in its expanded form), and those of declared-extension degree with `C4` |
| `consistency of assumptions and guarantees` | the guarantees and assumptions of formal degree, and those of declared-extension degree with `C2` |
| `consistency of the details` | the lines with `DETAILS` of which neither the line nor the one it details is in words or unrecognised |

A line of declared-extension degree enters an entry when **at least one** of the extensions it uses (including
inside the argument of another use, section 4.14) has the check in its `VERIFY V1`: `C3` for `scenarios`, `C4` for
`coverage of the triggers`, `C2` for `consistency of assumptions and guarantees`. Listing one check too many does not make
any line appear checked; omitting one does.

Each entry is written `NAME: lines N, M, …` (or `NAME: line N` with a single line), with the lines in ascending
order; an entry without lines is not written. `k` is the number of entries written. Example:

```
15. CHECKS NOT EXECUTED: 3
  scenarios: lines 30, 35
  coverage of the triggers: lines 12, 14
  consistency of assumptions and guarantees: lines 12, 14, 20
```

The lines of section 15 are neither satisfied nor violated: a check not executed says nothing about
them.

---

## 10. The `bcdd check` command

Form: `bcdd check [--strict] [--json] [--dir FOLDER]... FILE`.
- The option `--strict` can be written before or after `FILE`, only once.
- The option `--json` can be written before or after `FILE`, in any order with the others, only once. It performs the
  same check, with the same exit codes and the same messages on standard error; on standard
  output, in place of the report, it writes a single JSON object, with `"forma": "bcdd-check"` and `"versione": 5`.
  The object contains, among other things: the field `molteplicita` of the `PART` citations (section 4.9); a `TYPE`
  declaration for a list of values, for a named type and for a `Record`, and `SCENARIO` for an entity scenario;
  `varianti` in `ENTITY` blocks; `variante` (`{"dimensione", "scelta"}` or `null`) in declarations, guarantees and
  citations; `in` (the suffix without parentheses or `in: `, or `null`) in errors and in uses, whose `messaggio` and
  `testo` remain without the suffix; in the `rapporto`, `ha_composizioni`, `composizioni[]` (section 9) and `assenze[]`
  (section 10). From version 5: the values `BINDING`, `VERIFICATION` and `PROFILE` of `blocchi[].tipo`, with `legata`
  (`{"nome", "versione"}` of the bound CSC) and `nome_proprio` (the name after `AS`, or `null`) for a `BINDING`, and
  `estensioni[]` for a `PROFILE` (for each one `nome`, `da`, `a`, `kind`, `level`, `riduzione` true or false);
  `stato` `null` for a `VERIFICATION`; the citations of type `IMPORT`, `LEGATA` and `USING` in the `citazioni[]` of every
  block; the values `formale` and `estensione_dichiarata` of `garanzie[].grado` and of `rapporto.gradi[].grado`, and the
  count `rapporto.conteggi.estensione_dichiarata`, alongside `verbale`, `formale` and `non_riconosciuta`; the
  counts `rapporto.conteggi.forme_mancanti` (the `k` of section 12) and `rapporto.conteggi.non_eseguite_piano`
  (the `k` of section 13); `rapporto.ha_binding` and `rapporto.ha_verification` (true if the file has at least one
  block of that type); in `rapporto.ipotesi[]` the field `tipo` (`GUARANTEE`, `ASSUME`, `DEFINE`,
  `SCENARIO`, `BIND`, `EXTENSION`); the field `motivo` (or `null`) in the entries of `rapporto.non_riconosciute[]`;
  `rapporto.forme_mancanti[]` (section 12), `rapporto.copertura[]` (section 13), `rapporto.da_giudicare[]`
  (section 14) and `rapporto.non_eseguiti[]` (section 15), always present, empty when the section is absent. From
  version 5 there are no longer `rapporto.conteggi.non_lette`, `rapporto.blocchi_non_letti[]` nor the value `non_letta`
  of `righe[].tipo`, because no block remains unread. `esito.riga` is the one of the report. Adding a field
  does not change the version of the form; removing one, or changing its meaning, does. In the rows of the table
  below with “the report”, with `--json` read “the JSON object”; where standard output is “nothing”, it remains nothing.
- Each `--dir FOLDER` is written before or after `FILE`, in any order with respect to the other options. The argument that
  follows `--dir` is always the folder, even if it begins with `-`: `--dir --strict` looks for a folder
  named `--strict`.
- The same string after two `--dir` options is incorrect usage; two different strings for the same folder (`a` and
  `./a`) are admitted and both are searched. A `--dir` equal to the folder of the file is not an error.
- Any other argument that begins with `-`, including `--dir=X`, is incorrect usage; a file whose name
  begins with `-` is indicated with its path, for example `./-x.csc`.
- The folders serve only for the search of citations (section 9.4): in a file without entities they change nothing
  other than the first line of the report.

| Case | Standard output | Standard error | Exit code |
|---|---|---|---|
| file read, no errors; without `--strict`, or with `--strict` and no unrecognised lines | the report | nothing | 0 |
| file read, at least one error (with or without `--strict`) | the report | nothing | 1 |
| file read, no errors, `--strict` and at least one unrecognised line | the report | nothing | 3 |
| file that does not exist: the system answers that the name is not there, or that a part of the path is not a folder; also a symbolic link that points to a file that does not exist | nothing | `bcdd check: file not found: ARG` | 2 |
| is a folder or is not a regular file | nothing | `bcdd check: not a file: ARG` | 2 |
| any other reason why the file cannot be examined or read: file permissions, permissions of a folder of the path, read error | nothing | `bcdd check: not readable: ARG` | 2 |
| non-UTF-8 bytes | nothing | `bcdd check: the file is not valid UTF-8 (line N)`, with N the line of the first wrong byte | 2 |
| `--dir ARG`: the name is not there, or a part of the path is not a folder | nothing | `bcdd check: folder not found: ARG` | 2 |
| `--dir ARG` exists but is not a folder | nothing | `bcdd check: not a folder: ARG` | 2 |
| `--dir ARG` is a folder but cannot be opened to read its contents; or it is not known whether it exists, because the query to the system fails for another reason (for example a folder of the path without traverse permission) | nothing | `bcdd check: folder not readable: ARG` | 2 |
| missing or extra arguments; `--strict` repeated; `--json` repeated; `--dir` without argument; the same `--dir` repeated; another option that begins with `-` | nothing | `usage: bcdd check [--strict] [--json] [--dir FOLDER]... FILE` | 2 |

`ARG` is the argument exactly as it was written. Every error message ends with an LF.
The checks are made in this order: the arguments; then the file (that it exists, that it is a regular file, that it can be
read, that it is UTF-8); then the `--dir` folders, one at a time in the written order. The first that fails decides the
message. A symbolic link is followed: a link to a folder is a folder, a broken one is
“not found”. “Not readable” deliberately does not state the cause: for `check` the person
needs to know only that the file has not been checked, and code 2 says so.

**What prevails.** If a file has errors and also unrecognised lines, with `--strict` the code is 1:
errors prevail, because they are the more serious problem and must be corrected first; the unrecognised
lines remain visible in section 5 and in the `outcome` line. In general, from the strongest: 2 (the
file could not be checked), 1 (errors), 3 (only unrecognised lines, with `--strict`), 0.
Code 3 therefore comes only from a file read in full and without errors. E14 is an error like the others
(code 1). Neither a citation not found nor a citation found in a file with errors or with unrecognised lines changes the exit
code, with or without `--strict`.

Properties that `check` respects:
- the file never changes, nor do the files it reads for the citations, not even the modification date;
- the degree of every contractual line, every `UNDECIDED` and every line pending approval are in the report;
- every rule that remains to be judged (section 14) and every check not executed on the formulas (section 15) are in the
  report: no formula appears more checked than it is;
- every unrecognised line is in section 5, with its number;
- the same file, with the same cited files and the same folders, always gives the same report, byte for byte, from
  whatever folder the command is launched, provided that the `--dir` options name the same folders (a relative `--dir` names
  a different folder from another working folder);
- with `--strict` a file with even a single unrecognised line gives an error outcome (code 3, or 1 if there are
  also errors); without `--strict` an unrecognised line does not change the code;
- every citation of an entity of the file is under the entity, if found, or in section 7, with the reason if there is one; a
  citation with E01 is not searched for and is visible from its error in section 1; a missing citation, or a cited file
  with errors, does not change the outcome;
- a cited version different from the one found is in the report (`, expected VERSION w`);
- inside an entity with all parts found, for a CSC that a part uses, that no other part provides and that
  the entity does not use from outside (with `USES`), `bcdd` signals E14.

For an unknown command and for `bcdd` without arguments: nothing on standard output, and on standard error

```
usage: bcdd [--lang it|en] COMMAND; commands: new NAME | check [--strict] [--json] [--dir FOLDER]... FILE | refine FILE [--csc NAME] | ratify FILE [--csc NAME] [--dir FOLDER]... [ID | --all] D-number
```

on a single line, with a final LF; code 2.

**The language of the texts.** `bcdd` writes its texts in English, or in Italian on request. Form:
`bcdd [--lang it|en] COMMAND …`.
- `--lang` is written only before the command, as the first two arguments; after the command it is an unknown option,
  hence incorrect usage of that command. The values are exactly `it` and `en`.
- Precedence: `--lang`, then the environment variable `BCDD_LANG` (`it` or `en`; empty counts as not set), then
  English. The variables `LANG`, `LC_ALL` and `LANGUAGE` are not read.
- An invalid value is incorrect usage: code 2, nothing on standard output and on standard error
  `bcdd: --lang accepts it or en: ARG`, in the language that would apply without the option; for the variable
  `bcdd: BCDD_LANG must be it or en, not: X`, always in English. `bcdd --lang` without a value and `bcdd --lang it`
  without a command give the general usage line, code 2.
- The language changes only the texts for the person: titles and entries of the report, error messages, outputs and
  refusals of the commands, usage lines (`uso:`/`usage:`, `NOME`/`NAME`, `CARTELLA`/`FOLDER`), comments and `PURPOSE`
  string of the skeleton of `new` (section 11), initial comment of a new dialogue file (section 13), letters of the
  answers of `refine` (`s`, `n`, `f` in Italian; `y`, `n`, `q` in English), names of the compositions (`with P` and
  `without P`, in Italian `con P` and `senza P`, section 4.10). With `refine` the request to the language model is
  also in the chosen language. The following do not change: keywords, error codes, line and column numbers, the first
  line of the report (which does not show `--lang`), the structure of the report, exit codes, literal values of
  options (`--expect nuovo`, `--modello veloce|accurato`), the markers of the dialogue file, the `STATUS RATIFIED BY`
  lines written by `ratify`.
- With `--json` the object has, immediately after `"versione"`, the additional field `"lingua"` (`"it"` or `"en"`);
  keys and enumerated values do not change, only the text fields for the person change (among others `messaggio`,
  `testo`, `motivo`, `esito.riga`). The form remains 5.
- `bcdd save`, used by bcdd-editor and not described in this document, writes its usage line in the chosen language.

---

## 11. The `bcdd new` command

`bcdd new NAME` creates the file `NAME.csc` in the current folder.

| Case | Standard output | Standard error | Code | File |
|---|---|---|---|---|
| created | `created NAME.csc` | nothing | 0 | created, with the text below |
| `NAME.csc` already exists (file, folder or link) | nothing | `bcdd new: NAME.csc already exists: I am not overwriting it` | 1 | **not touched** |
| NAME is not a Name (rule L7) | nothing | `bcdd new: invalid name: NAME` | 2 | none |
| missing or extra arguments | nothing | `usage: bcdd new NAME` | 2 | none |
| NAME is, in any combination of upper and lower case, a name that Windows reserves for a device (`CON`, `PRN`, `AUX`, `NUL`, `COM1`…`COM9`, `LPT1`…`LPT9`); on every system, because a folder of CSCs must be able to move from Linux to Windows | nothing | `bcdd new: the name “NAME” cannot be used: Windows reserves it (reserved names: CON, PRN, AUX, NUL, COM1-9, LPT1-9). Choose another name` | 2 | none |
| the file cannot be created or written: folder without write permission, disk full, any other system error | nothing | `bcdd new: I cannot create NAME.csc: CAUSE` | 1 | none, not even a temporary file |

The file is created in full or not at all: it must never remain half-written.

**Which names.** “Not reserved” in rule L7 means: it is not one of the words of section 2.3, the same
list as `check`. In this way `bcdd new` never creates a file whose header `check` rejects.

`CAUSE` is the description of the error given by the system (for example `Permission denied`), on one line.
It is the only text of `bcdd` that this document does **not** fix character by character: it depends on the system. The text
is fixed up to and including `NAME.csc: `; after it there is at least one character and a single final LF. The code is 1, as for the
file that already exists: in both cases the command was written correctly, but the file was not created; code 2
remains for incorrect usage.

**Text of the skeleton.** `NAME` is replaced by the given name; every line ends with LF, including the last; encoding
UTF-8 without BOM:

```
-- CSC created by bcdd new. It is filled in by hand; bcdd check checks the form.
-- Without STATUS RATIFIED no line is part of the contract: it is pending approval until the operator approves it.

CSC NAME VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "to be filled in: in one sentence, what NAME is responsible for"

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

The skeleton has only the mandatory lines (`CSC`, `VERSION`, `PURPOSE`, `END`) plus `STATUS HYPOTHESIS`, which makes
explicit what would apply in any case. The rest is comment: it suggests the forms without creating lines to be checked.

---

## 12. The `bcdd ratify` command

`bcdd ratify` records the approval of one line, or of all, by modifying or adding only `STATUS` indications. It works on
CSCs, on the guarantees of an entity, on `BINDING`s and on profiles; a `VERIFICATION` is not approved. The examples are
on the staircase light.

### 12.1 Form

```
bcdd ratify FILE [--csc NAME] [--dir FOLDER]... [ID | --all] D-nnn
```

`ratify` works on CSCs and on the **guarantees of an entity**: in an entity it approves, with `ID`, one guarantee, with
`--all` all those still pending approval; never the header, the `OFFERS` and `USES` lines or the parts of the entity. An
entity guarantee is approved only if every CSC that the entity provides or uses has been found, in the requested version, in
a file without errors (section 12.2, step 7).

In a CSC `ID` can also be the name of a detail of a `DEFINE` or the short name of a detail of a scenario (G12,
G19 with `DETAILS`), which are approved like contractual lines. A `BINDING` is approved like a CSC, with
the header or with `--all`; `BIND` lines have no short name and are not approved one by one. A profile is
approved only as a whole, with the header or with `--all` (which for a profile does the same): extensions have
no status of their own.

| Command | What it approves | Example |
|---|---|---|
| `bcdd ratify FILE D-nnn` | the **header** of the CSC; the lines that inherit (section 7.1, point 4) become approved with it | `bcdd ratify LuceScale.csc D-135` |
| `bcdd ratify FILE ID D-nnn` | the **line** `ID`, which must be pending approval | `bcdd ratify LuceScale.csc g2 D-135` |
| `bcdd ratify FILE --all D-nnn` | the header and **every** line that would remain pending approval, in a single write | `bcdd ratify LuceScale.csc --all D-135` |

- The arguments that do not begin with `-` are **positional**: 2 (`FILE D-nnn`) or 3 (`FILE ID D-nnn`);
  with `--all` there must be 2.
- The last positional argument is the **decision reference**: rule L9 (`D-` followed by digits only).
- With 3 positional arguments, the middle one is the **ID**, the short name of the line: rule L8.
- `--csc NAME` chooses the block (CSC, entity, `BINDING` or profile) when the file contains more than one; `NAME`
  must respect rule L7. The option is written in any position, only once, and `NAME` is the argument that follows it.
- `--all` is written in any position, only once, and has no argument.
- `--dir FOLDER` as in `check` (section 10): in any position, also several times; the argument that follows
  `--dir` is always the folder, even if it begins with `-`, and does not count among the positional arguments; the same string after two
  `--dir` options, `--dir` as the last argument and `--dir=X` are incorrect usage. The folders serve for the search of the
  citations, in step 4 and in step 7 of 12.2.
- A file whose name begins with `-` is indicated with its path, for example `./-x.csc`, as in `check`.

### 12.2 Order of the checks

The first check that fails decides the message and the code; the file is not touched.

1. Arguments, in this order: number of positional arguments and options (`usage: …`), decision, ID, name after `--csc` (the
   rows with code 2 of section 12.5).
2. Reading of the file: the same cases as `bcdd check` (section 10), with the prefix `bcdd ratify:` in place
   of `bcdd check:`.
3. The `--dir` folders, one at a time in the written order, with the cases and messages of section 10 and the prefix
   `bcdd ratify:` (for example `bcdd ratify: folder not found: ARG`), code 2.
4. **The file passes `bcdd check --strict`**: no errors and no unrecognised lines, in the whole file. Only
   what `bcdd` has read in full is approved. The check searches for the citations of the entities as `check` does: in the
   same file, in its folder and in the `--dir` folders. An E14, an E04 or an unrecognised line in
   an entity prevents the approval of every block of the file. The entries of sections 12-15 of the report are not
   errors and do not stop step 4.
5. **Choice of the block** (also applies to `refine`):

   | The file | Without `--csc` | With `--csc NAME` |
   |---|---|---|
   | at least one CSC | among the CSCs, wherever the other blocks are: a single one is the one; more than one, `the file contains N CSCs: …` | the block `NAME` (see below) |
   | no CSC, a single entity | the entity | the block `NAME` |
   | no CSC, several entities | `the file contains N ENTITYs: say which with --csc NAME`, code 2 | the block `NAME` |
   | no CSC or entity, a single block among `BINDING` and `PROFILE` | that block | the block `NAME` |
   | no CSC or entity, several blocks among `BINDING` and `PROFILE` | `the file contains N blocks to approve: say which with --csc NAME`, code 2 | the block `NAME` |
   | no block `NAME` | — | `no block to approve with the name NAME in the file`, code 1 |
   | no CSC, entity, `BINDING` or `PROFILE` (only `VERIFICATION`) | `the file contains no block to approve: a VERIFICATION is not approved`, code 1 | as without `--csc` |

   With `--csc NAME` the block is, in order: the CSC, the entity or the profile `NAME`; otherwise the `BINDING` with the
   distinguishing name `NAME` (`AS NAME`); otherwise the only `BINDING` without a distinguishing name bound to the CSC
   `NAME`. A `BINDING` without a distinguishing name in the same file as its CSC is not chosen by name, because the name is that
   of the CSC: it is chosen on its own when the file has no CSC or entity, or it is given a name with `AS`. The name of
   a `VERIFICATION` never chooses a block.

   A file with a `REFINEMENT VIEW` has E15 and stops at step 4.

6. The target. In a CSC: the header, the line `ID` (which must be pending approval: a contractual line or a
   detail of a `DEFINE` or of a scenario), or with `--all` the set of lines to be changed, which must not be
   empty. In a `BINDING`: the header, or with `--all` the header and the `BIND` lines with their own `STATUS`
   pending approval; with `ID` it is a refusal. In a profile: the header, with or without `--all`; with `ID` it is a refusal. **In an entity**: without `ID` or `--all` it is a
   refusal; with `ID`, a guarantee of the entity pending approval; with `--all`, all the guarantees of the entity pending approval,
   which must be at least one (the messages are in section 12.5).
7. **The boundaries read**, only if the chosen block is an entity. For every `OFFERS` and `USES` line of the entity,
   in line order, the search of step 4 must have **found** it; if the line declares `VERSION w`, the block
   found has `VERSION w` (same text); the file of the block found has **0 errors** (its unrecognised lines do
   not count). The first line that does not satisfy this decides the message (section 12.5), code 1. The parts do not
   count; an entity without `OFFERS` or `USES` passes. For a CSC the step does not exist: a CSC is approved even if
   an entity of the same file has a missing boundary.
8. Composition of the new text (section 12.3) and its check, with the same folders: no errors, no unrecognised
   lines, the target approved; with `--all`, the header and **all** the contractual lines of the
   CSC approved, or in an entity all its guarantees. If not, it is an internal error and the file is not touched. It is a
   safeguard: it should never happen.
9. Safe write: all or nothing (section 12.6).

A part not found suspends E14 and does not count for step 7. Therefore without `--dir` an entity guarantee is
approved even if, with `--dir` indicating the folder where the part is located, the file would have an E14. For this
reason the approver must indicate the folders in which the parts are located.

### 12.3 Changes to the file

**The minimum** changes: without `--all` **a single line** changes, or **a single line** is added; every other byte
remains identical, including the BOM and the line endings. “D-nnn” is the decision as it was written in the command.

For the header, the recognised `STATUS` of the header zone is considered (section 4.2: the first, wherever it
is among the header lines). In case c2 the line is added immediately after `CSC …`, even if the zone has
`IMPORT PROFILE` lines. For a line, the first line of the `GUARANTEE` or `ASSUME` declaration, or of the detail
of a `DEFINE` or of a scenario, is considered. In a detail of a `DEFINE` case r2 inserts ` STATUS RATIFIED BY D-nnn` immediately after the
short name that follows `DETAILS`, before `:=`; in a detail of a scenario, immediately after the short name that follows `DETAILS`,
before `GIVEN` or `EXPECT`. The header of a `BINDING` and of a profile changes with cases c1 and c2; in case c2
the indentation is that of the first declaration after the header, and if that is the `END` of the block, the indentation
of the `END` followed by two spaces. A `BIND` line with its own `STATUS HYPOTHESIS` changes with case r1; a `BIND`
line without `STATUS` follows the header and is not touched.

| Case | Target | What it does | Before | After |
|---|---|---|---|---|
| c1 | header with `STATUS HYPOTHESIS` | only the word `HYPOTHESIS` becomes `RATIFIED BY D-nnn`; indentation, spaces, comment and line ending remain | `  STATUS HYPOTHESIS` | `  STATUS RATIFIED BY D-135` |
| c2 | header without `STATUS` | a line is **added** immediately after `CSC …`: the indentation of the first declaration line after the header (the first that is neither blank nor a comment; there always is one, because the file has a `PURPOSE`), copied byte for byte, then `STATUS RATIFIED BY D-nnn`, then the line ending of the `CSC …` line (CR LF if that ends with CR LF, otherwise LF) | `CSC LuceScale VERSION 0.1` / `  PURPOSE "…"` | `CSC LuceScale VERSION 0.1` / `  STATUS RATIFIED BY D-135` / `  PURPOSE "…"` |
| c3 | header already `RATIFIED BY D-mmm` | **refusal**, code 1 | | |
| r1 | line with its own `STATUS HYPOTHESIS` | only the word `HYPOTHESIS` becomes `RATIFIED BY D-nnn` | `  GUARANTEE g2a DETAILS g2 STATUS HYPOTHESIS: VERBAL …` | `  GUARANTEE g2a DETAILS g2 STATUS RATIFIED BY D-135: VERBAL …` |
| r2 | line without `STATUS` | ` STATUS RATIFIED BY D-nnn` (with a space in front) is inserted immediately after the last character of the last token before the colon (the short name, or the short name after `DETAILS`); the spaces before the colon remain after the inserted text | `  GUARANTEE g2: VERBAL …`; `  GUARANTEE g3 : VERBAL …` | `  GUARANTEE g2 STATUS RATIFIED BY D-135: VERBAL …`; `  GUARANTEE g3 STATUS RATIFIED BY D-135 : VERBAL …` |
| r3 | line already approved, through its own `STATUS RATIFIED BY` or because it inherits (section 7.1, point 4) | **refusal**, code 1 | | |

The header of a contractual line is always on a single line (rule U2), so `ratify` always changes a single
line for each target. A line that details a line pending approval can be approved. Approving
the header does not change the lines that have their own `STATUS HYPOTHESIS` nor the details without `STATUS`: they remain pending
approval, and the command says so.

An interruption with Ctrl-C before the safe write ends the command without touching the file; during the
write it is deferred until the write ends (section 12.6).

**With `--all`**: after the command the header and every `GUARANTEE` and `ASSUME` of the CSC are approved, with the
minimum change:

| What | If it is pending approval | If it is already approved |
|---|---|---|
| the header | case c1 or c2 | does not change, and keeps its decision |
| a line with its own `STATUS HYPOTHESIS` | case r1 | — |
| a detail without `STATUS` | case r2 | — |
| a line without `STATUS` and without `DETAILS` | — | inherits the approval of the header: does not change |
| a line with its own `STATUS RATIFIED BY D-mmm` | — | does not change, and keeps its decision |

The other CSCs of the file do not change, and the lines of the entities remain identical byte for byte.

**The guarantees of an entity** change with cases **r1** (with their own `STATUS HYPOTHESIS`) and **r2** (without `STATUS`,
base or detail), one line per guarantee; with `--all` all the guarantees of the entity pending approval, and never
the header. The `VERIFY` lines are not realigned, even when case r2 shifts `VERBAL` to the right. Example: in an entity `Scale` with a base guarantee without
`STATUS` at line 5, a detail with `STATUS HYPOTHESIS` at line 7 and a detail already approved at line 9,
`--all D-200` changes line 5 (r2) and line 7 (r1); line 9 does not change. **A single write, all or nothing**: `bcdd`
composes the whole new text in memory, checks it once (step 8 of section 12.2) and writes it with a
single safe write (section 12.6); if the write fails, or the command is interrupted before, the file is
as it was: a file with only some of the lines approved never exists.

Example: on a staircase light with a `HYPOTHESIS` header and four base lines without `STATUS`, `--all D-201`
changes only line 4; the four lines inherit. If the same CSC also has six details with `STATUS HYPOTHESIS`
(for example added by `refine`, which always writes `STATUS HYPOTHESIS`), `--all` also changes those (case r1):
after the command the header and the six details have `STATUS RATIFIED BY`, the four base lines have no
`STATUS` and inherit. For `check` all ten are approved.

### 12.4 Output on success

Code 0, nothing on standard error. On standard output, with the line numbers of the file **after** the modification.
Examples on a staircase light (`D-200`, `D-201` and `D-202` are example references):

```
$ bcdd ratify LuceScale.csc D-200
approved CSC LuceScale (line 3) with D-200
contract: 4
lines still pending approval: 0
```

`contract` counts the `GUARANTEE`s and `ASSUME`s of the CSC that are approved after the modification. Then `lines still
pending approval: K` follows, with `K` the number of lines still pending approval, and if K is not 0 those lines, one per line (`  line N:
GUARANTEE id`), in file order. With lines that remain pending approval:

```
$ bcdd ratify R03_righe.csc D-130
approved CSC Righe (line 3) with D-130
contract: 2
lines still pending approval: 2
  line 8: GUARANTEE g1a
  line 11: ASSUME a1
```

```
$ bcdd ratify LuceScale.csc g2 D-200
approved line 12: GUARANTEE g2 with D-200
```

```
$ bcdd ratify LuceScale.csc --all D-201
approved with D-201 in CSC LuceScale: 1 line
  line 4: CSC LuceScale
contract: 4
```

In an entity, with `ID`: `approved line N: GUARANTEE ID with D-nnn`. With `--all`:

```
$ bcdd ratify Scale.csc --all D-200
approved with D-200 in ENTITY Scale: 2 lines
  line 5: GUARANTEE g1
  line 7: GUARANTEE g1a
contract: 3
```

`contract` counts the guarantees of the entity, all approved after the command; no header line.

**`BINDING` and profiles.** For a `BINDING` the outputs are those of a CSC, with `BINDING Nome VERSION v` (and ` AS b`)
in place of `CSC NAME`: `approved BINDING Luce VERSION 0.1 (line 3) with D-200`, then `contract: K` with `K` the
`BIND` lines approved after the command, and `lines still pending approval: K` with the lines `line N: BIND element`. For a
profile: `approved PROFILE Segnale VERSION 0.3 (line 2) with D-200`, then `extensions: K`, with `K` the extensions
of the profile, all approved with it. The other lines of the file remain identical byte for byte.

With `--all` in a `BINDING` the form is that of `--all` in a CSC (below), with `in BINDING Nome VERSION v[ AS
b]` in place of `in CSC NAME`: the first line counts the lines changed, then `line N: BINDING Nome VERSION v[ AS b]`
for the header (N is the line of `STATUS`) and `line N: BIND element` for every `BIND` line with its own `STATUS`
approved by the command, finally `contract: K` with `K` the `BIND` lines of the block. For example:

```
$ bcdd ratify Luce.csc --csc filo --all D-200
approved with D-200 in BINDING Luce VERSION 0.1 AS filo: 2 lines
  line 10: BINDING Luce VERSION 0.1 AS filo
  line 12: BIND accesa
contract: 2
```

With `--all` in a CSC: the first line counts the lines changed or added (`1 line` in the singular, otherwise `N
lines`); then one line for each, in file order, `line N: CSC NAME` for the header (N is the line of
`STATUS`, also when it has been added) and `line N: KEYWORD ID` for a contractual line (N is its first line);
then `contract: K`, with `K` the `GUARANTEE`s and `ASSUME`s of the CSC approved after the command. Usually no line
remains pending approval and the line `lines still pending approval` is not printed. The only lines that remain pending approval are those that use
an extension of a profile pending approval (section 7.1, point 0a), which `--all` cannot approve: then, after
`contract`, `lines still pending approval: K` and those lines are printed, as without `--all`. For example:

```
$ bcdd ratify R03_righe.csc --all D-130
approved with D-130 in CSC Righe: 3 lines
  line 4: CSC Righe
  line 8: GUARANTEE g1a
  line 11: ASSUME a1
contract: 4
```

```
$ bcdd ratify Luce.csc --csc Luce --all D-202
approved with D-202 in CSC Luce: 1 line
  line 4: CSC Luce
contract: 3
lines still pending approval: 1
  line 15: GUARANTEE g10
```

### 12.5 Errors and codes

Every message goes to standard error and ends with LF; standard output remains empty; the file does not
change. `ARG`, `ID`, `NAME`, `FILE` are the arguments as they were written.

| Case | Message | Code |
|---|---|---|
| positional arguments neither 2 nor 3; `--csc` without a name or repeated; `--all` repeated, or with 3 positional arguments; `--dir` without argument, or with the same folder twice; another option that begins with `-`, including `--dir=X` | `usage: bcdd ratify FILE [--csc NAME] [--dir FOLDER]... [ID \| --all] D-number` | 2 |
| a `--dir` folder that does not exist, is not a folder, cannot be read | as in `check` (section 10), with the prefix `bcdd ratify:` | 2 |
| the last positional argument is not a decision | `bcdd ratify: invalid decision: ARG (D-number is needed)` | 2 |
| the ID is not a word of rule L8 | `bcdd ratify: invalid id: ARG` | 2 |
| the name after `--csc` is not a Name | `bcdd ratify: invalid name: ARG` | 2 |
| file not found, not a file, not readable, not UTF-8 | as in `check`, with the prefix `bcdd ratify:` | 2 |
| the file does not pass `bcdd check --strict` | `bcdd ratify: the file does not pass bcdd check --strict (errors: E, unrecognised lines: U): I am not approving` | 1 |
| no block to approve (only `VERIFICATION`) | `bcdd ratify: the file contains no block to approve: a VERIFICATION is not approved` | 1 |
| no CSC or entity and several blocks among `BINDING` and `PROFILE`, no `--csc` | `bcdd ratify: the file contains N blocks to approve: say which with --csc NAME` | 2 |
| a `BINDING` or a profile with `ID` | `bcdd ratify: in a BINDING the header or --all is approved, not a line` (or `bcdd ratify: in a PROFILE the whole profile is approved, not a line`) | 1 |
| the `BINDING` or the profile is already approved | `bcdd ratify: the BINDING NAME VERSION v is already approved (D-mmm): I am changing nothing` (or `the PROFILE NAME VERSION v`) | 1 |
| no CSC and several entities, no `--csc` | `bcdd ratify: the file contains N ENTITYs: say which with --csc NAME` | 2 |
| several CSCs and no `--csc` (`N` counts only the CSCs) | `bcdd ratify: the file contains N CSCs: say which with --csc NAME` | 2 |
| `--csc NAME` and no block to approve with that name | `bcdd ratify: no block to approve with the name NAME in the file` | 1 |
| entity, without `ID` or `--all` | `bcdd ratify: the header of the ENTITY NAME is not approved: say a GUARANTEE or --all` | 1 |
| entity, `ID` that is not a name of the entity | `bcdd ratify: no GUARANTEE with id ID in the ENTITY NAME` | 1 |
| entity, `ID` the name of a part or of a scenario | `bcdd ratify: ID is not a GUARANTEE: in an ENTITY only guarantees are approved` | 1 |
| entity, `--all` and no guarantee pending approval | `bcdd ratify: ENTITY NAME has no guarantees still pending approval: I am changing nothing` | 1 |
| entity, a boundary not found (step 7) | `bcdd ratify: ENTITY NAME, line N: CITATION not found: I am not approving its guarantees`; with a reason from the search (section 9.4): `… not found (REASON): …` | 1 |
| entity, a boundary of another version | `bcdd ratify: ENTITY NAME, line N: CITATION found in PATH at line M with VERSION v: I am not approving its guarantees` | 1 |
| entity, a boundary in a file with errors | `bcdd ratify: ENTITY NAME, line N: CITATION found in PATH at line M, which has E errors: I am not approving its guarantees` (`1 error` for one error) | 1 |
| the CSC is already approved (case c3) | `bcdd ratify: the CSC NAME is already approved (D-mmm): I am changing nothing` | 1 |
| with `--all`: the header and all lines are already approved | `bcdd ratify: CSC NAME is already entirely part of the contract: I am changing nothing` | 1 |
| `ID` is not a name of the CSC | `bcdd ratify: no GUARANTEE or ASSUME with id ID in the CSC NAME` | 1 |
| `ID` is a name of the CSC but not of a contractual line nor of a detail of a `DEFINE` or of a scenario | `bcdd ratify: ID is neither a GUARANTEE nor an ASSUME: only contractual lines and details are approved` | 1 |
| the line is already approved (case r3; in an entity, a guarantee with its own `STATUS RATIFIED BY`) | `bcdd ratify: ID is already part of the contract (line N): I am changing nothing` | 1 |
| check of the new text failed | `bcdd ratify: internal error: the modified text does not pass check; file not touched` | 1 |
| errors of the safe write | section 12.6 | 1 |

In the boundary messages `CITATION` is the line as it is (`OFFERS X`, `USES X VERSION w`); `PATH` as in the
lines of the citations (section 9.4), and in the same file `in this file at line M`.

Code 2 means “the command could not be executed as it is written”; code 1 “the command
is clear, but the file does not allow it”. It is the same division as in `bcdd new`.

### 12.6 The safe write

`bcdd ratify` writes the file in such a way that it never remains half-written, and that nothing changes beyond what the command
declares:

1. the new content is written to a **temporary file in the same folder** as the file, with a name that begins
   with `.` and ends with `.tmp` followed by a number; it is then forced to disk;
2. the temporary file takes the same permissions as the original file;
3. **immediately before replacing**, `bcdd` rereads the original file: if its bytes are no longer those read
   at the start of the command, it **does not replace** it (for example because the person has saved the file from their editor in the
   meantime);
4. the temporary file takes the place of the original file with a single system operation, which either succeeds or
   leaves the file as it was;
5. in every error case the temporary file is deleted: nothing remains in the folder.

From the moment it creates the temporary file until the replacement, the command **defers** Ctrl-C: it finishes the write and then
exits normally. If `FILE` is a **symbolic link**, the file it points to is written and the link remains;
if the file has **several names** (hard links), the command refuses, because replacing it would detach the other
names, which would remain with the old content.

The messages, on standard error, with code 1; the file remains as it was. `FILE` is the name of the file as it was
written, `CAUSE` the description of the error given by the system, as in `bcdd new`:

| Case | Message |
|---|---|
| the temporary file cannot be created or written (folder not writable, disk full) | `bcdd ratify: I cannot write FILE: CAUSE` |
| the file changed after reading (point 3) | `bcdd ratify: FILE changed during the command: nothing written` |
| the file has several hard links | `bcdd ratify: FILE has more than one hard link: I am not rewriting it` |

---

## 13. The dialogue file

The file `FILE.dialogo` is located next to the CSC file. It is written only by `bcdd refine`, which keeps in it the questions of the language
model and the answers of the person, and sends it to the model in subsequent rounds; `check` and `ratify` do not
read it, and it is not a CSC file. Example, for the staircase light (the first lines of a file with two rounds):

```
-- bcdd refine: questions from the language model and answers from the person. It can be edited or deleted by hand.

GIRO 2026-10-17T12:17:35+02:00 CSC LuceScale
DOMANDA For g2: how long does the light stay on after the last press, and with what tolerance?
RISPOSTA 1 minute, with a tolerance of 5 s
DOMANDA For g3: what happens if someone presses the button while the light is already on?
RISPOSTA the on-time restarts from the beginning
```

| Line | What it says |
|---|---|
| the first, a comment | present from the creation of the file, and does not change |
| `GIRO DATE CSC NAME` | the start of a round, after a blank line; for an entity `GIRO DATE ENTITY NAME`. `DATE` is the local date and time to the second, with the time zone, in the form `YYYY-MM-DDTHH:MM:SS+HH:MM` (or `-HH:MM`): that of the start of the first call to the model in the round. A round has a single `GIRO` line |
| `DOMANDA text` | a question to which the person has answered; the following lines of a long question are indented by two spaces |
| `RISPOSTA text` | the answer; for a choice, the text of the choice and not the number |
| `CSC A PARTE NAME: REASON` | after the `DOMANDA`/`RISPOSTA` pairs of the round: a new topic that the model has signalled and the person has seen, one line for each, in the order in which it was shown |

The words `GIRO`, `CSC`, `ENTITY`, `DOMANDA`, `RISPOSTA` and `CSC A PARTE` are written in Italian in every language
of `bcdd`; only the first comment line follows the language. The rest of each line is the date, the name or the text.

A round is written if it has at least one answer or at least one `CSC A PARTE`. Skipped questions, proposals and
replacements are not recorded: the accepted proposals and the accepted replacements appear in the CSC file. If the existing file does not
end with LF, one is added before the new round; the rest of the content remains identical, byte for byte, and the
write is the safe write of section 12.6. The file is UTF-8 text with LF line endings; the person can correct it or
delete it (the process starts again without memory).

---

## 14. What `bcdd` does not check

The list states explicitly what `bcdd` does not check, so that nobody believes it checked:
- **the meaning of formulas**: `check` reads the formulas and checks their form, names and types, but does not evaluate them.
  It does not check that a scenario has the outcome it declares, that every trigger occurs in a scenario, that the guarantees and
  the assumptions can hold together, nor that a formal detail is consistent with the line it details: these are the
  “not executed” checks of section 15 of the report. It does not write the expanded form of shorthands and does not
  check that the `REDUCES TO` of an extension has consistent types. E36 recognises only a reduction that is a
  construct with only the parameters as operands: an equivalent reduction written in another way (`NOT NOT c`,
  `p AND p`, `x * 1`) is not signalled, nor are two extensions of the same profile with the same reduction apart from the
  names of the parameters;
- **the forms withdrawn from the language or reserved**: `FACE`, `LINK`, `MAP`, `REFINED BY`, `REFINES` are unrecognised
  lines;
- **the rules by judgement**: that a detail in words is consistent with the line it details, that the meaning of
  an extension does not describe the implementation, that an extension without reduction does not repeat a form of the language,
  that `MEANING` and `REDUCES TO` say the same thing: these are entries of section 14 of the report;
- **recordings**: `check` does not read traces recorded on a built system; the coverage of section 13
  states which guarantees an instrument observes, not that they are satisfied;
- **the values of constants**: `DEFINE ATTESA_MAX_LLM := 120 s` is recognised, but is not compared with
  anything; a constant name inside a string is text (section 4.3);
- **versions**: whether a VERSION is new, what has changed with respect to the previously approved version, and whether a line
  with its own `STATUS RATIFIED BY` has changed text after approval (section 7.2);
- **the levels of details**: no limit and no warning (section 7.3);
- **unknown types**: a value of an undeclared type, of a type described in words, of an `UNDECIDED` constant
  or of a name supplied by an extension is not checked (section 4.13); in an entity scenario a value
  that is a name, and an element of a cited CSC whose type is not a base type, are not checked (section 4.6); in an
  entity formula no element `X.y` has a known type, so on those formulas there is never E25 (section 4.9); the
  bounds of a range are not propagated in expressions;
- **the uses of two kinds of extension**: in this version `bcdd` does not read the uses of extensions of `KIND
  RELATION` and `KIND SCENARIO-FORM`: the lines that contain them are unrecognised (section 4.14);
- **the bounds of ranges**, including negative ones: `Real [20.0 .. -20.0]` is recognised, the bounds are not compared
  with each other;
- **units**: only `s` and `ms`; a different unit of measurement (`90 dB`) makes the line unrecognised, and the author
  puts it in the name of the constant and in the text of the guarantees;
- **copies**: the multiplicity of a part states how many copies there are, not when they are created and cease, nor how
  they are distinguished. The copies of the same part do not satisfy one another: the `OFFERS` of a copy does not count
  for the `USES` of another copy of the same part;
- **the lifecycle of requests**: `requested` of an `AUTONOMOUS` request, or `completed` before
  `accepted`, are not signalled;
- **the content of strings**: a `PURPOSE "to be filled in…"` left as it is is not signalled;
- **the other CSCs, beyond the search**. `check` searches for the CSCs and the entities that the entities of the file cite and reports their
  version, status and outcome (section 9.4), but:
  - a single depth: of a part, its parts are not read, nor the CSCs it cites; parts of parts,
    an entity that contains itself beyond the first depth and indexed parts (`ago[ch] : Strumento`) do not exist;
  - of a cited CSC the declarations are read only for the qualified names of entity scenarios, not the values
    of its lists of values;
  - a withdrawn block (`REFINEMENT VIEW`) has no parts or citations;
  - it does not check that the CSCs that an entity provides are supported by some part (an entity can provide a CSC that
    no part provides on its own: it is a judgement);
  - it does not check that an entity guarantee rests on those of the parts, nor that a consumer of a CSC satisfies its
    assumptions: these are judgements;
  - it does not know whether the CSC found is the right one: it finds it by name, and by version if the citation states it;
    a CSC with the same name in another `--dir` folder remains unseen if a first one has already been found;
  - it does not read the `.dialogo` file, nor the types described in another file; two `BINDING`s for the same CSC in different
    files are not compared (E40 applies in the checked file);
- **the location and the order of entities**: the language does not allow stating where an entity is located (device,
  process, machine), nor which entity comes first among several entities on the same side of a boundary. This is a
  choice of the language, not a limitation of `bcdd`;
- **meaning**: whether a guarantee in words is sensible, consistent with the others or verifiable is stated
  by whoever judges, not by `bcdd`.
