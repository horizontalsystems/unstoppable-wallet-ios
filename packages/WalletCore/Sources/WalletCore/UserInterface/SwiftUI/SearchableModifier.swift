import SwiftUI

struct SearchableModifier: ViewModifier {
    @Binding var text: String
    let prompt: String
    let autoFocus: Bool
    let isActive: Bool

    @FocusState private var focused: Bool

    func body(content: Content) -> some View {
        if !isActive {
            content
        } else if #available(iOS 18.0, *) {
            content
                .searchable(text: $text, prompt: prompt)
                .searchFocused($focused)
                .searchPresentationToolbarBehavior(.avoidHidingContent)
                .onAppear { focused = autoFocus }
        } else if #available(iOS 17.1, *) {
            content
                .searchable(text: $text, prompt: prompt)
                .searchPresentationToolbarBehavior(.avoidHidingContent)
        } else {
            content
                .searchable(text: $text, prompt: prompt)
        }
    }
}

extension View {
    func searchBar(text: Binding<String>, prompt: String, autoFocus: Bool = false, isActive: Bool = true) -> some View {
        modifier(SearchableModifier(text: text, prompt: prompt, autoFocus: autoFocus, isActive: isActive))
    }
}

// TODO: it is used in MarketView only (remove after applying new search)
