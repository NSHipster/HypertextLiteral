# HypertextLiteral

![CI][ci badge]
[![Documentation][documentation badge]][documentation]

**HypertextLiteral** is a Swift package for
generating HTML, XML, and [other SGML dialects](#support-for-other-formats).

It uses [custom string interpolation][expressiblebystringinterpolation]
to append and escape values _based on context_,
with built-in affordances for common patterns
and an extensible architecture for defining your own behavior.

```swift
import HypertextLiteral

let attributes = [
    "style": [
        "background": "yellow",
        "font-weight": "bold"
    ]
]

let html: HTML = "<span \(attributes)>whoa</span>"
// <span style="background: yellow; font-weight: bold;">whoa</span>
```

HypertextLiteral is small and self-contained with no external dependencies.
You can get up to speed in just a few minutes,
without needing to learn any new APIs or domain-specific languages (DSLs).
Less time fighting your tools means more time spent generating web content.

> This project is inspired by and borrows implementation details from
> [Hypertext Literal][htl] by Mike Bostock ([@mbostock][@mbostock]).
> You can read more about it [here][observablehq].

## Requirements

- Swift 5.0+

## Installation

### Swift Package Manager

Add the HypertextLiteral package to your target dependencies in `Package.swift`:

```swift
import PackageDescription

let package = Package(
  name: "YourProject",
  dependencies: [
    .package(
        url: "https://github.com/NSHipster/HypertextLiteral",
        from: "0.0.3"
    ),
  ]
)
```

Then run the `swift build` command to build your project.

## Usage

Hypertext literals automatically escape interpolated values
based on the context in which they appear.

* By default,
  interpolated content escapes the [XML entities][xml entities]
  `<`, `>`, `&`, `"`, and `'`
  as named character references
  (for example, `<` becomes `&lt;`)
* In the context of an attribute value,
  quotation marks are escaped with a backslash (`\"`)
* In a context of comment,
  any start and end delimiters (`<!--` and `-->`) are removed

### Interpolating Content

To get a better sense of how this works in practice,
consider the following examples:

```swift
let level: Int = 1
"<h\(level)>Hello, world!</h\(level)>" as HTML
// <h1>Hello, world!</h1>

let elementName: String = "h1"
"<\(elementName)>Hello, world!</\(elementName)>" as HTML
// <h1>Hello, world!</h1>

let startTag: String = "<h1>", endTag: String = "</h1>"
"\(startTag)Hello, world!\(endTag)" as HTML
// &lt;h1&gt;Hello, world!&lt;/h1&gt;
```

Interpolation for an element's name in part or whole work as intended,
but interpolation of the tag itself causes the string to have its
angle bracket (`<` and `>`) escaped.

When you don't want this to happen,
such as when you're embedding HTML content in a template,
you can either pass that content as an `HTML` value
or interpolate using the `unsafeUnescaped` argument label.

```swift
let startTag: HTML = "<h1>", endTag: HTML = "</h1>"
"\(startTag)Hello, world!\(endTag)" as HTML
// <h1>Hello, world!</h1>

"\(unsafeUnescaped: "<h1>")Hello, world!\(unsafeUnescaped: "</h1>")" as HTML
// <h1>Hello, world!</h1>
```

> **Note**:
> Interpolation with the `unsafeUnescaped` argument label
> appends the provided literal directly,
> which may lead to invalid results.
> For this reason,
> use of `HTML` values for composition is preferred.

### Interpolating Attribute Values

Attributes in hypertext literals may be interchangeably specified
with or without quotation marks, either single (`'`) or double (`"`).

```swift
let id: String = "logo
let title: String = #"Swift.org | "Welcome to Swift.org""#
let url = URL(string: "https://swift.org/")!

#"<a id='\#(logo)' title="\#(title)" href=\#(url)>Swift.org</a>"# as HTML
/* <a id='logo'
      title="Swift.org | \"Welcome to Swift.org\""
      href="https://swift.org/">Swift.org</a>
*/
```

Some attributes have special, built-in rules for value interpolation.

When you interpolate an array of strings for an element's `class` attribute,
the resulting value is a space-delimited list.

```swift
let classNames: [String] = ["alpha", "bravo", "charlie"]

"<div class=\(classNames)>…</div>" as HTML
// <div class="alpha bravo charlie">…</div>
```

If you interpolate a dictionary for the value of an element's `style` attribute,
it's automatically converted to CSS.

```swift
let style: [String: Any] = [
    "background": "orangered",
    "font-weight": 700
]

"<span style=\(style)>Swift</span>" as HTML
// <span style="background: orangered; font-weight: 700;">Swift</span>
```

The Boolean value `true` interpolates to different values depending the attribute.

```swift
"""
<input type="text" aria-enabled=\(true)
                   autocomplete=\(true)
                   spellcheck=\(true)
                   translate=\(true) />
""" as HTML
/* <input type="text" aria-enabled="true"
                      autocomplete="on"
                      spellcheck="spellcheck"
                      translate="yes"/> */
```

### Interpolating Attributes with Dictionaries

You can specify multiple attributes at once
by interpolating dictionaries keyed by strings.

```swift
let attributes: [String: Any] = [
    "id": "primary",
    "class": ["alpha", "bravo", "charlie"],
    "style": [
        "font-size": "larger"
    ]
]

"<div \(attributes)>…</div>" as HTML
/* <div id="primary"
        class="alpha bravo charlie"
        style="font-size: larger;">…</div> */
```

Attributes with a common `aria-` or `data-` prefix
can be specified with a nested dictionary.

```swift
let attributes: [String: Any] = [
    "id": "article",
    "aria": [
        "role": "article",
    ],
    "data": [
        "index": 1,
        "count": 3,
    ]
]

"<section \(attributes)>…</section>" as HTML
/* <section id="article"
            aria-role="article"
            data-index="1"
            data-count="3">…</section> */
```

### Support for Other Formats

In addition to HTML,
you can use hypertext literals for [XML][xml] and other [SGML][sgml] formats.
Below is an example of how `HypertextLiteral` can be used
to generate an SVG document.

```swift
import HypertextLiteral

typealias SVG = HTML

let groupAttributes: [String: Any] = [
    "stroke-width": 3,
    "stroke": "#FFFFEE"
]

func box(_ rect: CGRect, radius: CGVector = CGVector(dx: 10, dy: 10), attributes: [String: Any] = [:]) -> SVG {
    #"""
    <rect x=\#(rect.origin.x) y=\#(rect.origin.y)
          width=\#(rect.size.width) height=\#(rect.size.height)
          rx=\#(radius.dx) ry=\#(radius.dy)
          \#(attributes)/>
    """#
}

let svg: SVG = #"""
<?xml version="1.0" encoding="utf-8"?>
<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'>
  <g \#(groupAttributes)>
    \#(box(CGRect(x: 12, y: 28, width: 60, height: 60), attributes: ["fill": "#F06507"]))
    \#(box(CGRect(x: 27, y: 18, width: 55, height: 55), attributes: ["fill": "#F2A02D"]))
    \#(box(CGRect(x: 47, y: 11, width: 40, height: 40), attributes: ["fill": "#FEC352"]))
  </g>
</svg>
"""#
```

## License

MIT

## Contact

Mattt ([@mattt](https://twitter.com/mattt))

[expressiblebystringinterpolation]: https://nshipster.com/expressiblebystringinterpolation/
[htl]: https://github.com/observablehq/htl
[@mbostock]: https://github.com/mbostock
[observablehq]: https://observablehq.com/@observablehq/htl
[xml entities]: https://en.wikipedia.org/wiki/List_of_XML_and_HTML_character_entity_references
[named character references]: https://html.spec.whatwg.org/multipage/named-characters.html#named-character-references
[xml]: https://en.wikipedia.org/wiki/XML
[sgml]: https://en.wikipedia.org/wiki/Standard_Generalized_Markup_Language
[svg]: https://en.wikipedia.org/wiki/Scalable_Vector_Graphics

[ci badge]: https://github.com/NSHipster/HypertextLiteral/workflows/CI/badge.svg
[documentation badge]: https://github.com/NSHipster/HypertextLiteral/workflows/Documentation/badge.svg
[documentation]: https://github.com/NSHipster/HypertextLiteral/wiki
