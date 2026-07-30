# Penpot Design Patterns

Common design patterns for building UI components in Penpot.

## Card Component

```javascript
async function createCard(title, description) {
  const card = penpot.createBoard();
  card.name = 'Card';
  card.resize(320, 0); // Width fixed, height auto
  card.fills = [{ fillColor: '#FFFFFF' }];
  card.borderRadius = 12;
  card.shadows = [{
    style: 'drop-shadow',
    color: { color: '#000000', opacity: 0.08 },
    offsetX: 0, offsetY: 4, blur: 12, spread: 0
  }];

  // Add flex layout
  const flex = penpotUtils.addFlexLayout(card, 'column');
  flex.rowGap = 12;
  flex.topPadding = 24;
  flex.rightPadding = 24;
  flex.bottomPadding = 24;
  flex.leftPadding = 24;

  // Title
  const titleText = penpot.createText(title);
  titleText.name = 'Title';
  titleText.fontSize = '20';
  titleText.fontWeight = '600';
  titleText.fills = [{ fillColor: '#1F2937' }];
  titleText.growType = 'auto-width';
  card.appendChild(titleText);

  // Description
  const descText = penpot.createText(description);
  descText.name = 'Description';
  descText.fontSize = '14';
  descText.fills = [{ fillColor: '#6B7280' }];
  descText.growType = 'auto-width';
  card.appendChild(descText);

  // Configure children sizing
  titleText.layoutChild.horizontalSizing = 'fill';
  descText.layoutChild.horizontalSizing = 'fill';

  return card;
}
```

## Button Component

```javascript
function createButton(label, variant = 'primary') {
  const colors = {
    primary: { bg: '#3B82F6', text: '#FFFFFF' },
    secondary: { bg: '#E5E7EB', text: '#1F2937' },
    outline: { bg: 'transparent', text: '#3B82F6', border: '#3B82F6' }
  };
  const style = colors[variant];

  const button = penpot.createBoard();
  button.name = `Button/${variant}`;
  button.resize(0, 40);
  button.borderRadius = 8;

  if (style.bg !== 'transparent') {
    button.fills = [{ fillColor: style.bg }];
  } else {
    button.fills = [];
  }

  if (style.border) {
    button.strokes = [{
      strokeColor: style.border,
      strokeWidth: 1,
      strokeAlignment: 'center'
    }];
  }

  // Flex layout for centering
  const flex = penpotUtils.addFlexLayout(button, 'row');
  flex.alignItems = 'center';
  flex.justifyContent = 'center';
  flex.leftPadding = 16;
  flex.rightPadding = 16;

  // Label
  const text = penpot.createText(label);
  text.fontSize = '14';
  text.fontWeight = '500';
  text.fills = [{ fillColor: style.text }];
  text.growType = 'auto-width';
  button.appendChild(text);

  return button;
}
```

## Navigation Bar

```javascript
function createNavBar(menuItems) {
  const nav = penpot.createBoard();
  nav.name = 'Navigation';
  nav.resize(1200, 64);
  nav.fills = [{ fillColor: '#FFFFFF' }];
  nav.strokes = [{
    strokeColor: '#E5E7EB',
    strokeWidth: 1,
    strokeAlignment: 'inner'
  }];

  const flex = penpotUtils.addFlexLayout(nav, 'row');
  flex.alignItems = 'center';
  flex.justifyContent = 'space-between';
  flex.leftPadding = 32;
  flex.rightPadding = 32;

  // Logo
  const logo = penpot.createText('LOGO');
  logo.fontSize = '24';
  logo.fontWeight = '700';
  logo.fills = [{ fillColor: '#1F2937' }];
  logo.growType = 'auto-width';
  nav.appendChild(logo);

  // Menu container
  const menu = penpot.createBoard();
  menu.name = 'Menu';
  menu.resize(0, 40);
  menu.fills = [];
  const menuFlex = penpotUtils.addFlexLayout(menu, 'row');
  menuFlex.columnGap = 32;
  menuFlex.alignItems = 'center';

  for (const item of menuItems) {
    const menuItem = penpot.createText(item);
    menuItem.fontSize = '14';
    menuItem.fontWeight = '500';
    menuItem.fills = [{ fillColor: '#4B5563' }];
    menuItem.growType = 'auto-width';
    menu.appendChild(menuItem);
  }

  nav.appendChild(menu);

  // CTA Button
  const cta = createButton('Get Started', 'primary');
  nav.appendChild(cta);

  return nav;
}
```

## Form Input Field

