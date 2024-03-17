import SwiftUI

private struct TransparentFullScreenModifier<FullScreenContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let fullScreenContent: () -> FullScreenContent

    func body(content: Content) -> some View {
        content
            .onChange(of: isPresented) { _ in
                UIView.setAnimationsEnabled(false)
            }
            .fullScreenCover(
                    isPresented: $isPresented,
                    content: {
                        ZStack {
                            fullScreenContent()
                        }
                            .background(FullScreenCoverBackgroundRemovalView())
                            .onAppear {
                                if !UIView.areAnimationsEnabled {
                                    UIView.setAnimationsEnabled(true)
                                }
                            }
                            .onDisappear {
                                if !UIView.areAnimationsEnabled {
                                    UIView.setAnimationsEnabled(true)
                                }
                            }
                    }
            )
    }
}

private struct FullScreenCoverBackgroundRemovalView: UIViewRepresentable {
    private class BackgroundRemovalView: UIView {
        override func didMoveToWindow() {
            super.didMoveToWindow()

            superview?.superview?.backgroundColor = .clear
        }
    }

    func makeUIView(context _: Context) -> UIView {
        BackgroundRemovalView()
    }

    func updateUIView(_: UIView, context _: Context) {}
}

extension View {
    func transparentFullScreenCover(isPresented: Binding<Bool>, content: @escaping () -> some View) -> some View {
        modifier(TransparentFullScreenModifier(isPresented: isPresented, fullScreenContent: content))
    }
}
