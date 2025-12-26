# Teacher App Design System

## 🎨 Color Palette

### Primary Colors
```
Indigo:  #6366F1  ███████  Main brand color
Purple:  #8B5CF6  ███████  Secondary accent
Blue:    #3B82F6  ███████  Tertiary accent
```

### Functional Colors
```
Emerald: #10B981  ███████  Success/Attendance
Amber:   #F59E0B  ███████  Warning/Assignments
Red:     #EF4444  ███████  Error/Danger
```

### Text Colors
```
Primary:   #1E293B  ███████  Main text
Secondary: #64748B  ███████  Subtitles
Tertiary:  #94A3B8  ███████  Hints/Disabled
```

### Background Colors
```
Primary:   #F8FAFC  ███████  Main background
Secondary: #FFFFFF  ███████  Cards/Surfaces
Tertiary:  #F1F5F9  ███████  Subtle backgrounds
```

### Border Colors
```
Light:  #E2E8F0  ███████  Default borders
Medium: #CBD5E1  ███████  Emphasized borders
```

## 📐 Spacing Scale

```
4px   - Micro spacing (between icon and text)
8px   - Small spacing (between related elements)
12px  - Medium spacing (within cards)
16px  - Default spacing (between sections)
20px  - Large spacing (page padding)
24px  - XL spacing (major sections)
32px  - XXL spacing (hero sections)
```

## 🔤 Typography

### Font Family
- **Primary**: Poppins (Google Fonts)

### Font Sizes
```
36px - Hero titles (Login screen)
22px - Page headers (Welcome card)
20px - Section headers (Modal titles)
16px - Body text, buttons
14px - Secondary text
13px - Small text (badges, hints)
12px - Micro text (timestamps)
```

### Font Weights
```
w400 - Regular (body text)
w500 - Medium (labels)
w600 - Semi-bold (card titles)
w700 - Bold (headers, buttons)
w800 - Extra-bold (hero text)
```

## 📦 Component Styles

### Cards
```dart
decoration: BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: Color(0xFFE2E8F0), width: 1),
  boxShadow: [
    BoxShadow(
      color: Color(0xFF6366F1).withValues(alpha: 0.06),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ],
)
```

### Buttons (Primary)
```dart
style: ElevatedButton.styleFrom(
  backgroundColor: Color(0xFF6366F1),
  foregroundColor: Colors.white,
  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  elevation: 0,
)
```

### Input Fields
```dart
decoration: InputDecoration(
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: Color(0xFFE2E8F0)),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: Color(0xFF6366F1), width: 2),
  ),
  filled: true,
  fillColor: Colors.white,
  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
)
```

### Gradient Backgrounds
```dart
// Purple to Indigo (Primary)
gradient: LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
)

// Amber to Red (Assignments)
gradient: LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
)
```

### Icon Containers
```dart
Container(
  padding: EdgeInsets.all(12),
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        color.withValues(alpha: 0.15),
        color.withValues(alpha: 0.05),
      ],
    ),
    borderRadius: BorderRadius.circular(12),
  ),
  child: Icon(icon, size: 24, color: color),
)
```

## 🎯 Usage Guidelines

### When to Use Each Color

**Indigo (#6366F1)**
- Primary buttons
- Classes/School related items
- Main brand elements
- Active states

**Emerald (#10B981)**
- Attendance features
- Success messages
- Positive actions
- Confirmation buttons

**Amber (#F59E0B)**
- Assignments
- Warnings
- Important notifications
- Pending states

**Purple (#8B5CF6)**
- Messages
- Secondary accents
- Decorative elements
- Gradients

### Accessibility

- All text colors meet WCAG AA standards
- Minimum touch target: 44x44 pixels
- Sufficient contrast ratios maintained
- Focus states clearly visible

### Best Practices

1. **Consistency**: Use the same spacing values throughout
2. **Hierarchy**: Larger, bolder text for important content
3. **Contrast**: Ensure text is readable on all backgrounds
4. **Feedback**: Provide visual feedback for all interactions
5. **Simplicity**: Don't overuse gradients or shadows

## 📱 Responsive Breakpoints

```
Mobile:  < 600px  (Primary target)
Tablet:  600-900px
Desktop: > 900px
```

## 🎨 Empty States

Always include:
- Large icon (64px) with colored background
- Primary message (16px, w600)
- Secondary hint (14px, lighter color)
- Call-to-action when applicable

Example:
```dart
Container(
  padding: EdgeInsets.all(24),
  decoration: BoxDecoration(
    color: Color(0xFF6366F1).withValues(alpha: 0.1),
    shape: BoxShape.circle,
  ),
  child: Icon(Icons.icon_name, size: 64, color: Color(0xFF6366F1)),
)
```

---

**Version**: 1.0  
**Last Updated**: December 2024  
**Maintained by**: Development Team
