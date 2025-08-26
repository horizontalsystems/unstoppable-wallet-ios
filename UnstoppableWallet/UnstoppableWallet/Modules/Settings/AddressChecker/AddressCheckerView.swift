import SwiftUI

struct AddressCheckerView: View {
    @StateObject var viewModel = AddressCheckerViewModel()

    @State private var checkAddressPresented = false

    var body: some View {
        ScrollableThemeView {
            VStack(spacing: .margin24) {
                VStack(spacing: 0) {
                    ListSection {
                        if viewModel.activated {
                            ListRow {
                                switchContent()
                            }
                        } else {
                            ClickableRow(action: {
                                Coordinator.shared.presentPurchase(page: .addressChecker, trigger: .disableAddressChecker)
                            }) {
                                switchContent()
                                    .allowsHitTesting(false)
                            }
                        }
                    }

                    ListSectionFooter(text: "address_checker.recipient_check.description".localized)
                }

                VStack(spacing: 0) {
                    ListSection {
                        ClickableRow(action: {
                            if viewModel.activated {
                                checkAddressPresented = true
                            } else {
                                Coordinator.shared.presentPurchase(page: .addressChecker, trigger: .addressChecker)
                            }
                        }) {
                            addressContent()
                        }
                    }

                    ListSectionFooter(text: "address_checker.check_address.description".localized)
                }
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
        .navigationTitle("address_checker.title".localized)
        .navigationDestination(isPresented: $checkAddressPresented) {
            CheckAddressView()
                .onFirstAppear {
                    stat(page: .addressChecker, event: .open(page: .checkAddress))
                }
        }
    }

    @ViewBuilder
    private func switchContent() -> some View {
        Toggle(isOn: $viewModel.recipientAddressCheck.animation()) {
            Text("address_checker.recipient_check".localized).themeBody()
        }
        .toggleStyle(SwitchToggleStyle(tint: .themeYellow))
    }

    @ViewBuilder
    private func addressContent() -> some View {
        Text("address_checker.check_address".localized).textBody()
        Spacer()
        Image.disclosureIcon
    }
}
