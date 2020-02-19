/**
 A type that provides attributes for a hypertext literal element.
*/
public protocol HypertextAttributesInterpolatable {
    /**
      Returns the attributes that correspond to this instance
      for an element in a hypertext literal.

      - Parameters:
        - element: The name of the element.
      - Returns: An HTML representation, or `nil`.
     */
    func html(in element: String) -> HTML
}
