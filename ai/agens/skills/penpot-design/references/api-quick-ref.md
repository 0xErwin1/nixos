# Penpot API Quick Reference

Quick reference for the Penpot Plugin API. Use `penpot_api_info` tool for detailed documentation.

## Shape Types

```
Shape = Board | Group | Boolean | Rectangle | Path | Text | Ellipse | SvgRaw | Image
```

| Type | Create Method | Description |
|------|--------------|-------------|
| `Board` | `penpot.createBoard()` | Container with layout support |
| `Rectangle` | `penpot.createRectangle()` | Basic rectangle |
| `Ellipse` | `penpot.createEllipse()` | Circle/ellipse |
| `Text` | `penpot.createText(str)` | Text element |
| `Path` | `penpot.createPath()` | Vector path |
| `Group` | `penpot.group(shapes[])` | Group shapes |

## Common Shape Properties

### Position & Size
```typescript
shape.x: number           // Absolute X (writable)
shape.y: number           // Absolute Y (writable)
shape.width: number       // READ-ONLY
shape.height: number      // READ-ONLY
shape.bounds: Bounds      // READ-ONLY { x, y, width, height }
shape.center: Point       // READ-ONLY { x, y }
shape.parentX: number     // READ-ONLY - relative to parent
shape.parentY: number     // READ-ONLY - relative to parent
shape.boardX: number      // READ-ONLY - relative to board
shape.boardY: number      // READ-ONLY - relative to board

// Methods
shape.resize(width, height)
shape.rotate(angle, center?)
penpotUtils.setParentXY(shape, x, y)  // Set relative position
```

### Hierarchy
```typescript
shape.id: string
shape.name: string
shape.type: string
shape.parent: Shape | null
shape.parentIndex: number

// Methods (Board/Group only)
parent.children: Shape[]
parent.insertChild(index, child)  // ✅ Use this!
parent.appendChild(child)         // ⚠️ Broken for non-flex boards
```

### Visibility & Lock
```typescript
shape.visible: boolean
shape.hidden: boolean
shape.blocked: boolean
shape.opacity: number      // 0-1
```

### Styling
```typescript
shape.fills: Fill[]
shape.strokes: Stroke[]
shape.shadows: Shadow[]
shape.blur?: Blur
shape.blendMode: BlendMode
```

### Border Radius (Rectangle, Board)
```typescript
shape.borderRadius: number
shape.borderRadiusTopLeft: number
shape.borderRadiusTopRight: number
shape.borderRadiusBottomRight: number
shape.borderRadiusBottomLeft: number
```

### Constraints
```typescript
shape.constraintsHorizontal: 'left' | 'right' | 'leftright' | 'center' | 'scale'
shape.constraintsVertical: 'top' | 'bottom' | 'topbottom' | 'center' | 'scale'
shape.proportionLock: boolean
```

### Transform
```typescript
shape.rotation: number
shape.flipX: boolean
shape.flipY: boolean
```

### Z-Order Methods
```typescript
shape.bringToFront()
shape.sendToBack()
shape.bringForward()
shape.sendBackward()
shape.setParentIndex(index)
```

### Other Methods
```typescript
shape.clone(): Shape
shape.remove(): void
shape.export(config): Promise<Uint8Array>
```

## Fill Object

```typescript
interface Fill {
  fillColor?: string           // '#RRGGBB'
  fillOpacity?: number         // 0-1, default 1
  fillColorGradient?: Gradient
  fillImage?: ImageData
}
```

## Stroke Object

```typescript
interface Stroke {
  strokeColor?: string
  strokeOpacity?: number
  strokeWidth?: number
  strokeStyle?: 'solid' | 'dotted' | 'dashed' | 'none'
  strokeAlignment?: 'center' | 'inner' | 'outer'
  strokeCapStart?: StrokeCap
  strokeCapEnd?: StrokeCap
  strokeColorGradient?: Gradient
}
```

## Shadow Object

```typescript
interface Shadow {
  style?: 'drop-shadow' | 'inner-shadow'
  color?: Color
  offsetX?: number
  offsetY?: number
  blur?: number
  spread?: number
  hidden?: boolean
}
```

## Color Object

```typescript
interface Color {
  color?: string     // '#RRGGBB'
  opacity?: number   // 0-1
  gradient?: Gradient
}
```

## Gradient Object

```typescript
interface Gradient {
  type: 'linear' | 'radial'
  startX: number
  startY: number
  endX: number
  endY: number
  width: number
  stops: Array<{
    color: string
    opacity?: number
    offset: number  // 0-1
  }>
}
```

