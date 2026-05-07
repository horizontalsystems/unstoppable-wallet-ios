import SwiftUI

struct AccountWarningView: View {
    @ObservedObject var viewModel: AccountWarningViewModel

    var body: some View {
        if let item = viewModel.item {
            Button(action: {
                if let url = item.url {
                    Coordinator.shared.present { _ in
                        MarkdownView(url: url, navigation: true).ignoresSafeArea()
                    }
                }
            }) {
                AlertCardView(item.alertItem)
            }
        }
    }

    private func termsTextPart(string: String, url: URL? = nil) -> AttributedString {
        var part = AttributedString(string)

        if let url {
            part.link = url
            part.foregroundColor = .themeIssykBlue
            part.underlineStyle = .single
        }

        return part
    }

    private func attibutedText(text _: String, url: URL?) -> AttributedString {
        var result = AttributedString("restore.error.non_standard.description".localized)
        result.append(termsTextPart(string: "restore.error.non_standard.link".localized, url: url))

        return result
    }
}
