---
name: penpot-design
description: Design and manipulate Penpot projects using the Penpot MCP Plugin. Use when working with Penpot designs including creating shapes, boards, layouts, styling, components, generating CSS/HTML from designs, or any design task when Penpot MCP is connected. Triggers on mentions of "Penpot", design manipulation requests with connected MCP, or design-to-code workflows.
license: MIT
metadata:
  author: iperez
  version: "1.0.0"
---

# Penpot Design Skill

Create, edit, and manipulate designs in Penpot using the connected MCP plugin.

## Prerequisites

User must have Penpot MCP Plugin connected to their Penpot project.

## Available Tools

| Tool | Purpose |
|------|---------|
| `execute_code` | Run JavaScript in Penpot plugin context |
| `penpot_api_info` | Get API docs for types/members |
| `export_shape` | Export shapes as PNG/SVG for inspection |

## Core Objects

```javascript
penpot          // Main API: selection, root, library, fonts, viewport
penpotUtils     // Helpers: findShape, findShapes, shapeStructure, setParentXY
storage         // Persistent storage across tool calls
```

## Critical Rules

### 1. Child Ordering is REVERSED in Flex Layout
For `dir="column"` or `dir="row"`, the `children` array order is **reversed** relative to visual order. First in array = visually last.

### 2. Use insertChild, NOT appendChild
```javascript
// ✅ CORRECT - predictable ordering
parent.insertChild(parent.children.length, shape);

// ❌ BROKEN - unpredictable placement
parent.appendChild(shape);  // Don't use for non-flex boards!
```

**Exception**: For flex layout boards, use `board.appendChild(shape)` which inserts at the visual end.

### 3. Position Properties
```javascript
shape.x = 100;           // ✅ Writable - absolute page coordinates
shape.y = 200;           // ✅ Writable
shape.parentX;           // ❌ READ-ONLY
shape.parentY;           // ❌ READ-ONLY

// To set relative position:
penpotUtils.setParentXY(shape, relativeX, relativeY);
```

### 4. Resize and Dimensions
```javascript
shape.width;             // ❌ READ-ONLY
shape.height;            // ❌ READ-ONLY
shape.resize(200, 100);  // ✅ Use method to change size
```

### 5. Text Sizing
```javascript
text.fontSize = '24';         // ✅ Changes text size
text.resize(200, 100);        // ❌ Only changes bounding box, not font
text.growType = 'auto-width'; // ✅ Always set after resize for auto-sizing
```

### 6. Store Selection Immediately
```javascript
storage.selection = [...penpot.selection]; // Selection can change!
```

## Workflow

### 1. Explore Design Structure
```javascript
// Page overview (depth 3)
return penpotUtils.shapeStructure(penpot.root, 3);

// Store current selection
storage.selection = [...penpot.selection];
return storage.selection.map(s => ({ id: s.id, name: s.name, type: s.type }));
```

### 2. Find Elements
```javascript
// By name
const shape = penpotUtils.findShape(s => s.name === 'Button');

// By type
const texts = penpotUtils.findShapes(s => s.type === 'text', penpot.root);

// Images (including fill images)
const images = penpotUtils.findShapes(
  s => s.type === 'image' || s.fills?.some(f => f.fillImage),
  penpot.root
);

// All boards
const boards = penpotUtils.findShapes(s => s.type === 'board', penpot.root);
```

### 3. Create Shapes
```javascript
// Rectangle
const rect = penpot.createRectangle();
rect.name = 'Card Background';
rect.x = 100; rect.y = 100;
rect.resize(300, 200);
rect.fills = [{ fillColor: '#FFFFFF' }];
rect.borderRadius = 12;

// Text
const text = penpot.createText('Hello World');
text.x = 120; text.y = 120;
text.fontSize = '24';
text.fontFamily = 'Inter';
text.growType = 'auto-width';

// Board (frame/artboard)
const board = penpot.createBoard();
board.name = 'Card';
board.x = 0; board.y = 0;
board.resize(400, 300);
board.fills = [{ fillColor: '#FFFFFF' }];

// Ellipse
const ellipse = penpot.createEllipse();
ellipse.resize(100, 100);

// Path
const path = penpot.createPath();
```

### 4. Build Hierarchy

**CRITICAL**: Add background shapes FIRST, then foreground shapes. Z-order = array order.

```javascript
const card = penpot.createBoard();
card.resize(300, 200);

// 1. Background first (will be behind)
const bg = penpot.createRectangle();
bg.resize(300, 200);
bg.fills = [{ fillColor: '#F5F5F5' }];
card.insertChild(card.children.length, bg);

// 2. Content on top (will be in front)
const title = penpot.createText('Title');
title.fontSize = '20';
card.insertChild(card.children.length, title);

// Position relative to parent
penpotUtils.setParentXY(bg, 0, 0);
penpotUtils.setParentXY(title, 20, 20);
```

### 5. Flex Layout
```javascript
const container = penpot.createBoard();
container.resize(400, 0);

// Add flex layout (use helper to preserve child order)
const flex = penpotUtils.addFlexLayout(container, 'column');
flex.rowGap = 16;
flex.columnGap = 16;
flex.topPadding = 24;
flex.rightPadding = 24;
flex.bottomPadding = 24;
flex.leftPadding = 24;
flex.alignItems = 'stretch';
flex.justifyContent = 'start';

// For flex boards, appendChild adds at visual end
container.appendChild(item1);
container.appendChild(item2);

// Child sizing within flex
item1.layoutChild.horizontalSizing = 'fill';
item1.layoutChild.verticalSizing = 'auto';
```