## Text Properties

```typescript
text.characters: string
text.growType: 'fixed' | 'auto-width' | 'auto-height'

// Typography
text.fontId: string
text.fontFamily: string
text.fontVariantId: string
text.fontSize: string
text.fontWeight: string
text.fontStyle: 'normal' | 'italic' | null

// Spacing
text.lineHeight: string
text.letterSpacing: string

// Alignment
text.align: 'left' | 'center' | 'right' | 'justify' | null
text.verticalAlign: 'top' | 'center' | 'bottom' | null
text.direction: 'ltr' | 'rtl' | null

// Decoration
text.textTransform: 'uppercase' | 'lowercase' | 'capitalize' | null
text.textDecoration: 'underline' | 'line-through' | null

// Methods
text.getRange(start, end): TextRange
text.applyTypography(typography: LibraryTypography)
```

## Board Properties

```typescript
board.type: 'board'
board.clipContent: boolean
board.showInViewMode: boolean
board.children: Shape[]

// Layout
board.flex?: FlexLayout
board.grid?: GridLayout
board.guides: Guide[]
board.rulerGuides: RulerGuide[]

// Methods
board.appendChild(child)
board.insertChild(index, child)
board.addFlexLayout(): FlexLayout
board.addGridLayout(): GridLayout
```

## FlexLayout Properties

```typescript
interface FlexLayout {
  dir: 'row' | 'column' | 'row-reverse' | 'column-reverse'
  wrap?: 'wrap' | 'nowrap'

  alignItems?: 'start' | 'center' | 'end' | 'stretch'
  alignContent?: 'start' | 'center' | 'end' | 'stretch' |
                 'space-between' | 'space-around' | 'space-evenly'
  justifyItems?: 'start' | 'center' | 'end' | 'stretch'
  justifyContent?: 'start' | 'center' | 'end' | 'stretch' |
                   'space-between' | 'space-around' | 'space-evenly'

  rowGap: number
  columnGap: number

  // Padding
  topPadding: number
  rightPadding: number
  bottomPadding: number
  leftPadding: number
  verticalPadding: number    // shorthand
  horizontalPadding: number  // shorthand

  // Sizing
  horizontalSizing: 'fill' | 'auto' | 'fit-content'
  verticalSizing: 'fill' | 'auto' | 'fit-content'

  // Methods
  appendChild(child)
  remove()
}
```

## GridLayout Properties

```typescript
interface GridLayout {
  dir: 'row' | 'column'
  rows: Track[]
  columns: Track[]
  rowGap: number
  columnGap: number

  // Alignment (same as FlexLayout)
  alignItems?: ...
  justifyItems?: ...
  justifyContent?: ...
  alignContent?: ...

  // Padding (same as FlexLayout)
  topPadding: number
  // ...etc

  // Methods
  addRow(type: TrackType, value?)
  addColumn(type: TrackType, value?)
  removeRow(index)
  removeColumn(index)
  setRow(index, type, value?)
  setColumn(index, type, value?)
  appendChild(child, row, column)
  remove()
}

type TrackType = 'flex' | 'fixed' | 'percent' | 'auto'
```

## LayoutChildProperties

```typescript
interface LayoutChildProperties {
  absolute: boolean              // If true, not controlled by layout
  zIndex: number
  horizontalSizing: 'fill' | 'auto' | 'fix'
  verticalSizing: 'fill' | 'auto' | 'fix'
  alignSelf: 'auto' | 'start' | 'center' | 'end' | 'stretch'

  // Margins
  topMargin: number
  rightMargin: number
  bottomMargin: number
  leftMargin: number
  horizontalMargin: number
  verticalMargin: number

  // Size constraints
  minWidth: number | null
  maxWidth: number | null
  minHeight: number | null
  maxHeight: number | null
}

// Access via:
shape.layoutChild?.horizontalSizing = 'fill';
```

## Library API

```typescript
// Access
penpot.library.local: Library
penpot.library.connected: Library[]
penpot.library.availableLibraries(): Promise<LibrarySummary[]>
penpot.library.connectLibrary(id): Promise<Library>

// Library interface
interface Library {
  id: string
  name: string
  colors: LibraryColor[]
  typographies: LibraryTypography[]
  components: LibraryComponent[]

  createColor(): LibraryColor
  createTypography(): LibraryTypography
  createComponent(shapes: Shape[]): LibraryComponent
}

// LibraryComponent
interface LibraryComponent {
  id: string
  name: string
  path: string
  instance(): Shape
  mainInstance(): Shape
  isVariant(): boolean
}

// LibraryColor
interface LibraryColor {
  id: string
  name: string
  path: string
  color?: string
  opacity?: number
  gradient?: Gradient
}

// LibraryTypography
interface LibraryTypography {
  id: string
  name: string
  path: string
  fontId: string
  fontFamily: string
  fontSize: string
  fontWeight: string
  // ...etc
}
```

