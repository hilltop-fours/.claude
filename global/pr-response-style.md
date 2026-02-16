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

## Content Style

**Tone:**
- Casual and direct
- Explain what was changed, not where (no file names or component names unless essential)
- Write so a third person reading later (without seeing the original code snippet) understands what got fixed

**Length:**
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

---

## When to Apply This

Use this style for all PR review responses in this project. When Claude provides a PR response, it should match the pattern shown in "After" examples.

---

## How to Update This Guide

When you edit a PR response to your preferred style, tell Claude to add it as a new example with before/after pair. Over time, this file becomes the reference for the exact style and tone you prefer.
