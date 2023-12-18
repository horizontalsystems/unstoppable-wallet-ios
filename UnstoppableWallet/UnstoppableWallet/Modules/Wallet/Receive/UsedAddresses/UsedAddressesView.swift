import SwiftUI

struct UsedAddressesView: View {
    let coinName: String
    let usedAddresses: [UsedAddress]
    var onDismiss: (() -> ())?

    @Environment(\.presentationMode) private var presentationMode
    @State private var linkUrl: URL?

    var body: some View {
        ScrollableThemeView {
            VStack(spacing: .margin12) {
                Text("deposit.used_addresses.description".localized(coinName))
                    .textSubhead2()
                    .padding(EdgeInsets(top: 0, leading: .margin16, bottom: 0, trailing: .margin16))

                ListSection {
                    ForEach(usedAddresses, id: \.self) { address in
                        ListRow {
                            HStack(spacing: .margin16) {
                                Text("\(address.index + 1)").textSubhead2()
                                Text(address.address).textSubhead2(color: .themeLeah)
                                Button(action: { linkUrl = address.explorerUrl }) {
                                    Image("globe_20").renderingMode(.template)
                                }
                                .buttonStyle(SecondaryCircleButtonStyle(style: .default))

                                Button(action: { CopyHelper.copyAndNotify(value: address.address) }) {
                                    Image("copy_20").renderingMode(.template)
                                }
                                .buttonStyle(SecondaryCircleButtonStyle(style: .default))
                            }
                        }
                    }
                }
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
            .sheet(item: $linkUrl) { url in
                SFSafariView(url: url)
                    .ignoresSafeArea()
            }
        }
        .navigationTitle("deposit.used_addresses.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("button.done".localized) {
                    if let onDismiss {
                        onDismiss()
                    } else {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .accentColor(.themeJacob)
    }
}
