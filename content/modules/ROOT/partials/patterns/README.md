# Patterns

Interactive UI components for AsciiDoc pages. Each pattern is a self-contained `.adoc` file with CSS and JS inside a passthrough block. Pages include only the patterns they need.

## Including patterns

```asciidoc
include::partial$patterns/copypaste.adoc[]
include::partial$patterns/verification.adoc[]
```

Or include all patterns at once:

```asciidoc
include::partial$patterns/all.adoc[]
```

> Every page must also include `style.adoc` (global CSS, attributes, overlays) before any pattern includes.

---

## Copypaste

Copy-to-clipboard blocks with an optional docserver fetch for dynamic values.

**File:** `copypaste.adoc`

### Static block

Displays fixed content with a copy button.

```asciidoc
[.copypaste]
****
oc get pods -n demo
****
```

### Multi-line static block

Paragraphs separated by blank lines are joined with `\n\n` in the textarea.

```asciidoc
[.copypaste]
****
# Kafka configuration
camel.component.kafka.brokers=localhost:9092
camel.component.kafka.group-id=my-group
****
```

### Dynamic block (docserver fetch)

Fetches data from the docserver and replaces `REPLACE` tokens with the response. Each `REPLACE` is replaced in order with comma-separated values from the server.

```asciidoc
[.copypaste]
****
[.path]
/credentials/im

REPLACE
****
```

### Dynamic block with custom defaults

If the server is unavailable, `[.default]` values are shown instead of the built-in `<unavailable>`.

```asciidoc
[.copypaste]
****
[.path]
/credentials/im

[.default]
fallback-password

REPLACE
****
```

### Dynamic block with multiple tokens

Multiple `REPLACE` tokens are substituted in order. Defaults are comma-separated.

```asciidoc
[.copypaste]
****
[.path]
/configuration/matrix

[.default]
fallback-token, fallback-room

# Matrix credentials
matrix.token=REPLACE
matrix.room=REPLACE
****
```

### Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `[.path]` | No | URL path appended to `{url-docserver}`. Makes the block dynamic. |
| `[.default]` | No | Comma-separated fallback values for `REPLACE` tokens when the server is unavailable. If omitted, `<unavailable>` is used. |
| Content paragraphs | Yes | The template text. `REPLACE` tokens are substituted with fetched or default values. |

### Default value cascade

1. All `REPLACE` tokens are immediately replaced with `<unavailable>` (built-in)
2. If `[.default]` is provided, its values override the built-in
3. On successful fetch, server data overwrites everything
4. On fetch failure, whatever is currently displayed stays

### Context compatibility

Copypaste blocks work inside:
- Admonitions (use compound syntax: `[NOTE]` with `====` delimiters)
- Example blocks
- Open blocks
- Ordered and unordered lists (with `+` continuation)
- Collapsible blocks (`[%collapsible]`)
- Tables (use `a|` cell type)
- Nested structures (e.g. admonition inside example block)
- Multiple blocks in sequence

---

## Verification

"Check your work" components that gate the Next page link until the user selects "Yes" on all verification blocks.

**File:** `verification.adoc`

### Basic usage

```asciidoc
[.verification]
****
Did you see the message in _Matrix_ showing up in _Rocket.Chat_?

[.success]
Finish this chapter by completing the next task.

[.fail]
Review your steps in the exercise and try again.
****
```

### Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| First paragraph | Yes | The question shown with Yes/No radio buttons. |
| `[.success]` | No | Message shown when user selects Yes. Default: "Great, you may continue to the next section." |
| `[.fail]` | No | Message shown when user selects No. Default: "Review your steps and try again." |

### Behavior

- Renders as a green-header card with Yes/No radio buttons
- Selecting "Yes" shows the success message; "No" shows the fail message
- Antora's Next page link is disabled until **all** verification blocks on the page have "Yes" selected
- Multiple verification blocks on a single page are supported

### Used in

`intro/intro.3`, `m1/m1.2`, `m1/m1.3`, `m2/m2.1`, `m2/m2.4`

---

## Tiles

Grid-based module cards for index/landing pages.

**File:** `tiles.adoc`

### Usage

```asciidoc
[.tile]
****
xref:m1/m1.0.adoc[Lab 1 -- Be the Camel developer]

Description text for the tile card.

[.meta]
29 min | 5 tasks
****
```

### Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| First paragraph (with `xref:`) | Yes | The link href becomes the card's click target; the link text becomes the card header. |
| Middle paragraphs | No | Description text shown in the card body. |
| `[.meta]` | No | Footer with time and task count, separated by `\|`. |

### Behavior

- All `.tile` blocks on a page are collected into a responsive CSS grid
- Cards have a green header bar (`#3e8635`), hover shadow, and responsive layout
- Grid uses `repeat(auto-fill, minmax(280px, 1fr))`

