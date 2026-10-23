import SwiftUI

struct KeyScreenScaffold<Content: View>: View {
    private let title: String
    private let statPage: StatPage
    private let showsInfoButton: Bool
    private let copyDisabled: Bool
    private let onCopy: () -> Void
    private let content: Content

    init(title: String, statPage: StatPage, showsInfoButton: Bool = true, copyDisabled: Bool = false, onCopy: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.title = title
        self.statPage = statPage
        self.showsInfoButton = showsInfoButton
        self.copyDisabled = copyDisabled
        self.onCopy = onCopy
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
                ThemeButton(text: "button.copy".localized, style: .primary) {
                    onCopy()
                }
                .disabled(copyDisabled)
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

            Coordinator.shared.present { _ in
                MarkdownView(url: url, handleRelativeUrl: false, navigation: true).ignoresSafeArea()
            }
            stat(page: statPage, event: .open(page: .info))
        } label: {
            Image("information")
        }
    }
}