```javascript
function createInput(label, placeholder) {
  const field = penpot.createBoard();
  field.name = `Input/${label}`;
  field.resize(280, 0);
  field.fills = [];

  const flex = penpotUtils.addFlexLayout(field, 'column');
  flex.rowGap = 6;

  // Label
  const labelText = penpot.createText(label);
  labelText.fontSize = '14';
  labelText.fontWeight = '500';
  labelText.fills = [{ fillColor: '#374151' }];
  labelText.growType = 'auto-width';
  field.appendChild(labelText);

  // Input box
  const input = penpot.createBoard();
  input.name = 'Input Box';
  input.resize(280, 40);
  input.fills = [{ fillColor: '#FFFFFF' }];
  input.borderRadius = 6;
  input.strokes = [{
    strokeColor: '#D1D5DB',
    strokeWidth: 1,
    strokeAlignment: 'inner'
  }];

  const inputFlex = penpotUtils.addFlexLayout(input, 'row');
  inputFlex.alignItems = 'center';
  inputFlex.leftPadding = 12;
  inputFlex.rightPadding = 12;

  const placeholderText = penpot.createText(placeholder);
  placeholderText.fontSize = '14';
  placeholderText.fills = [{ fillColor: '#9CA3AF' }];
  placeholderText.growType = 'auto-width';
  input.appendChild(placeholderText);

  field.appendChild(input);

  // Configure sizing
  labelText.layoutChild.horizontalSizing = 'fill';
  input.layoutChild.horizontalSizing = 'fill';

  return field;
}
```

## Grid Layout

```javascript
function createGrid(columns, gap) {
  const grid = penpot.createBoard();
  grid.name = 'Grid';
  grid.resize(800, 0);
  grid.fills = [];

  // Add grid layout
  const layout = grid.addGridLayout();
  layout.columnGap = gap;
  layout.rowGap = gap;

  // Add columns
  for (let i = 0; i < columns; i++) {
    layout.addColumn('flex', 1); // Equal width columns
  }

  return { grid, layout };
}

// Usage:
const { grid, layout } = createGrid(3, 24);
const item1 = penpot.createRectangle();
item1.resize(100, 100);
item1.fills = [{ fillColor: '#F3F4F6' }];
layout.appendChild(item1, 1, 1); // row 1, col 1

const item2 = penpot.createRectangle();
item2.resize(100, 100);
item2.fills = [{ fillColor: '#F3F4F6' }];
layout.appendChild(item2, 1, 2); // row 1, col 2
```

## Modal Dialog

```javascript
function createModal(title, content) {
  // Overlay
  const overlay = penpot.createBoard();
  overlay.name = 'Modal Overlay';
  overlay.resize(1440, 900);
  overlay.fills = [{ fillColor: '#000000', fillOpacity: 0.5 }];

  // Modal container
  const modal = penpot.createBoard();
  modal.name = 'Modal';
  modal.resize(480, 0);
  modal.fills = [{ fillColor: '#FFFFFF' }];
  modal.borderRadius = 16;
  modal.shadows = [{
    style: 'drop-shadow',
    color: { color: '#000000', opacity: 0.25 },
    offsetX: 0, offsetY: 20, blur: 40, spread: 0
  }];

  const flex = penpotUtils.addFlexLayout(modal, 'column');
  flex.rowGap = 16;
  flex.topPadding = 24;
  flex.rightPadding = 24;
  flex.bottomPadding = 24;
  flex.leftPadding = 24;

  // Header
  const header = penpot.createBoard();
  header.name = 'Header';
  header.resize(0, 32);
  header.fills = [];
  const headerFlex = penpotUtils.addFlexLayout(header, 'row');
  headerFlex.alignItems = 'center';
  headerFlex.justifyContent = 'space-between';

  const titleText = penpot.createText(title);
  titleText.fontSize = '18';
  titleText.fontWeight = '600';
  titleText.fills = [{ fillColor: '#1F2937' }];
  titleText.growType = 'auto-width';
  header.appendChild(titleText);

  // Close button (X)
  const closeBtn = penpot.createText('✕');
  closeBtn.fontSize = '20';
  closeBtn.fills = [{ fillColor: '#9CA3AF' }];
  closeBtn.growType = 'auto-width';
  header.appendChild(closeBtn);

  modal.appendChild(header);

  // Content
  const contentText = penpot.createText(content);
  contentText.fontSize = '14';
  contentText.fills = [{ fillColor: '#4B5563' }];
  contentText.growType = 'auto-width';
  modal.appendChild(contentText);

  // Actions
  const actions = penpot.createBoard();
  actions.name = 'Actions';
  actions.resize(0, 40);
  actions.fills = [];
  const actionsFlex = penpotUtils.addFlexLayout(actions, 'row');
  actionsFlex.columnGap = 12;
  actionsFlex.justifyContent = 'end';

  const cancelBtn = createButton('Cancel', 'secondary');
  const confirmBtn = createButton('Confirm', 'primary');
  actions.appendChild(cancelBtn);
  actions.appendChild(confirmBtn);

  modal.appendChild(actions);

  // Configure sizing
  header.layoutChild.horizontalSizing = 'fill';
  contentText.layoutChild.horizontalSizing = 'fill';
  actions.layoutChild.horizontalSizing = 'fill';

  // Center modal in overlay
  overlay.insertChild(overlay.children.length, modal);
  // Position modal in center (after creation)
  await new Promise(r => setTimeout(r, 100)); // Wait for auto-sizing
  modal.x = (overlay.width - modal.width) / 2;
  modal.y = (overlay.height - modal.height) / 2;

  return overlay;
}
```

