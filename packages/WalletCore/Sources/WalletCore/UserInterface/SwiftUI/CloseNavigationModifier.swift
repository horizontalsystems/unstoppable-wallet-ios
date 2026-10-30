import SwiftUI

struct CloseNavigationModifier: ViewModifier {
    let isPresented: Binding<Bool>?

    func body(content: Content) -> some View {
        if let isPresented {
            ThemeNavigationStack {
                content
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button {
                                isPresented.wrappedValue = false
                            } label: {
                                Image("close")
                            }
                        }
                    }
            }
        } else {
            content
        }
    }
}

extension View {
    /// Wraps in a navigation stack with a close button when presented modally; returns the view unchanged otherwise
    func closeNavigation(isPresented: Binding<Bool>?) -> some View {
        modifier(CloseNavigationModifier(isPresented: isPresented))
    }
}
