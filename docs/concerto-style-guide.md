# Concerto - Admin Panel UI/UX Design Specification & Style Guide

## 1. Overview & Design Principles

### 1.1. Purpose & Vision

This document outlines the definitive UI/UX design specification for the Concerto admin panel. As the primary interface for content managers, moderators, and administrators, the panel is designed to be a powerful, intuitive, and efficient tool for managing a digital signage network.

This specification harmonizes the design legacy of Concerto V1 (2008) and V2 (2012), evolving their foundational principles to meet the expectations of a modern, enterprise-grade web application in 2025.

### 1.2. Target Users

*   **Content Creators**: Users focused on efficient content submission and management.
*   **Moderators**: Users responsible for reviewing and approving content with clarity and speed.
*   **Administrators**: Power users who manage the entire ecosystem, including screens, feeds, users, and system-level settings.

### 1.3. Design Philosophy

The design is guided by three core principles that build upon its heritage:

*   **Streamlined & Intuitive**: We prioritize clarity and ease of use. Workflows are simplified, and the interface provides clear guidance, reducing cognitive load and enabling users to complete tasks with confidence and speed.
*   **Powerful yet Approachable**: The design exposes Concerto's robust functionality without overwhelming the user. A clean aesthetic, logical information architecture, and progressive disclosure make powerful features accessible to users of all skill levels.
*   **Enterprise-Grade Simplicity**: Embrace a modern, clean aesthetic that is professional and trustworthy. The design system is built on consistency, accessibility, and responsiveness, ensuring a reliable and seamless experience across all devices.

### 1.4. Evolution from V1 & V2

This specification is a thoughtful evolution, not a revolution. It respects the visual DNA of its predecessors—particularly the established blue-centric color palette—while systematically updating every element for a 2025 audience. We have replaced dated gradients, textures, and heavy shadows with clean lines, functional whitespace, and a consistent, scalable design system. The fixed sidebar of V1 and the responsive top-bar of V2 have been synthesized into a modern, collapsible sidebar navigation, providing the best of both worlds: persistent navigation and responsive adaptability.

---

## 2. Branding & Visual Identity

### 2.1. Color Palette

The palette is an evolution of the classic Concerto blue. It is designed to be vibrant, accessible, and professional, meeting WCAG 2.1 AA contrast standards for all text and interactive elements.

#### **Primary Colors**

*   **Brand Blue**: The core interactive color, evolved from V1/V2's `#006699`. It's slightly more vibrant for a modern feel.
    *   `#007BFF`
    *   `rgb(0, 123, 255)`
    *   `hsl(211, 100%, 50%)`
*   **Brand Blue (Dark)**: For hover states and darker accents.
    *   `#0056B3`
*   **Brand Blue (Light)**: For lighter backgrounds and subtle highlights.
    *   `#CCE5FF`

#### **Neutral Colors**

A versatile grayscale palette for text, backgrounds, and borders.

*   **Neutral 900 (Text)**: `#171A1C`
*   **Neutral 700 (Sub-text)**: `#4A5459`
*   **Neutral 500 (Borders)**: `#A0AEC0`
*   **Neutral 300 (Dividers)**: `#CBD5E0`
*   **Neutral 200 (UI Backgrounds)**: `#E2E8F0`
*   **Neutral 100 (App Background)**: `#F8F9FA`
*   **White**: `#FFFFFF`

#### **Semantic Colors**

For communicating status and feedback clearly.

*   **Success**: `#28A745` (Used for approvals, online status, success messages)
*   **Warning**: `#FFC107` (Used for pending status, non-critical alerts)
*   **Error**: `#DC3545` (Used for denials, offline status, error messages)
*   **Info**: `#17A2B8` (Used for informational alerts and highlights)

### 2.2. Typography

The typography is clean, legible, and modern, designed for clarity in a data-rich UI. We use 'Inter' for its excellent readability at all sizes.

*   **Font Family**: 'Inter', sans-serif

#### **Typographic Scale**

A responsive and harmonious scale based on a `1rem = 16px` root font size.

