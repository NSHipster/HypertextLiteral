/**
 A type that customizes its representation in
 a hypertext literal attribute value.
 */
public protocol HypertextAttributeValueInterpolatable {

    /**
     Returns a representative value of this instance
     for an attribute value in a hypertext literal.

     - Parameters:
       - attribute: The name of the attribute.
       - element: The name of the element.
     - Returns: An HTML representation, or `nil`.
     */
    func html(for attribute: String, in element: String) -> HTML?
}
