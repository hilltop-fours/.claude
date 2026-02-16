# Styling Guidelines - GRG Wegkenmerken Verkeersborden

## Critical Rule: No Bootstrap Classes

**NEVER use Bootstrap classes in this project.**

The project is actively removing Bootstrap dependencies. Do not use any Bootstrap classes including but not limited to:
- Grid system: `.row`, `.col-*`, `.container`, `.container-fluid`
- Typography: `.fw-*`, `.fs-*`, `.text-muted`, `.lead`
- Spacing: `.m-*`, `.p-*`, `.g-*`, `.gap-*` (Bootstrap versions)
- Components: `.btn-*`, `.form-*`, `.alert-*`, `.card-*`, `.badge-*`, `.nav-*`
- Utilities: `.d-*`, `.flex-*`, `.align-*`, `.justify-*` (Bootstrap versions)

## Required: Use Design System Classes Only

**ALL CSS classes MUST come from:**
```
/Users/daniel/Developer/GRG-Wegkenmerken-verkeersborden/traffic-sign-frontend/src/assets/styles/
```

### Available Style Files

**Layout** (`layout/_layout.scss`):
- Display: `.d-flex`, `.d-block`, `.d-inline-flex`, `.d-none`
- Flexbox: `.flex-row`, `.flex-column`, `.justify-content-*`, `.align-items-*`
- Text alignment: `.text-left`, `.text-center`, `.text-right`
- Sizing: `.w-100`, `.h-100`

**Spacing** (`layout/_spacing.scss`):
- Margin: `.m-{0-5}`, `.mt-*`, `.mb-*`, `.ms-*`, `.me-*`, `.mx-*`, `.my-*`, `.m-auto`, `.ms-auto`
- Padding: `.p-{0-5}`, `.pt-*`, `.pb-*`, `.ps-*`, `.pe-*`, `.px-*`, `.py-*`
- Gap: `.gap-{0-5}`

**Typography** (`layout/_font.scss`):
- Font size: `.font-2xs`, `.font-xs`, `.font-sm`, `.font-md`, `.font-lg`, `.font-xl`, `.font-2xl`
- Font weight: `.font-light`, `.font-regular`, `.font-bold`
- Color: `.font-gray`

**Components** (`components/`):
- Buttons: `_button.scss`
- Cards: `_card.scss`
- Columns: `_columns.scss` (2-column grid with `dl[ndw-columns]`)
- List items: `_list-item.scss`
- Road feature details: `_road-feature-detail.scss`
- Modals: `_modal.scss`
- Nav pills: `_nav-pills.scss`
- Popovers: `_popover.scss`
- Quick actions: `_quick-action.scss`
- Switches: `_switch.scss`
- Traffic signs: `_traffic-sign.scss`, `_traffic-sign-popup.scss`

## Workflow: Before Writing CSS

1. **Check existing patterns first**: Look in `/src/assets/styles/` to see if classes already exist
2. **Use design system classes**: Apply classes from the style files above
3. **If pattern doesn't exist**: Create a new reusable pattern in the appropriate style file
4. **Never create one-off styles**: All styling should be reusable and defined in the design system

## Pattern Discovery

Before adding inline styles or creating component-specific SCSS:

```bash
# Search for existing class patterns
grep -r "class-name" /Users/daniel/Developer/GRG-Wegkenmerken-verkeersborden/traffic-sign-frontend/src/assets/styles/

# List all available style files
ls /Users/daniel/Developer/GRG-Wegkenmerken-verkeersborden/traffic-sign-frontend/src/assets/styles/**/*.scss
```

## Examples

### ❌ WRONG (Bootstrap)
```html
<div class="row mb-3">
  <div class="col-6 fw-semibold">Label</div>
  <div class="col-6 text-muted">Value</div>
</div>
```

### ✅ CORRECT (Design System)
```html
<div class="d-flex gap-2 mb-3">
  <div class="font-bold">Label</div>
  <div class="font-gray">Value</div>
</div>
```

Or use semantic HTML with design system attributes:
```html
<dl ndw-columns>
  <dt>Label</dt>
  <dd>Value</dd>
</dl>
```

## Migration Note

This project is **actively removing Bootstrap**. If you encounter existing Bootstrap classes in the codebase:
- **Do NOT update them** - the team is handling this manually
- **Do NOT add new Bootstrap classes** - only use design system classes
- **Reference this pattern** - when writing new code, follow these guidelines

## Questions?

If you need a CSS pattern that doesn't exist in the design system:
1. Check if similar patterns exist in other components
2. Propose creating a new reusable pattern in the appropriate style file
3. Document the new pattern in this file
