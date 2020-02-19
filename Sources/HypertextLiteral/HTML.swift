import Foundation

/**
 An object whose content can be created using string interpolation
 in a way that interprets values according to the context
 at which the interpolation occurs.

 For more information,
 see [this project's README](https://github.com/NSHipster/HypertextLiteral).
 */
public struct HTML: LosslessStringConvertible, Equatable, Hashable {
    /// The HTML content.
    public var description: String

    /**
     Creates an HTML object with the specified content.
     - Parameter description: The HTML content.
     */
    public init(_ description: String) {
        self.description = description
    }
}

// MARK: - HypertextConvertible

extension HTML: HypertextLiteralConvertible {
    public var html: HTML {
        return self
    }
}

// MARK: -

extension HTML {
    class Parser {
        private enum State {
            case text
            case tagOpen
            case elementName
            case afterElementName
            case attributeName
            case afterAttributeName
            case beforeAttributeValue
            case attributeValue(QuotationMark?)
            case afterAttributeValue
            case selfClosingTag
            case beforeComment
            case comment
            case unsupportedEntity
        }

        enum QuotationMark: Character {
            case single = "'"
            case double = "\""
        }

        enum Disposition {
            case text
            case element(elementName: String)
            case attribute(elementName: String, attributeName: String, quotationMarks: QuotationMark?)
            case comment
        }

        private var state: State = .text

        func parse(_ string: String) -> Disposition {
            var skipNext: Int = 0

            var elementName: String?
            var attributeName: String?

            for (index, character) in zip(string.indices, string) {
                guard skipNext <= 0 else {
                    skipNext -= 1
                    continue
                }

                func willNextScan<Target>(_ value: Target) -> Bool where Target: StringProtocol {
                    guard !value.isEmpty else { return false }
                    guard let startIndex = string.index(index, offsetBy: 1, limitedBy: string.endIndex),
                        let endIndex = string.index(index, offsetBy: value.count + 1, limitedBy: string.endIndex),
                        string[startIndex..<endIndex] == value
                        else {
                            return false
                    }

                    skipNext = value.count
                    return true
                }

                redo: repeat {
                    switch state {
                    case .text:
                        if character == "<" {
                            state = .tagOpen
                        }
                    case .tagOpen:
                        switch character {
                        case "!":
                            if willNextScan("--") {
                                state = .beforeComment
                            } else {
                                state = .unsupportedEntity
                            }
                        case "/" where willNextScan(">"):
                            state = .text
                        case "a"..."z", "A"..."Z", "-":
                            state = .elementName
                            continue redo
                        case "?":
                            state = .unsupportedEntity
                            continue redo
                        default:
                            state = .text
                            continue redo
                        }
                    case .elementName:
                        switch character {
                        case _ where character.isWhitespace:
                            state = .afterElementName
                        case "/":
                            state = .selfClosingTag
                        case ">":
                            state = .text
                        default:
                            elementName += character
                        }
                    case .afterElementName:
                        switch character {
                        case _ where character.isWhitespace:
                            break
                        case "/", ">":
                            state = .afterAttributeName
                            continue redo
                        case "=":
                            state = .beforeAttributeValue
                        default:
                            state = .attributeName
                            continue redo
                        }
                    case .attributeName:
                        switch character {
                        case "/", ">":
                            fallthrough
                        case _ where character.isWhitespace:
                            state = .afterAttributeName
                            continue redo
                        case "=":
                            state = .beforeAttributeValue
                        default:
                            attributeName += character
                        }
                    case .afterAttributeName:
                        switch character {
                        case _ where character.isWhitespace:
                            break
                        case "/":
                            state = .selfClosingTag
                        case "=":
                            state = .beforeAttributeValue
                        case ">":
                            state = .text
                        default:
                            attributeName = nil
                            state = .attributeName
                            continue redo
                        }
                    case .beforeAttributeValue:
                        switch character {
                        case _ where character.isWhitespace:
                            break
                        case ">":
                            state = .text
                        default:
                            let quotationMark = QuotationMark(rawValue: character)
                            state = .attributeValue(quotationMark)
                            if quotationMark == nil {
                                continue redo
                            }
                        }
                    case .attributeValue(let quotationMark?):
                        if character == quotationMark.rawValue {
                            attributeName = nil
                            state = .afterAttributeValue
                        }
                    case .attributeValue:
                        switch character {
                        case _ where character.isWhitespace:
                            attributeName = nil
                            state = .afterAttributeValue
                        case ">":
                            state = .text
                        default:
                            break
                        }
                    case .afterAttributeValue:
                        switch character {
                        case _ where character.isWhitespace:
                            state = .afterElementName
                        case "/":
                            state = .selfClosingTag
                        case ">":
                            state = .text
                        default:
                            state = .afterElementName
                            continue redo
                        }
                    case .selfClosingTag:
                        switch character {
                        case ">":
                            elementName = nil
                            attributeName = nil
                            state = .text
                        default:
                            state = .afterElementName
                            continue redo
                        }
                    case .unsupportedEntity:
                        if character == ">" {
                            state = .text
                        }
                    case .beforeComment:
                        switch character {
                        case "-":
                            state = .beforeComment
                        case ">":
                            state = .text
                        default:
                            state = .comment
                            continue redo
                        }
                    case .comment:
                        if willNextScan("-->") {
                            state = .text
                        } else {
                            state = .comment
                        }
                    }

                    break
                } while true
            }

            switch state {
            case .afterElementName:
                return .element(elementName: elementName ?? "")
            case .attributeValue(let quotationMarks):
                return .attribute(elementName: elementName ?? "", attributeName: attributeName ?? "", quotationMarks: quotationMarks)
            case .beforeAttributeValue, .afterAttributeValue:
                return .attribute(elementName: elementName ?? "", attributeName: attributeName ?? "", quotationMarks: .none)
            case .comment, .beforeComment:
                return .comment
            default:
                return .text
            }
        }
    }
}

