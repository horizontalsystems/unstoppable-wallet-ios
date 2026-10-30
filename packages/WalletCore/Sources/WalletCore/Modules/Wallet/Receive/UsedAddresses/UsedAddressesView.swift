import SwiftUI

struct UsedAddressesView: View {
    let coinName: String
    let title: String
    let description: String
    let hasChangeAddresses: Bool
    let usedAddresses: [HDReceiveAddressViewModel.AddressChain: [UsedAddress]]
    var onDismiss: (() -> Void)?

    @State private var currentTabIndex: Int = HDReceiveAddressViewModel.AddressChain.external.rawValue

    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        ScrollableThemeView {
            VStack(spacing: .margin12) {
                Text(description).textSubhead2().padding(.padding16)

                if hasChangeAddresses {
                    TabHeaderView(
                        tabs: usedAddresses.map { key, _ in key }.sorted().map(\.title),
                        currentTabIndex: $currentTabIndex
                    )
                }

                ListSection {
                    if let key = HDReceiveAddressViewModel.AddressChain(rawValue: currentTabIndex), let addresses = usedAddresses[key] {
                        ForEach(addresses, id: \.self) { address in
                            Cell(
                                left: {
                                    ThemeText("\(address.index)", style: .subhead)
                                        .frame(width: width(index: addresses.last?.index ?? 0 + 1), alignment: .leading)
                                },
                                middle: {
                                    VStack(alignment: .leading, spacing: .margin4) {
                                        ThemeText(address.address, style: .subhead, colorStyle: .primary)

                                        if let transactionsCount = address.transactionsCount {
                                            ThemeText("deposit.subaddresses.transactions_count".localized("\(transactionsCount)"), style: .captionSB)
                                        }
                                    }
                                },
                                right: {
                                    HStack(spacing: .margin8) {
                                        if let explorerUrl = address.explorerUrl {
                                            IconButton(icon: "globe", style: .secondary, size: .small) {
                                                Coordinator.shared.present(url: explorerUrl)
                                            }
                                        }

                                        IconButton(icon: "copy", style: .secondary, size: .small) {
                                            CopyHelper.copyAndNotify(value: address.address)
                                        }
                                    }
                                }
                            )
                        }
                    }
                }
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
        .navigationTitle(title)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(action: {
                    if let onDismiss {
                        onDismiss()
                    } else {
                        presentationMode.wrappedValue.dismiss()
                    }
                }) {
                    Image("check")
                }
            }
        }
    }

    private func width(index: Int) -> CGFloat {
        let count = index.description.count
        let maxValue = String(repeating: "9", count: count)
        return maxValue.size(containerWidth: .greatestFiniteMagnitude, font: .subhead1).width
    }
}
