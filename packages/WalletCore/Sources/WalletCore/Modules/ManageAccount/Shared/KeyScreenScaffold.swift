import SwiftUI

struct KeyScreenScaffold<Content: View>: View {
    private let title: String
    private let statPage: StatPage
    private let showsInfoButton: Bool
    private let buttonTitle: String
    private let buttonIdentifier: String?
    private let buttonDisabled: Bool
    private let onButtonTap: () -> Void
    private let content: Content

    init(title: String, statPage: StatPage, showsInfoButton: Bool = true, buttonTitle: String = "button.copy".localized, buttonIdentifier: String? = nil, buttonDisabled: Bool = false, onButtonTap: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.title = title
        self.statPage = statPage
        self.showsInfoButton = showsInfoButton
        self.buttonTitle = buttonTitle
        self.buttonIdentifier = buttonIdentifier
        self.buttonDisabled = buttonDisabled
        self.onButtonTap = onButtonTap
        self.content = content()
    }

    var body: some View {
        ThemeView {
            BottomGradientWrapper {
                ScrollView {
                    content
                        .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
                }
            } bottomContent: {
                let button = ThemeButton(text: buttonTitle, style: .primary) {
                    onButtonTap()
                }

                if let buttonIdentifier {
                    button
                        .disabled(buttonDisabled)
                        .accessibilityIdentifier(buttonIdentifier)
                } else {
                    button
                        .disabled(buttonDisabled)
                }
            }
        }
        .navigationTitle(title)
        .toolbar {
            if showsInfoButton {
                ToolbarItem(placement: .primaryAction) {
                    infoButton
                }
            }
        }
    }

    private var infoButton: some View {
        Button {
            guard let url = FaqUrlHelper.privateKeysUrl else {
                return
            }

            Coordinator.shared.present { isPresented in
                MarkdownView(url: url, handleRelativeUrl: false, isPresented: isPresented)
            }
            stat(page: statPage, event: .open(page: .info))
        } label: {
            Image("information")
        }
    }
}
