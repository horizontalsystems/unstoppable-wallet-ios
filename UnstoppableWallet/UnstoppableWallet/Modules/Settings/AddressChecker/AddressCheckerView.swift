import SwiftUI

struct AddressCheckerView: View {
    @StateObject var viewModel = AddressCheckerViewModel()

    var body: some View {
        ScrollableThemeView {
            VStack(spacing: .margin24) {
                VStack(spacing: 0) {
                    ListSection {
                        ListRow {
                            Toggle(isOn: $viewModel.recipientAddressCheck.animation()) {
                                Text("address_checker.recipient_check".localized).themeBody()
                            }
                            .toggleStyle(SwitchToggleStyle(tint: .themeYellow))
                        }
                    }

                    ListSectionFooter(text: "address_checker.recipient_check.description".localized)
                }

                VStack(spacing: 0) {
                    ListSection {
                        NavigationRow(spacing: .margin8, destination: {
                            CheckAddressView()
                                .onFirstAppear {
                                    stat(page: .addressChecker, event: .open(page: .checkAddress))
                                }
                        }) {
                            Text("address_checker.check_address".localized).textBody()
                            Spacer()
                            Image.disclosureIcon
                        }
                    }

                    ListSectionFooter(text: "address_checker.check_address.description".localized)
                }
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
        .navigationTitle("address_checker.title".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}
