import SwiftUI

struct FirstAppear: ViewModifier {
    let action: () -> Void

    @StateObject private var isFirstAppear = FirstAppearState()

    func body(content: Content) -> some View {
        content.onAppear {
            if isFirstAppear.value {
                isFirstAppear.value = false
                action()
            }
        }
    }
}

private class FirstAppearState: ObservableObject {
    @Published var value: Bool = true
}