| Element | Font Size | Font Weight | Line Height | Letter Spacing |
| :--- | :--- | :--- | :--- | :--- |
| **H1** | `2rem` (32px) | 700 (Bold) | `2.5rem` | `-0.02em` |
| **H2** | `1.5rem` (24px) | 700 (Bold) | `2rem` | `-0.015em` |
| **H3** | `1.25rem` (20px) | 600 (SemiBold) | `1.75rem` | `-0.01em` |
| **H4** | `1rem` (16px) | 600 (SemiBold) | `1.5rem` | `normal` |
| **Body** | `0.875rem` (14px) | 400 (Regular) | `1.5rem` | `normal` |
| **Label** | `0.75rem` (12px) | 500 (Medium) | `1rem` | `0.05em` (UPPERCASE) |
| **Caption**| `0.75rem` (12px) | 400 (Regular) | `1rem` | `normal` |

### 2.3. Logo Usage

The Concerto logo should be subtly refined for clarity and scalability.

*   **Placement**: The primary logo is placed at the top of the main navigation sidebar.
*   **Clear Space**: A minimum of 25% of the logo's width should be maintained as clear space around it.
*   **Backgrounds**: Use the full-color logo on light backgrounds (`Neutral 100`, `White`). On dark or colored backgrounds, a monochromatic white version should be used.
*   **Favicon**: A simplified version of the logo mark should be used for the browser favicon.

---

## 3. Application Shell & Global Elements

### 3.1. Header

The header is minimal, fixed, and serves as a utility bar.

*   **Height**: `64px`
*   **Background**: `White`
*   **Border**: `1px solid Neutral 300` at the bottom.
*   **Content**: Contains global search, a "New Content" quick-action button, notifications, and the user profile dropdown.
*   **Responsiveness**: On mobile, the search bar collapses into an icon, and actions may be consolidated into a single menu.

### 3.2. Navigation (Primary)

A collapsible left sidebar provides persistent and intuitive navigation.

*   **Layout**: Fixed on the left side of the viewport.
*   **Width**: `240px` (expanded), `72px` (collapsed).
*   **Styling**: `Neutral 900` background for a strong visual anchor.
*   **Structure**:
    1.  **Logo**: At the top.
    2.  **Navigation Items**: Grouped by context (e.g., Content, Network, Administration).
    3.  **Collapse Toggle**: At the bottom.
*   **Navigation Items**:
    *   **Iconography**: Each item has a clear icon (20x20px).
    *   **States**:
        *   **Default**: `Neutral 300` text and icon color.
        *   **Hover**: `White` text and icon color, with a subtle `Neutral 700` background.
        *   **Active**: `Brand Blue` text and icon color, with a `Brand Blue (Light)` background and a `Brand Blue` left border accent (4px).
        *   **Disabled**: `Neutral 500` text and icon, non-interactive.

### 3.3. Footer

The footer is clean, unobtrusive, and contains essential links.

*   **Height**: Auto-sizing, with `24px` padding.
*   **Styling**: `Neutral 100` background, `Neutral 700` text color.
*   **Content**: Copyright notice, version number, and links to support or legal documentation.

---

## 4. UI Components Library

All components are built on the spacing system, color palette, and typography. They are designed to be accessible, responsive, and consistent.

### 4.1. Buttons

| State | Background | Text Color | Border | Box Shadow |
| :--- | :--- | :--- | :--- | :--- |
| **Primary (Default)** | `Brand Blue` | `White` | `1px solid Brand Blue` | `none` |
| **Primary (Hover)** | `Brand Blue (Dark)` | `White` | `1px solid Brand Blue (Dark)` | `0 2px 8px rgba(0,0,0,0.1)` |
| **Secondary (Default)**| `Neutral 200` | `Neutral 900` | `1px solid Neutral 300` | `none` |
| **Secondary (Hover)** | `Neutral 300` | `Neutral 900` | `1px solid Neutral 500` | `0 2px 8px rgba(0,0,0,0.1)` |
| **Danger (Default)** | `Error` | `White` | `1px solid Error` | `none` |
| **Danger (Hover)** | `darken(Error, 10%)` | `White` | `1px solid darken(Error, 10%)` | `0 2px 8px rgba(0,0,0,0.1)` |
| **Focus (All)** | *Same as Hover* | *Same as Hover* | `1px solid Brand Blue` | `0 0 0 3px Brand Blue (Light)` |
| **Disabled (All)** | `Neutral 200` | `Neutral 500` | `1px solid Neutral 300` | `none` (cursor: not-allowed) |

*   **Sizing**: Small (`32px` height), Medium (`40px` height), Large (`48px` height).
*   **Padding**: Consistent vertical padding with horizontal padding adjusted for size.
*   **Border Radius**: `8px`.

