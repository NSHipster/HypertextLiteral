import XCTest
@testable import HypertextLiteral
import Foundation

final class HypertextLiteralTests: XCTestCase {
    func testOriginalHyperTextLiteralEquivalence() throws {
        let attributes = [
            "style": [
                "background": "yellow",
                "font-weight": "bold"
            ]
        ]

        let html: HTML = "<span \(attributes)>whoa</span>"

        let expected: String = #"<span style="background: yellow; font-weight: bold;">whoa</span>"#

        XCTAssertEqual(html.description, expected)
    }

    func testInitializerWithDescription() throws {
        let html: HTML = HTML(#"<h1>Hello, world!</h1>"#)

        let expected: String = #"<h1>Hello, world!</h1>"#

        XCTAssertEqual(html.description, expected)
    }

    func testStringLiteralWithoutInterpolation() throws {
        let html: HTML = #"<h1>Hello, world!</h1>"#

        let expected: String = #"<h1>Hello, world!</h1>"#

        XCTAssertEqual(html.description, expected)
    }

    func testStringLiteralWithTextInterpolation() throws {
        let html: HTML = #"<h1>Hello, \#("world")!</h1>"#

        let expected: String = #"<h1>Hello, world!</h1>"#

        XCTAssertEqual(html.description, expected)
    }

    func testStringLiteralWithEscapedTextInterpolation() throws {
        let html: HTML = #"<h1>Hello, \#("<world>")!</h1>"#

        let expected: String = #"<h1>Hello, &lt;world&gt;!</h1>"#

        XCTAssertEqual(html.description, expected)
    }

    func testStringLiteralWithElementNameInterpolation() throws {
        let tag: String = "h1"
        let html: HTML = #"<\#(tag)>Hello, world!</\#(tag)>"#

        let expected: String = #"<h1>Hello, world!</h1>"#

        XCTAssertEqual(html.description, expected)
    }

    func testStringLiteralWithPartialElementNameInterpolation() throws {
        let level: Int = 1
        let html: HTML = #"<h\#(level)>Hello, world!</h\#(level)>"#

        let expected: String = #"<h1>Hello, world!</h1>"#

        XCTAssertEqual(html.description, expected)
    }

    func testStringLiteralWithStringTagInterpolation() throws {
        let startTag: String = "<h1>"
        let endTag: String = "</h1>"

        let html: HTML = #"\#(startTag)Hello, world!\#(endTag)"#

        let expected: String = #"&lt;h1&gt;Hello, world!&lt;/h1&gt;"#

        XCTAssertEqual(html.description, expected)
    }

    func testStringLiteralWithHTMLTagInterpolation() throws {
        let startTag: HTML = "<h1>"
        let endTag: HTML = "</h1>"

        let html: HTML = #"\#(startTag)Hello, world!\#(endTag)"#

        let expected: String = #"<h1>Hello, world!</h1>"#

        XCTAssertEqual(html.description, expected)
    }

    func testStringLiteralWithStringAttributeInterpolation() throws {
        let id: String = "logo"
        let url = URL(string: "https://swift.org/")!
        let title: String = #"Swift.org | "Welcome to Swift.org""#
        let html: HTML = #"<a id='\#(id)' href="\#(url)" title=\#(title)>Swift.org</a>"#

        let expected: String = #"<a id='logo' href="https://swift.org/" title="Swift.org | \"Welcome to Swift.org\"">Swift.org</a>"#

        XCTAssertEqual(html.description, expected)
    }

    func testStringLiteralWithClassAttributeInterpolation() throws {
        let attributes: [String: [String]] = [
            "class": ["alpha", "bravo", "charlie"]
        ]

        let html: HTML = #"""
        <div \#(attributes)></div>
        """#

        let expected = #"""
        <div class="alpha bravo charlie"></div>
        """#

        XCTAssertEqual(html.description, expected)
    }

    func testStringLiteralWithStyleAttributeInterpolation() throws {
        let style: [String: Any] = [
            "background": "orangered",
            "font-weight": 700
        ]

        let html: HTML = #"""
        <span style=\#(style)>Swift</span>
        """#

        let expected = #"""
        <span style="background: orangered; font-weight: 700;">Swift</span>
        """#

        XCTAssertEqual(html.description, expected)
    }

    func testStringLiteralWithNestedAttributesInterpolation() throws {
        let attributes: [String: [String: Any]] = [
            "aria": [
                "role": "article",
            ],
            "data": [
                "index": 1,
                "count": 3,
            ],
            "style": [
                "background": "orangered",
                "font-weight": 700
            ]
        ]

        let html: HTML = #"""
        <section \#(attributes)>…</section>
        """#

        let expected = #"""
        <section aria-role="article" data-count="3" data-index="1" style="background: orangered; font-weight: 700;">…</section>
        """#

        XCTAssertEqual(html.description, expected)
    }

    func testStringLiteralWithBooleanAttributeInterpolation() throws {
        let attributes: [String: Any] = [
            "aria": [
                "label": true
            ],
            "autocomplete": true,
            "spellcheck": true,
            "translate": true,
            "type": "text"
        ]

        let html: HTML = #"""
        <input \#(attributes)/>
        """#

        let expected = #"""
        <input aria-label="true" autocomplete="on" spellcheck="spellcheck" translate="yes" type="text"/>
        """#

        XCTAssertEqual(html.description, expected)
    }

    func testStringLiteralWithUnsafeUnescapedInterpolation() throws {
        let inlineHTML: String = "<strong>&amp;</strong>"
        let html: HTML = #"<span>\#(unsafeUnescaped: inlineHTML)</span>"#

        let expected = #"<span><strong>&amp;</strong></span>"#

        XCTAssertEqual(html.description, expected)
    }

    func testStringLiteralWithoutUnsafeUnescapedInterpolation() throws {
        let inlineHTML: String = "<strong>&amp;</strong>"
        let html: HTML = #"<span>\#(inlineHTML)</span>"#

        let expected = #"<span>&lt;strong&gt;&amp;amp;&lt;/strong&gt;</span>"#

        XCTAssertEqual(html.description, expected)
    }

    func testStringLiteralWithCommentInterpolationInText() throws {
        let html: HTML = #"\#(comment: "(　ﾟДﾟ)<!!")"#

        let expected = #"<!-- (　ﾟДﾟ)<!! -->"#

        XCTAssertEqual(html.description, expected)
    }

    func testStringLiteralWithCommentInterpolationInComment() throws {
        let html: HTML = #"<!-- \#(comment: "<!-- (－_－) zzZ -->") -->"#

        let expected = #"<!-- (－_－) zzZ -->"#

        XCTAssertEqual(html.description, expected)
    }

    func testStringLiteralWithEmbeddedHTMLInterpolation() throws {
        func results(for string: String) -> HTML {
            func entry(for character: Character) -> HTML {
                func definition(for scalar: Unicode.Scalar) -> HTML {
                    return #"<dd>U+\#(String(format: "%04X", scalar.value)) \#(scalar.properties.name ?? "")</dd>"#
                }

                return #"""
                <dt>\#(character)</dt>
                \#(character.unicodeScalars.map { definition(for: $0) })
                """#
            }

            return #"""
            <dl>
            \#(string.map { entry(for: $0) })
            </dl>
            """#
        }

        let string: String = "🕵️❗️"

        let title: String = "Unicode String Inspector - \(string)"

        let content: HTML = #"""
        <h1>Results for <var>\#(string)</var>:</h1>
        \#(results(for: string))
        """#

        let html: HTML = #"""
        <!DOCTYPE html>
        <html lang="en-US">
        <head>
            <title>\#(title)</title>
        </head>
        <body>
            <main>
                \#(content)
            </main>
        </body>
        </html>
        """#

        let expected: String = #"""
        <!DOCTYPE html>
        <html lang="en-US">
        <head>
            <title>Unicode String Inspector - 🕵️❗️</title>
        </head>
        <body>
            <main>
                <h1>Results for <var>🕵️❗️</var>:</h1>
        <dl>
        <dt>🕵️</dt>
        <dd>U+1F575 SLEUTH OR SPY</dd>
        <dd>U+FE0F VARIATION SELECTOR-16</dd>
        <dt>❗️</dt>
        <dd>U+2757 HEAVY EXCLAMATION MARK SYMBOL</dd>
        <dd>U+FE0F VARIATION SELECTOR-16</dd>
        </dl>
            </main>
        </body>
        </html>
        """#

        XCTAssertEqual(html.description, expected)
    }

    func testStringLiteralWithSVGInterpolation() throws {
        typealias SVG = HTML

        let groupAttributes: [String: Any] = [
            "stroke-width": 3,
            "stroke": "#FFFFEE"
        ]

        func box(_ rect: CGRect, radius: CGFloat = 10, attributes: [String: Any] = [:]) -> SVG {
            #"""
            <rect x=\#(rect.origin.x) y=\#(rect.origin.y)
                  width=\#(rect.size.width) height=\#(rect.size.height)
                  rx=\#(radius) ry=\#(radius)
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

        let expected = #"""
        <?xml version="1.0" encoding="utf-8"?>
        <svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'>
          <g stroke="#FFFFEE" stroke-width="3">
            <rect x="12.0" y="28.0"
              width="60.0" height="60.0"
              rx="10.0" ry="10.0"
              fill="#F06507"/>
            <rect x="27.0" y="18.0"
              width="55.0" height="55.0"
              rx="10.0" ry="10.0"
              fill="#F2A02D"/>
            <rect x="47.0" y="11.0"
              width="40.0" height="40.0"
              rx="10.0" ry="10.0"
              fill="#FEC352"/>
          </g>
        </svg>
        """#

        XCTAssertEqual(svg.description, expected)
    }
}
