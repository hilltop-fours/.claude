# PR Response Style Guide

Guidelines for how Claude should write PR review responses for this project.

---

## General Rules

**Language:** Dutch (casual, conversational)

**Punctuation:** NO punctuation at all
- No periods at end of sentences
- No commas between clauses
- No colons or semicolons
- No em dashes (—) ever — AI overuses these, never use them
- Write as a continuous flow without any terminal punctuation

**Capitalization:**
- No capitalization at start of sentences
- Only capitalize words that are inherently capitalized (proper nouns, codebase references that are capitalized in code)

---

## Three Types of PR Comments

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

### Type 3: Pushback / Clarification ("is X still there?" / "shouldn't this be Y?")

Reviewer flags something they think might be wrong, but the current code is actually correct. Response = explain gently why no change is needed.

**Tone:**
- Same humble/suggestive tone as Type 2
- Don't be defensive — acknowledge what they're seeing and explain calmly
- Use softening words: "volgens mij" / "ik denk dat" / "het idee is" / "klopt dat"
- Leave room for the reviewer to push back further if they disagree

**Length (all types):**
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

## Output Format

Always present the PR response in a **plain text fenced code block** (not a blockquote with `>`):

````
heb het verplaatst naar `AuthService` en `UserPermissionsService` verwijderd
````

This allows the user to copy-paste directly into GitHub without any markdown syntax getting in the way.

---

## When to Apply This

Use this style for all PR review responses in this project. When Claude provides a PR response, it should match the pattern shown in "After" examples.

---

### Example 6: Explaining why something was removed (Type 2 - humble/suggestive)

**Reviewer asked:** "h2?"

**Claude attempt 1 (too formal, ends with "semantiek"):**
> de `h2` was weggevallen doordat de content in `tsf-side-panel-header` terechtkwam die zelf al de heading styling regelt maar heb hem toch teruggebracht voor de semantiek

**Claude attempt 2 (better but wrong tense, "weggehaald" instead of first person past):**
> heb de `h2` weggehaald omdat de content in `tsf-side-panel-header` terechtkwam die zelf al de heading styling regelt maar heb hem toch teruggebracht

**✅ Final accepted version:**
> had de `h2` weggehaald omdat de content in `tsf-side-panel-header` kwam en die had zelf al de heading styling

**Claude attempt 3 (adds question about approach but too wordy and "utility classes" is jargon):**
> had de `h2` weggehaald omdat de content in `tsf-side-panel-header` kwam en die had zelf al de heading styling maar heb hem teruggebracht en de styling handmatig toegevoegd via onze utility classes — vraag me wel af of je liever `ndw-heading-sm` gebruikt of dat je het zo goed vindt

**✅ Final accepted version:**
> had de `h2` weggehaald omdat de content in `tsf-side-panel-header` kwam en die had zelf al de styling maar heb hem teruggebracht en de styling toegevoegd via classes de vraag is alleen of je toch liever `ndw-heading-sm` gebruikt of dat je het zo goed vindt

**Key lessons:**
- Use `had ... weggehaald` (past perfect) not `heb ... weggehaald` when explaining what you did before
- Don't end with abstract nouns like "semantiek" — keep it concrete and practical
- When the fix involves a judgment call, invite the reviewer to weigh in at the end
- Avoid jargon like "utility classes" — just say "classes"
- "heading styling" → just "styling" is more natural when context is clear
- When asking a question, lead with "de vraag is alleen of" rather than "vraag me wel af of"

### Example 7: Responding to a 2-part comment (fix + question about approach)

**Reviewer comment:** "Moet dit geen h2 blijven? [...] geen fan van deze 5 classes op 1 element."

Two parts: (1) request to revert to h2, (2) question about whether many classes on one element is okay.

**Claude attempt 1 (too rude/assertive about the classes):**
> de `h2` teruggebracht en de classes zijn onze eigen utility classes die we door de hele app gebruiken in plaats van de design system classes

**Claude attempt 2 (better but "laat me weten" is too open-ended):**
> de `h2` teruggebracht en wat de classes betreft dat zijn de classes die we zelf gedefinieerd hebben en afgesproken hebben om inline te gebruiken maar laat me weten als je dat anders ziet

**✅ Final accepted version:**
> heb de `h2` teruggebracht en over de classes op 1 element hadden we afgesproken dat de dingen die we zelf hadden gemaakt zoals in de `_spacing.scss` die mogen gewoon gebruikt worden inline

**Key lessons:**
- When a comment has 2 parts, address both in one response
- Reference the actual agreement/file (`_spacing.scss`) to make it concrete instead of vague
- "hadden we afgesproken" is better than "we zelf gedefinieerd hebben en afgesproken hebben" — less repetitive
- Don't end with "laat me weten als je dat anders ziet" — it's too open; just state the agreement confidently

### Example 8: Confirming correct auth setup (Type 3 - pushback/clarification)

**Reviewer asked:** "Verkeersborden kan ik niet bewerken, maar kenmerken wel. Heb al een tijdje niets meer met auth en authGuards gedaan. Maar klopt dat dan wel?"

**Claude attempt 1 (too assertive, no softening):**
> klopt ja dat zijn twee aparte rollen in Keycloak `traffic-sign-edit` voor verkeersborden en `road-feature-edit` voor kenmerken dus iemand kan de ene hebben zonder de andere

**✅ Final accepted version:**
> klopt ja dat zijn vgm want in keycloak heb je twee aparte rollen `traffic-sign-edit` voor verkeersborden en `road-feature-edit` voor kenmerken dus ik zou denken dat iemand de ene kan hebben zonder de andere

**Key lessons:**
- Use "vgm" (vermoedelijk) as a natural softener for Type 3 confirmations — less stiff than "volgens mij"
- "ik zou denken dat" is more humble than stating it as a direct fact ("iemand kan de ene hebben zonder de andere")
- "want in keycloak heb je" explains the reasoning in a natural, conversational way
- Don't just confirm — briefly explain the mechanism so the reviewer understands why

---

## How to Update This Guide

When you edit a PR response to your preferred style, tell Claude to add it as a new example with before/after pair. Over time, this file becomes the reference for the exact style and tone you prefer.