### Used in

`index.adoc`

---

## Mermaid Diagrams

Client-side rendering of Mermaid diagrams (flowcharts, sequence diagrams, etc.).

**File:** `mermaid.adoc`

### Usage

Use a listing block with the `[.mermaid]` role:

```asciidoc
[.mermaid]
----
sequenceDiagram
    actor User
    participant API
    participant DB@{ "type": "database", "alias": "Database" }
    User->>API: Request
    API->>DB: Query
    DB-->>API: Result
    API-->>User: Response
----
```

### Flowchart example

```asciidoc
[.mermaid]
----
flowchart LR
    A[Service A] --> B[Service B]
    B --> C[(Database)]
----
```

### Behavior

- Mermaid JS is loaded from CDN only when `[.mermaid]` blocks are present on the page
- Raw listing blocks are hidden by CSS until JS transforms them
- Configuration is defined in `mermaid.adoc` (e.g. `mirrorActors: false` hides duplicated actor boxes at the bottom of sequence diagrams)
- Supports all Mermaid diagram types: sequence, flowchart, class, state, etc.
- Participant shapes in sequence diagrams use `@{ "type": "database" }` JSON syntax

### Participant shape types (sequence diagrams)

| Type | Syntax | Shape |
|------|--------|-------|
| Default | `participant Name` | Rectangle |
| Actor | `actor Name` | Stick figure |
| Database | `participant DB@{ "type": "database", "alias": "Label" }` | Cylinder |
| Collections | `participant S3@{ "type": "collections", "alias": "Label" }` | Stacked boxes |
| Queue | `participant Q@{ "type": "queue", "alias": "Label" }` | Queue |
| Boundary | `participant B@{ "type": "boundary", "alias": "Label" }` | Boundary |
| Entity | `participant E@{ "type": "entity", "alias": "Label" }` | Entity |
| Control | `participant C@{ "type": "control", "alias": "Label" }` | Control |

---

## Mermaid Hints

Interactive hover popovers on Mermaid diagram nodes. Place a `[.mermaid-hints-*]` sidebar block after a `[.mermaid]` diagram — the pattern automatically finds the preceding diagram and attaches hover handlers to the specified nodes.

**File:** `mermaid-hints.adoc`

The pattern name is **namespaced**: `mermaid-hints-simple` is the current variant (title + plain text). Future variants (e.g. `mermaid-hints-rich` with formatted HTML content) can be added as separate patterns sharing the `mermaid-hints-` prefix.

### Basic usage

Each line defines a hint: `NodeId | Title | Description`. Lines are separated by ` +` (AsciiDoc line continuation). The `NodeId` must match a node or subgraph ID in the Mermaid diagram.

```asciidoc
[.mermaid]
----
flowchart LR
    subgraph S1 ["Site(1)"]
        Connector((Connector))
    end
    subgraph S2 ["Site(2)"]
        Listener((Listener))
        Grant[AccessGrant]
    end
    S2 -.-|"🔒 link"| S1
----

[.mermaid-hints-simple]
****
S2 | Site | The foundation of the Skupper network. Each namespace runs one. +
S1 | Site | Same as above, on the other side. +
Grant | AccessGrant | An invitation for a remote Site to connect. +
Listener | Listener | Exposes a remote service locally in your namespace. +
Connector | Connector | Connects a local service to the Skupper network.
****

TIP: Hover over each component in the diagram to learn what it does.
```

### Multi-line descriptions

Lines without the `NodeId | Title | Description` pattern are appended to the previous hint's description, shown on a new line in the popover:

```asciidoc
[.mermaid-hints-simple]
****
Grant | AccessGrant | Created on the receiving side. +
It generates credentials that allow a remote Site to connect. +
Think of it as an invitation to join the network. +
Token | AccessToken | Created on the connecting side.
****
```

### Blank lines for grouping

Blank lines between hints are purely cosmetic — they create visual grouping in the AsciiDoc source without affecting behavior:

```asciidoc
[.mermaid-hints-simple]
****
S2 | Site | Description. +
S1 | Site | Description.

Grant | AccessGrant | Description. +
Token | AccessToken | Description.
****
```

### Node ID matching

Mermaid generates different ID patterns for regular nodes vs subgraphs:

| Diagram element | Mermaid ID pattern | Example |
|---|---|---|
| Regular node (`Grant[AccessGrant]`) | `flowchart-{id}-{n}` | `flowchart-Grant-3` |
| Subgraph (`subgraph S2 [...]`) | `{id}` | `S2` |

The pattern handles both automatically — no special syntax needed.

### Behavior

