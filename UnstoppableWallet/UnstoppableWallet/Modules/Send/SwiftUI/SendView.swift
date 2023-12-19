import Kingfisher
import SwiftUI
import ThemeKit

struct SendView: View {
    @ObservedObject var viewModel: SendViewModelNew

    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        ScrollableThemeView {
            VStack(spacing: .margin16) {
                HStack(spacing: .margin8) {
                    Text("send.available_balance".localized).textSubhead2()
                    Spacer()
                    Text("12345.678").textSubhead2(color: .themeLeah)
                }
                .padding(.horizontal, .margin16)
                .padding(.vertical, .margin12)
                .overlay(RoundedRectangle(cornerRadius: .cornerRadius12, style: .continuous).stroke(Color.themeSteel20, lineWidth: .heightOneDp))

                SendModuleNew.amountView(token: viewModel.token)

                Button(action: {}) {
                    Text("button.next".localized)
                }
                .buttonStyle(PrimaryButtonStyle(style: .yellow))
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin16, trailing: .margin16))
        }
        .navigationTitle("Send \(viewModel.token.coin.code)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                KFImage.url(URL(string: viewModel.token.coin.imageUrl))
                    .resizable()
                    .frame(width: .iconSize24, height: .iconSize24)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button("button.cancel".localized) {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}
