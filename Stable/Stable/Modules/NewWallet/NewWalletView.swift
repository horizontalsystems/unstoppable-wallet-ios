import SwiftUI
import UserInterface

struct NewWalletView: View {
    @State private var walletName: String = ""
    @FocusState private var nameFocused: Bool

    @State private var safariUrl: SafariUrl?

    var body: some View {
        ThemeView {
            VStack(alignment: .leading, spacing: 0) {
                ThemeText(key: "new_wallet.title", style: .title3)
                    .padding(.top, 12)
                    .padding(.bottom, 16)
                    .padding(.horizontal, 8)

                InputCard(
                    title: "new_wallet.wallet_name_label",
                    text: $walletName,
                    customButton: .init(icon: "magic") {
                        walletName = "Random Name"
                    },
                    focus: $nameFocused
                )

                Spacer()

                ThemeText(attributedText, style: .subhead, color: .themeGray)
                    .multilineTextAlignment(.center)
                    .environment(\.openURL, OpenURLAction { url in
                        switch url.absoluteString {
                        case "terms": safariUrl = .init(string: AppConfig.companyWebPageLink)
                        case "policy": safariUrl = .init(string: AppConfig.appWebPageLink)
                        default: ()
                        }

                        return .handled
                    })
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 16)

                ThemeButton(text: "new_wallet.create_button") {
                    // todo
                }
                .disabled(walletName.isEmpty)
                .padding(.horizontal, 8)
                .padding(.bottom, 16)
            }
            .padding(.horizontal, 16)
        }
        .onTapGesture {
            nameFocused = false
        }
        .sheet(item: $safariUrl) { url in
            SafariView(url: URL(string: url.string)!)
                .ignoresSafeArea()
        }
    }

    private var attributedText: AttributedString {
        let raw = String(localized: "new_wallet.terms_agreement")

        guard var attributed = try? AttributedString(
            markdown: raw,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) else {
            return AttributedString(raw)
        }

        for run in attributed.runs where run.link != nil {
            attributed[run.range].foregroundColor = .themeLime
            attributed[run.range].underlineStyle = .single
        }

        return attributed
    }
}

extension NewWalletView {
    struct SafariUrl: Identifiable {
        let id = UUID()
        let string: String
    }
}
