public protocol HypertextAttributeValueInterpolatable {
    func html(for attribute: String, in element: String) -> HTML?
}
