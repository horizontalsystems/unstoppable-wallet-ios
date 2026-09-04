import SwiftUI

struct WCNMessageView: View {
    let text: String

    var body: some View {
        ThemeView {
            ScrollView {
                ListSection {
                    ListRow {
                        Text(text)
                            .themeSubhead2(color: .themeLeah)
                            .textSelection(.enabled)
                    }
                }
                .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
            }
        }
        .navigationTitle("wallet_connect.sign.message".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}
