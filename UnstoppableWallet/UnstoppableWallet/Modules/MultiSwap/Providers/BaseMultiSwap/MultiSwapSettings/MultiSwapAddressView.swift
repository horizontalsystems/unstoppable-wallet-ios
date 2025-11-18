import MarketKit
import SwiftUI

struct MultiSwapAddressView: View {
    @ObservedObject var viewModel: AddressMultiSwapSettingsViewModel
    @Environment(\.addressParserFilter) private var parserFilter

    var body: some View {
        VStack(spacing: 0) {
            ListSection {
                ClickableRow {
                    Coordinator.shared.present { isPresented in
                        ThemeNavigationStack {
                            ThemeView {
                                AddressView(token: viewModel.token, buttonTitle: "button.done".localized, destination: .swap, address: viewModel.address) { resolvedAddress in
                                    viewModel.address = resolvedAddress.address
                                    isPresented.wrappedValue = false
                                }
                            }
                            .navigationTitle("address.title".localized)
                            .navigationBarTitleDisplayMode(.inline)
                        }
                        .environment(\.addressParserFilter, parserFilter)
                    }
                } content: {
                    if let address = viewModel.address {
                        Text("swap.advanced_settings.recipient_address.to".localized).textSubhead2()
                        Text(address)
                            .textBody(color: .themeLeah)
                            .multilineTextAlignment(.leading)

                        Spacer()

                        Button(action: {
                            viewModel.address = nil
                        }, label: {
                            Image("trash_20").renderingMode(.template)
                        })
                        .buttonStyle(SecondaryCircleButtonStyle(style: .default))
                    } else {
                        Text("swap.advanced_settings.add_recipient_address".localized)
                            .textBody(color: .themeLeah)
                            .multilineTextAlignment(.leading)

                        Spacer()

                        Image.disclosureIcon
                    }
                }
            }
            .themeListStyle(.lawrence)

            Text("swap.advanced_settings.recipient.footer".localized)
                .themeSubhead2()
                .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin12, trailing: .margin16))
        }
    }
}
