import SwiftUI

struct ExperimentalFeaturesView: View {
    var body: some View {
        ScrollableThemeView {
            VStack(spacing: .margin24) {
                HighlightedTextView(text: "settings.experimental_features.description".localized)

                ListSection {
                    NavigationRow(destination: {
                        SimpleActivateModule.bitcoinHodlingView()
                    }) {
                        Text("settings.experimental_features.bitcoin_hodling".localized).themeBody()
                        Image.disclosureIcon
                    }
                }
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
        .navigationTitle("settings.experimental_features.title".localized)
    }
}