**Flex Layout Properties:**
- `dir`: 'row' | 'column' | 'row-reverse' | 'column-reverse'
- `alignItems`: 'start' | 'center' | 'end' | 'stretch'
- `justifyContent`: 'start' | 'center' | 'end' | 'stretch' | 'space-between' | 'space-around' | 'space-evenly'
- `rowGap`, `columnGap`: number
- `topPadding`, `rightPadding`, `bottomPadding`, `leftPadding`: number

### 6. Styling

**Fills:**
```javascript
// Solid color
shape.fills = [{ fillColor: '#3B82F6', fillOpacity: 1 }];

// Gradient
shape.fills = [{
  fillColorGradient: {
    type: 'linear',
    startX: 0, startY: 0,
    endX: 1, endY: 1,
    width: 1,
    stops: [
      { color: '#3B82F6', offset: 0 },
      { color: '#8B5CF6', offset: 1 }
    ]
  }
}];
```

**Strokes:**
```javascript
shape.strokes = [{
  strokeColor: '#E5E7EB',
  strokeWidth: 1,
  strokeAlignment: 'center', // 'inner' | 'outer'
  strokeStyle: 'solid'       // 'dotted' | 'dashed'
}];
```

**Shadows:**
```javascript
shape.shadows = [{
  style: 'drop-shadow',  // or 'inner-shadow'
  color: { color: '#000000', opacity: 0.1 },
  offsetX: 0,
  offsetY: 4,
  blur: 12,
  spread: 0
}];
```

**Border Radius:**
```javascript
shape.borderRadius = 8;  // All corners
// Or individual:
shape.borderRadiusTopLeft = 8;
shape.borderRadiusTopRight = 8;
shape.borderRadiusBottomRight = 0;
shape.borderRadiusBottomLeft = 0;
```

**Opacity & Blend:**
```javascript
shape.opacity = 0.8;
shape.blendMode = 'multiply'; // 'normal' | 'darken' | 'screen' | etc.
```

### 7. Text Styling
```javascript
const text = penpot.createText('Hello');
text.fontSize = '16';
text.fontFamily = 'Inter';
text.fontWeight = '600';
text.fontStyle = 'normal';     // or 'italic'
text.lineHeight = '1.5';
text.letterSpacing = '0';
text.align = 'center';         // 'left' | 'right' | 'justify'
text.verticalAlign = 'center'; // 'top' | 'bottom'
text.textTransform = 'uppercase'; // 'lowercase' | 'capitalize'
text.textDecoration = 'underline'; // 'line-through'
text.direction = 'ltr';        // 'rtl'
text.growType = 'auto-width';  // 'auto-height' | 'fixed'

// Text color
text.fills = [{ fillColor: '#1F2937' }];
```

### 8. Z-Order Methods
```javascript
shape.bringToFront();    // Move to top
shape.sendToBack();      // Move to bottom
shape.bringForward();    // Move up one level
shape.sendBackward();    // Move down one level
shape.setParentIndex(0); // Set exact position (0-based)
```

## Design-to-Code

### Generate CSS
```javascript
// CSS for selected elements
return penpot.generateStyle(penpot.selection, {
  type: 'css',
  withPrelude: true,
  includeChildren: true
});
```

### Generate HTML/SVG
```javascript
return penpot.generateMarkup(penpot.selection, { type: 'html' });
// or
return penpot.generateMarkup(penpot.selection, { type: 'svg' });
```

### Design-to-Code Workflow
1. Select target element(s) in Penpot
2. Use `export_shape` to visually verify
3. Generate CSS with `generateStyle`
4. Generate markup with `generateMarkup`
5. Combine into working code

**CRITICAL**: Never assume values. Strictly adhere to the design. Use black/white defaults only when information is genuinely missing.

## Components & Libraries

```javascript
// Access libraries
const local = penpot.library.local;
const connected = penpot.library.connected;

// Find component
const btn = local.components.find(c => c.name.includes('Button'));

// Create instance
const instance = btn.instance();
instance.x = 100;
instance.y = 100;

// Access colors
const primary = local.colors.find(c => c.name === 'Primary');

// Access typography
const heading = local.typographies.find(t => t.name === 'Heading');

// Create library assets
const newColor = local.createColor();
newColor.name = 'Brand Blue';
newColor.color = '#3B82F6';

const newTypo = local.createTypography();
newTypo.name = 'Body';
newTypo.fontSize = '16';
newTypo.fontFamily = 'Inter';
```

## Visual Inspection

Always verify designs visually:
```javascript
// Use export_shape tool to see the result
// export_shape({ shapeId: shape.id, format: 'png' })
// or use 'selection' for currently selected shape
```

## Common Patterns

See [references/patterns.md](references/patterns.md) for:
- Card components
- Button variants
- Navigation bars
- Form fields
- Grid layouts
- Modal dialogs

## API Quick Reference

See [references/api-quick-ref.md](references/api-quick-ref.md) for:
- All shape types and properties
- Layout system details
- Complete styling reference
- Library management

## Shape Types

| Type | Description |
|------|-------------|
| `Board` | Container/frame, supports layouts |
| `Rectangle` | Basic rectangle shape |
| `Ellipse` | Circle/ellipse shape |
| `Text` | Text element |
| `Path` | Vector path |
| `Group` | Non-layout container |
| `Boolean` | Boolean operations result |
| `Image` | Image element (legacy) |
| `SvgRaw` | Raw SVG content |