## Avatar Component

```javascript
function createAvatar(size = 40, initials = 'AB') {
  const avatar = penpot.createBoard();
  avatar.name = 'Avatar';
  avatar.resize(size, size);
  avatar.borderRadius = size / 2; // Circle
  avatar.fills = [{ fillColor: '#E0E7FF' }];

  const flex = penpotUtils.addFlexLayout(avatar, 'row');
  flex.alignItems = 'center';
  flex.justifyContent = 'center';

  const text = penpot.createText(initials);
  text.fontSize = String(Math.round(size * 0.4));
  text.fontWeight = '600';
  text.fills = [{ fillColor: '#4338CA' }];
  text.growType = 'auto-width';
  avatar.appendChild(text);

  return avatar;
}
```

## Badge/Tag Component

```javascript
function createBadge(label, color = 'blue') {
  const colors = {
    blue: { bg: '#DBEAFE', text: '#1D4ED8' },
    green: { bg: '#D1FAE5', text: '#047857' },
    red: { bg: '#FEE2E2', text: '#DC2626' },
    yellow: { bg: '#FEF3C7', text: '#D97706' },
    gray: { bg: '#F3F4F6', text: '#4B5563' }
  };
  const style = colors[color] || colors.gray;

  const badge = penpot.createBoard();
  badge.name = `Badge/${label}`;
  badge.resize(0, 24);
  badge.fills = [{ fillColor: style.bg }];
  badge.borderRadius = 12;

  const flex = penpotUtils.addFlexLayout(badge, 'row');
  flex.alignItems = 'center';
  flex.leftPadding = 10;
  flex.rightPadding = 10;

  const text = penpot.createText(label);
  text.fontSize = '12';
  text.fontWeight = '500';
  text.fills = [{ fillColor: style.text }];
  text.growType = 'auto-width';
  badge.appendChild(text);

  return badge;
}
```

## Divider/Separator

```javascript
function createDivider(width = 300, vertical = false) {
  const divider = penpot.createRectangle();
  divider.name = 'Divider';

  if (vertical) {
    divider.resize(1, 24);
  } else {
    divider.resize(width, 1);
  }

  divider.fills = [{ fillColor: '#E5E7EB' }];
  return divider;
}
```

## Icon Placeholder

```javascript
function createIconPlaceholder(size = 24) {
  const icon = penpot.createBoard();
  icon.name = 'Icon';
  icon.resize(size, size);
  icon.fills = [{ fillColor: '#9CA3AF' }];
  icon.borderRadius = 4;
  return icon;
}
```

## List Item

```javascript
function createListItem(title, subtitle) {
  const item = penpot.createBoard();
  item.name = 'List Item';
  item.resize(320, 0);
  item.fills = [];

  const flex = penpotUtils.addFlexLayout(item, 'row');
  flex.columnGap = 12;
  flex.alignItems = 'center';
  flex.topPadding = 12;
  flex.bottomPadding = 12;

  // Avatar
  const avatar = createAvatar(40, title.charAt(0));
  item.appendChild(avatar);

  // Content
  const content = penpot.createBoard();
  content.name = 'Content';
  content.resize(0, 0);
  content.fills = [];
  const contentFlex = penpotUtils.addFlexLayout(content, 'column');
  contentFlex.rowGap = 2;

  const titleText = penpot.createText(title);
  titleText.fontSize = '14';
  titleText.fontWeight = '500';
  titleText.fills = [{ fillColor: '#1F2937' }];
  titleText.growType = 'auto-width';
  content.appendChild(titleText);

  const subtitleText = penpot.createText(subtitle);
  subtitleText.fontSize = '12';
  subtitleText.fills = [{ fillColor: '#6B7280' }];
  subtitleText.growType = 'auto-width';
  content.appendChild(subtitleText);

  item.appendChild(content);

  // Configure sizing
  content.layoutChild.horizontalSizing = 'fill';

  return item;
}
```
