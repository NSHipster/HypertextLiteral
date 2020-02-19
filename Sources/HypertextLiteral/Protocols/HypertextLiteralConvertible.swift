/**
 A type that customizes its representation in a hypertext literal.
 */
public protocol HypertextLiteralConvertible {
    /// A representation of this instance in a hypertext literal.
    var html: HTML { get }
}
