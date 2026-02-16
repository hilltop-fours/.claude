# PR Response Style Guide

Guidelines for how Claude should write PR review responses for this project.

---

## General Rules

**Language:** Dutch (casual, conversational)

**Punctuation:** NO punctuation at all
- No periods at end of sentences
- No commas between clauses
- No colons or semicolons
- Write as a continuous flow without any terminal punctuation

**Capitalization:**
- No capitalization at start of sentences
- Only capitalize words that are inherently capitalized (proper nouns, codebase references that are capitalized in code)

---

## Two Types of PR Comments

### Type 1: Action Feedback ("do X instead" / "remove Y" / "don't use Z")

Reviewer tells you to change something. Response = what you did about it.

**Tone:**
- Casual and direct
- Explain what was changed not where (no file names or component names unless essential)
- Write so a third person reading later (without seeing the original code snippet) understands what got fixed

### Type 2: Questions ("why did you do this?" / "what's this for?")

Reviewer asks for your reasoning. Response = explain your thinking humbly.

**Tone:**
- Humble and suggestive not authoritative
- Come from a place of "this is what I think" not "this is how it is"
- Use softening words like: "volgens mij" / "ik denk dat" / "misschien" / "het idee was" / "zou kunnen"
- Never state things as absolute facts when explaining your own choices
- You're sharing your perspective not lecturing the reviewer

**Length (both types):**
- Keep it short and simple
- Usually 1-2 sentences max
- One clear idea per response

**Code formatting:**
- Inline code in single backticks: `` `methodName()` `` or `` `<button>` ``
- Multi-line code in triple backticks with language tag when needed

---

## Before/After Examples

### Example 1: Service Refactoring

**❌ Before (too formal, has punctuation):**
> de business logic (`canChangeOwner()` en `getOwnerChangeBlockReason()`) verplaatst van de service naar de component als private methods. de service doet nu alleen de http call (`changeOwner()`), wat past bij het patroon dat services alleen http calls moeten doen.

**✅ After (your style):**
> `canChangeOwner()` en `getOwnerChangeBlockReason()` verplaatst van de service naar de component en de service doet nu alleen de http call

**Key changes:**
- Removed punctuation (periods, parenthetical explanation)
- Removed "als private methods" (implied by context)
- Removed explanation of why (the reviewer already knows the pattern)
- Shorter, more direct

### Example 2: Removing Dead Code

**❌ Before (too formal, uses "was"):**
> de `title` en `type` fields waren inderdaad niet gebruikt en zijn verwijderd zodat roleInfoMessage nu gewoon een string teruggeeft

**✅ After (your style):**
> werd toch niet gebruikt en heb ik verwijderd samen met title zodat `roleInfoMessage` nu gewoon een string teruggeeft

**Key changes:**
- First person "heb ik verwijderd" instead of passive "zijn verwijderd"
- "werd toch niet gebruikt" more casual than "waren inderdaad niet gebruikt"
- No punctuation

---

### Example 3: Confirming and Simplifying

**❌ Before (repeats too much):**
> klopt de `title` en `type` fields zijn verwijderd en roleInfoMessage is nu een simpele string computed signal

**✅ After (your style):**
> klopt `title` en `type` waren niet nodig en heb ze verwijderd en `roleInfoMessage` geeft nu direct een string terug

**Key changes:**
- Dropped "fields" (unnecessary detail)
- "waren niet nodig" instead of "zijn verwijderd" (explains why not just what)
- "heb ze verwijderd" first person
- "geeft nu direct een string terug" more natural than "is nu een simpele string computed signal"

---

### Example 4: Moving Logic Between Services

**❌ Before (too explanatory):**
> permissions logica verplaatst naar `AuthService` en de aparte `UserPermissionsService` is verwijderd

**✅ After (your style):**
> heb de het verplaatst naar `AuthService` en `UserPermissionsService` verwijderd

**Key changes:**
- Dropped "permissions logica" (reviewer knows what was moved from context)
- Dropped "de aparte" (unnecessary qualifier)
- First person "heb de het verplaatst"
- Shorter overall

### Example 5: Answering a Question (Type 2 - humble/suggestive)

**Reviewer asked:** "Waar wordt deze voor gebruikt? Je hebt ook selectedRoadAuthority?"

**❌ Before (too authoritative, stating facts):**
> `selectedOption` bepaalt welke radio button actief is (keep/change) en `selectedRoadAuthority` is de specifieke wegbeheerder die gekozen is uit de dropdown dat zijn twee verschillende dingen en beide nodig

**✅ After (your style):**
> volgens mij heb je `selectedOption` nodig om te bepalen welke radio button actief is (keep/change) en `selectedRoadAuthority` is dan welke wegbeheerder er gekozen is uit de dropdown dus ik denk dat ze allebei nodig zijn

**Key changes:**
- Opens with "volgens mij" instead of stating directly
- "ik denk dat ze allebei nodig zijn" instead of "dat zijn twee verschillende dingen en beide nodig"
- Explains reasoning as personal understanding not as absolute truth
- Same information but delivered humbly

**Note:** This example was accepted without corrections on the first try

---

## When to Apply This

Use this style for all PR review responses in this project. When Claude provides a PR response, it should match the pattern shown in "After" examples.

---

## How to Update This Guide

When you edit a PR response to your preferred style, tell Claude to add it as a new example with before/after pair. Over time, this file becomes the reference for the exact style and tone you prefer.
