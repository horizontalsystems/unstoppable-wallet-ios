import Foundation

// Positional `ForEach` identity for static lists that may contain equal elements; lists are replaced wholesale on reload
struct IndexedElement<Element>: Identifiable {
    let index: Int
    let element: Element

    var id: Int {
        index
    }
}

extension Array {
    var indexedElements: [IndexedElement<Element>] {
        enumerated().map { IndexedElement(index: $0.offset, element: $0.element) }
    }
}
