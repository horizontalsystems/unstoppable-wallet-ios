import SwiftUI

struct UsedAddressesView: View {
    let coinName: String
    let title: String
    let description: String
    let hasChangeAddresses: Bool
    let usedAddresses: [ReceiveAddressModule.AddressType: [UsedAddress]]
    var onDismiss: (() -> Void)?

    @State private var currentTabIndex: Int = ReceiveAddressModule.AddressType.external.rawValue

    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        ScrollableThemeView {
            VStack(spacing: .margin12) {
                Text(description).textSubhead2().padding(EdgeInsets(top: 0, leading: .margin16, bottom: 0, trailing: .margin16))

                if hasChangeAddresses {
                    TabHeaderView(
                        tabs: usedAddresses.map { key, _ in key }.sorted().map(\.title),
                        currentTabIndex: $currentTabIndex
                    )
                }

                ListSection {
                    if let key = ReceiveAddressModule.AddressType(rawValue: currentTabIndex), let addresses = usedAddresses[key] {
                        ForEach(addresses, id: \.self) { address in
                            ListRow {
                                HStack(spacing: .margin16) {
                                    Text("\(address.index)")
                                        .textSubhead2()
                                        .frame(width: width(index: addresses.last?.index ?? 0 + 1), alignment: .leading)
                                    VStack(alignment: .leading, spacing: .margin4) {
                                        Text(address.address).textSubhead2(color: .themeLeah)

                                        if let transactionsCount = address.transactionsCount {
                                            Text("deposit.subaddresses.transactions_count".localized("\(transactionsCount)")).textCaptionSB(color: .themeGray)
                                        }
                                    }
                                    Spacer()
                                    if let explorerUrl = address.explorerUrl {
                                        Button(action: {
                                            Coordinator.shared.present(url: explorerUrl)
                                        }) {
                                            Image("globe_20").renderingMode(.template)
                                        }
                                        .buttonStyle(SecondaryCircleButtonStyle(style: .default))
                                    }

                                    Button(action: { CopyHelper.copyAndNotify(value: address.address) }) {
                                        Image("copy_20").renderingMode(.template)
                                    }
                                    .buttonStyle(SecondaryCircleButtonStyle(style: .default))
                                }
                            }
                        }
                    }
                }
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
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

    private func width(index: Int) -> CGFloat {
        let count = index.description.count
        let maxValue = String(repeating: "9", count: count)
        return maxValue.size(containerWidth: .greatestFiniteMagnitude, font: .subhead2).width
    }
}