// MARK: - Comparable

extension HTML: Comparable {
    public static func < (lhs: HTML, rhs: HTML) -> Bool {
        return lhs.description < rhs.description
    }
}

// MARK: - Codable

extension HTML: Codable {
    public init(decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.description = try container.decode(String.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

// MARK: - ExpressibleByStringLiteral

extension HTML: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)
    }
}

// MARK: - ExpressibleByStringInterpolation

extension HTML: ExpressibleByStringInterpolation {
    public init(stringInterpolation: StringInterpolation) {
        self.init(stringInterpolation.value)
    }

    public struct StringInterpolation: StringInterpolationProtocol {
        fileprivate var value: String = ""

        private var parser = Parser()
        private var disposition: Parser.Disposition = .text

        public init(literalCapacity: Int, interpolationCount: Int) {
            self.value.reserveCapacity(literalCapacity)
        }

        public mutating func appendLiteral(_ literal: String) {
            disposition = parser.parse(literal)
            self.value.append(literal)
        }

        public mutating func appendInterpolation<T>(_ value: T) where T: CustomStringConvertible {
            switch disposition {
            case .text:
                switch value {
                case let value as HypertextLiteralConvertible:
                    appendLiteral(value.html.description)
                default:
                    appendLiteral(value.description.escaped)
                }
            case let .element(elementName):
                switch value {
                case let value as HypertextAttributesInterpolatable:
                    appendLiteral(value.html(in: elementName).description)
                default:
                    appendLiteral(value.description.escaped)
                }
            case let .attribute(elementName, attributeName, quotationMarks):
                var literal: String
                if let html = (value as? HypertextAttributeValueInterpolatable)?.html(for: attributeName, in: elementName) {
                    literal = html.description
                } else {
                    literal = value.description
                }

                if quotationMarks != .single {
                    literal = literal.replacingOccurrences(of: "\"", with: "\\\"")
                }

                if quotationMarks == .none {
                    literal = #""\#(literal)""#
                }

                appendLiteral(literal)
            case .comment:
                appendInterpolation(comment: value.description)
            }
        }

        mutating func appendInterpolation(unsafeUnescaped string: String) {
            appendLiteral(string)
        }

        mutating func appendInterpolation(comment string: String) {
            let string = string.replacingOccurrences(of: "<!--", with: "")
                               .replacingOccurrences(of: "-->", with: "")
                               .trimmingCharacters(in: .whitespacesAndNewlines)
            switch disposition {
            case .comment:
                appendLiteral(string)
            default:
                appendLiteral("<!-- \(string) -->")
            }
        }
    }
}

// MARK: -

fileprivate extension StringProtocol {
    var escaped: String {
        #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
        return (CFXMLCreateStringByEscapingEntities(nil, String(self) as NSString, nil)! as NSString) as String
        #else
        return [
            ("&", "&amp;"),
            ("<", "&lt;"),
            (">", "&gt;"),
            ("'", "&apos;"),
            ("\"", "&quot;"),
        ].reduce(String(self)) { (string, element) in
            string.replacingOccurrences(of: element.0, with: element.1)
        }
        #endif
    }

    func escapingOccurrences<Target>(of target: Target, options: String.CompareOptions = [], range searchRange: Range<String.Index>? = nil) -> String where Target : StringProtocol {
        return replacingOccurrences(of: target, with: target.escaped, options: options, range: searchRange)
    }

    func escapingOccurrences<Target>(of targets: [Target], options: String.CompareOptions = []) -> String where Target : StringProtocol {
        return targets.reduce(into: String(self)) { (result, target) in
            result = result.escapingOccurrences(of: target, options: options)
        }
    }
}

fileprivate func += (lhs: inout String?, rhs: Character) {
    lhs = lhs ?? ""
    lhs?.append(rhs)
}