### 4.2. Input Fields

*   **Default State**:
    *   **Background**: `White`.
    *   **Border**: `1px solid Neutral 300`.
    *   **Text Color**: `Neutral 900`.
    *   **Placeholder Text**: `Neutral 500`.
*   **Focus State**:
    *   **Border**: `1px solid Brand Blue`.
    *   **Box Shadow**: `0 0 0 3px Brand Blue (Light)`.
*   **Error State**:
    *   **Border**: `1px solid Error`.
    *   **Box Shadow**: `0 0 0 3px lighten(Error, 25%)`.
*   **Disabled State**:
    *   **Background**: `Neutral 100`.
    *   **Border**: `1px solid Neutral 300`.
    *   **Text Color**: `Neutral 500`.
*   **Styling**: `8px` border-radius, `12px` horizontal padding.

### 4.3. Tables

*   **Structure**: Clean, with ample whitespace.
*   **Header**: `Neutral 100` background, `Neutral 700` text color, `font-weight: 600`.
*   **Rows**: `White` background.
*   **Row Hover**: `lighten(Neutral 100, 2%)` background.
*   **Borders**: `1px solid Neutral 200` between rows. No vertical borders.
*   **Padding**: `16px` in all cells.

### 4.4. Modals

*   **Overlay**: `rgba(23, 26, 28, 0.5)` with a blur filter (`backdrop-filter: blur(4px)`).
*   **Container**: `White` background, `24px` border-radius, subtle `box-shadow`.
*   **Header**: `H3` title, close button (`X` icon).
*   **Content**: `24px` padding.
*   **Footer**: `16px` padding, contains action buttons, right-aligned.
*   **Animation**: Smooth fade-in and scale-up transition.

### 4.5. Alerts

*   **Styling**: `16px` padding, `8px` border-radius.
*   **Structure**: Icon on the left, title and message on the right.
*   **Color Variants**:
    *   **Info**: `Brand Blue (Light)` background, `Brand Blue` text.
    *   **Success**: `lighten(Success, 35%)` background, `darken(Success, 20%)` text.
    *   **Warning**: `lighten(Warning, 35%)` background, `darken(Warning, 40%)` text.
    *   **Error**: `lighten(Error, 35%)` background, `darken(Error, 10%)` text.

---

## 5. Layout & Grid System

### 5.1. Spacing System

A consistent 4px-based scale is used for all spacing (padding, margin) to ensure visual harmony and align with Tailwind CSS defaults.

*   `1`: `4px` (0.25rem)
*   `2`: `8px` (0.5rem)
*   `3`: `12px` (0.75rem)
*   `4`: `16px` (1rem)
*   `5`: `20px` (1.25rem)
*   `6`: `24px` (1.5rem)
*   `8`: `32px` (2rem)
*   `10`: `40px` (2.5rem)
*   `12`: `48px` (3rem)

**Note**: This spacing scale follows Tailwind CSS conventions where each unit represents 0.25rem (4px). This provides fine-grained control while maintaining consistency with modern design systems.

### 5.2. Responsive Breakpoints

*   **Mobile**: `< 768px`
*   **Tablet**: `768px - 1024px`
*   **Desktop**: `> 1024px`

### 5.3. Grid Structure

A standard 12-column flexible grid system is used for laying out content within the main content area. Gutters are based on the spacing system (`space-3` or `24px`).

---

## 6. Imagery & Iconography

### 6.1. Iconography

This specification moves away from raster icons and custom icon fonts to a modern, consistent SVG icon library.

*   **Library**: **HeroIcons** (or a similar high-quality, open-source library).
*   **Style**: Line icons, emphasizing clarity and simplicity.
*   **Properties**:
    *   **Size**: `20px` (standard), `16px` (small), `24px` (large).
    *   **Stroke Width**: `1.5px` for a clean, modern look.
    *   **Color**: Icons inherit color from their parent text element (`color: currentColor`) for easy styling.

### 6.2. Imagery

*   **User-Generated Content**: Previews and thumbnails should be displayed cleanly within `16:9` or `4:3` aspect-ratio containers to maintain layout consistency.
*   **Illustrations**: Empty states and onboarding flows should use simple, friendly line-art illustrations that match the `Brand Blue` and `Neutral` color palette.