- A single shared popover is created per page (dark background, purple title, grey description)
- The popover appears below the hovered node, centered horizontally, clamped to viewport edges
- Moving the cursor to the popover keeps it visible (for reading longer descriptions)
- The pattern wraps the preceding `[.mermaid]` block in a container div to reliably track it through Mermaid's async CDN rendering
- Multiple `[.mermaid-hints-*]` blocks on a page are supported, each targeting its preceding diagram

### Important

- Do NOT use raw HTML tags (e.g. `<br>`) inside the sidebar block — AsciiDoc passes them through and they break the block structure
- The `[.mermaid-hints-simple]` block must appear AFTER the `[.mermaid]` diagram it targets (the pattern walks backwards through siblings to find it)

### Used in

`m3/m3.2`

---

## Overlay

SVG annotation overlays (arrows, numbered circles, labels) on images, terminal output, and Mermaid diagrams.

**File:** `overlay.adoc`

### Usage (on images)

```asciidoc
[#my-image]
image::m4/kafka-to-rocketchat.png[width=50%]

[.overlay]
****
[.target]
my-image

[.arrows]
{x: 30, y: 24, rot: 45, color: "red"} +
{x: 0, y: 24, rot: 180, color: "blue"}

[.numbers]
{x: 9, y: 58, size: 2} +
{x: 30, y: 38}

[.labels]
{x: 18, y: 90, text: "Source", size: 1.2} +
{x: 52, y: 90, text: "Process", size: 1.2}
****
```

### Usage (on terminal output)

Put the `id` directly on the `<pre>` tag — AsciiDoc `[#id]` doesn't wrap passthrough blocks.

```asciidoc
++++
<pre id="my-output" style="background-color: #272822; ...">$ oc get pods
NAME    READY   STATUS
pod-1   1/1     Running</pre>
++++

[.overlay]
****
[.target]
my-output

[.arrows]
{x: 50, y: 50}
****
```

### Usage (on Mermaid diagrams)

Combine id and class on one line — two separate attribute lines don't merge.

```asciidoc
[#my-diagram.mermaid]
----
flowchart LR
    A([Source]) --> B[Process] --> C([Dest])
----

[.overlay]
****
[.target]
my-diagram

[.labels]
{x: 15, y: 90, text: "Input", size: 1.2} +
{x: 85, y: 90, text: "Output", size: 1.2}
****
```

### Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `[.target]` | Yes | HTML id of the element to overlay. |
| `[.arrows]` | No | Arrow annotations. Each item: `{x, y, rot, size, color}`. |
| `[.numbers]` | No | Circled numbers, auto-numbered 1, 2, 3... Each item: `{x, y, size, color}`. |
| `[.labels]` | No | Text labels. Each item: `{x, y, text, rot, size, color}`. |

### Coordinate system

- `x`, `y` — percentages (0–100) of the target element's dimensions. `0,0` = top-left.
- `rot` — degrees. Arrows: 0 = pointing up, 90 = right, 180 = down. Labels: 0 = horizontal.
- `size` — multiplier (default 1).
- `color` — any CSS color (default `red`).

### Behavior

- Each item is a JS object literal on its own line, separated by ` +`
- `{x: 30}` passes through AsciiDoc unchanged — no escaping needed
- Overlays reposition on window resize (debounced)
- Waits for Mermaid async rendering before initializing diagram overlays
- CSS hides raw sidebar blocks (`display: none`) to prevent flash of unstyled content

### Used in

`test/test.1` (test page with examples for all three target types)

---

## Creating a new pattern

1. Create `partials/patterns/newpattern.adoc` with a `++++` passthrough block containing `<style>` and `<script>` sections
2. Use `[subs=attributes]` on the passthrough block if the pattern needs AsciiDoc attributes resolved (e.g. `{url-docserver}`)
3. Hide raw sidebar blocks with CSS: `.sidebarblock.newpattern { display: none; }`
4. In JS, add a `DOMContentLoaded` handler that queries `.sidebarblock.newpattern`, extracts content from `.paragraph` children, builds replacement HTML, and replaces the original block
5. Use prefixed CSS classes (e.g. `np-tooltip`) to avoid collisions with other patterns
6. Add `include::./newpattern.adoc[]` to `all.adoc`

### Architecture pattern

All patterns follow the same structure:

```
AsciiDoc sidebar block    →    CSS hides it    →    JS transforms it on DOMContentLoaded
   [.rolename]                  display: none         querySelectorAll → build HTML → replaceChild
   ****
   content...
   ****
```

Role paragraphs inside the block (e.g. `[.path]`, `[.success]`, `[.meta]`) act as named parameters — they become CSS classes on the rendered `.paragraph` divs, which JS can query with `classList.contains()`.