## Penpot Global Object

```typescript
interface Penpot {
  // Current state
  root: Shape | null           // Current page root
  currentFile: File | null
  currentPage: Page | null
  selection: Shape[]
  currentUser: User
  activeUsers: ActiveUser[]
  theme: Theme
  viewport: Viewport

  // Context
  library: LibraryContext
  fonts: FontsContext
  history: HistoryContext
  localStorage: LocalStorage

  // Create shapes
  createRectangle(): Rectangle
  createBoard(): Board
  createEllipse(): Ellipse
  createPath(): Path
  createText(text: string): Text | null
  createBoolean(type, shapes): Boolean | null
  createShapeFromSvg(svg: string): Group | null

  // Grouping
  group(shapes: Shape[]): Group | null
  ungroup(group: Group, ...more: Group[]): void

  // Code generation
  generateStyle(shapes, options?): string
  generateMarkup(shapes, options?): string
  generateFontFaces(shapes): Promise<string>

  // Alignment
  alignHorizontal(shapes, direction: 'left' | 'center' | 'right')
  alignVertical(shapes, direction: 'top' | 'center' | 'bottom')
  distributeHorizontal(shapes)
  distributeVertical(shapes)

  // Colors
  shapesColors(shapes): (Color & ColorShapeInfo)[]
  replaceColor(shapes, oldColor, newColor)

  // Media
  uploadMediaUrl(name, url): Promise<ImageData>
  uploadMediaData(name, data, mimeType): Promise<ImageData>

  // Pages
  createPage(): Page
  openPage(page, newWindow?)
  openViewer()

  // Flatten
  flatten(shapes): Path[]

  // Events
  on(type, callback, props?): symbol
  off(listenerId: symbol)
}
```

## penpotUtils Helpers

```typescript
// Page utilities
penpotUtils.getPages(): { id, name }[]
penpotUtils.getPageById(id): Page | null
penpotUtils.getPageByName(name): Page | null

// Shape finding
penpotUtils.findShapeById(id): Shape | null
penpotUtils.findShape(predicate, root?): Shape | null
penpotUtils.findShapes(predicate, root?): Shape[]

// Structure
penpotUtils.shapeStructure(shape, maxDepth?): { id, name, type, children?, layout? }

// Positioning
penpotUtils.setParentXY(shape, parentX, parentY): void

// Containment
penpotUtils.isContainedIn(shape, container): boolean

// Analysis
penpotUtils.analyzeDescendants(root, evaluator, maxDepth?): Array<{ shape, result }>

// Layout (preserves child order)
penpotUtils.addFlexLayout(container, dir): FlexLayout
```

## Code Generation Options

```typescript
// generateStyle options
{
  type: 'css',
  withPrelude?: boolean,      // Include CSS reset
  includeChildren?: boolean   // Include child styles
}

// generateMarkup options
{
  type: 'html' | 'svg'
}
```

## Blend Modes

```typescript
type BlendMode =
  | 'normal'
  | 'darken' | 'multiply' | 'color-burn'
  | 'lighten' | 'screen' | 'color-dodge'
  | 'overlay' | 'soft-light' | 'hard-light'
  | 'difference' | 'exclusion'
  | 'hue' | 'saturation' | 'color' | 'luminosity'
```

## Events

```typescript
// Selection change
penpot.on('selectionchange', () => {
  console.log(penpot.selection);
});

// Page change
penpot.on('pagechange', () => {
  console.log(penpot.currentPage);
});

// File change
penpot.on('filechange', () => {
  console.log(penpot.currentFile);
});

// Theme change
penpot.on('themechange', (theme) => {
  console.log(theme); // 'light' | 'dark'
});

// Finish (plugin closing)
penpot.on('finish', () => {
  // Cleanup
});
```

## Storage Object

The `storage` object persists across tool calls:

```javascript
// Store selection
storage.selection = [...penpot.selection];

// Store any data
storage.myData = { foo: 'bar' };

// Store functions
storage.helpers = {
  createCard: (title) => { ... }
};

// Access later
const sel = storage.selection;
storage.helpers.createCard('Title');
```
