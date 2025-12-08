import MarketKit
import SwiftUI

struct AddressView: View {
    @StateObject private var viewModel: AddressViewModel
    @StateObject private var defenseViewModel: SendDefenseSystemViewModel

    private let buttonTitle: String
    private let onFinish: (ResolvedAddress) -> Void

    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.addressParserFilter) private var parserFilter

    var borderColor: Color {
        switch viewModel.addressResult {
        case .invalid: return .themeLucian
        default: return .themeBlade
        }
    }

    init(token: Token, buttonTitle: String, destination: AddressViewModel.Destination, address: String? = nil, onFinish: @escaping (ResolvedAddress) -> Void) {
        _viewModel = StateObject(wrappedValue: AddressViewModel(
            token: token,
            destination: destination,
            address: address
        ))
        _defenseViewModel = StateObject(wrappedValue: SendDefenseSystemViewModel(
            token: token,
            destination: destination
        ))

        self.buttonTitle = buttonTitle
        self.onFinish = onFinish
    }

    var body: some View {
        BottomGradientWrapper {
            ScrollView {
                VStack(spacing: 0) {
                    AddressViewNew(
                        initial: .init(
                            blockchainType: viewModel.token.blockchainType,
                            showContacts: true
                        ),
                        text: $viewModel.address,
                        result: $viewModel.addressResult,
                        parserFilter: parserFilter,
                        borderColor: Binding(get: { borderColor }, set: { _ in })
                    )
                    .padding(.bottom, .margin12)

                    if case let .invalid(caution) = viewModel.state, let caution {
                        VStack(spacing: .margin12) {
                            HighlightedTextView(caution: caution)
                        }
                        .padding(.top, .margin16)
                    } else {
                        switch viewModel.state {
                        case .empty, .invalid:
                            if let recentContact = viewModel.recentContact {
                                ListSectionHeader2(text: "send.address.recent".localized)
                                ListSection {
                                    row(contact: recentContact)
                                }
                                .themeListStyle(.bordered)
                            }

                            if !viewModel.contacts.isEmpty {
                                ListSectionHeader2(text: "send.address.contacts".localized)
                                ListSection {
                                    ForEach(viewModel.contacts) { row(contact: $0) }
                                }
                                .themeListStyle(.bordered)
                            }
                        case .valid:
                            SendDefenseSystemView(viewModel: defenseViewModel)
                                .padding(.top, .margin16)
                        }
                    }
                }
                .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin16, trailing: .margin16))
            }
        } bottomContent: {
            let (title, disabled, showProgress) = buttonState()

            Button(action: {
                handleFinish()
            }) {
                HStack(spacing: .margin8) {
                    if showProgress {
                        ProgressView()
                    }

                    Text(title)
                }
            }
            .disabled(disabled)
            .buttonStyle(PrimaryButtonStyle(style: .yellow))
        }
        .onChange(of: viewModel.state) { newState in
            if case let .valid(address) = newState {
                defenseViewModel.set(address: address)
            } else {
                defenseViewModel.reset()
            }
        }
    }

    @ViewBuilder private func row(contact: AddressViewModel.Contact) -> some View {
        ClickableRow {
            viewModel.address = contact.address
        } content: {
            if let name = contact.name {
                VStack(spacing: 1) {
                    Text(name).themeBody()
                    Text(contact.address.shortened).themeSubhead2()
                }
            } else {
                Text(contact.address).themeBody()
            }
        }
    }

    private func handleFinish() {
        guard case let .valid(address) = viewModel.state else {
            return
        }

        let resolvedAddress = ResolvedAddress(
            address: address.raw,
            issueTypes: defenseViewModel.detectedIssueTypes
        )

        onFinish(resolvedAddress)
    }

    private func buttonState() -> (String, Bool, Bool) {
        let title: String
        var disabled = true
        var showProgress = false

        switch viewModel.state {
        case .empty:
            title = "send.address.enter_address".localized
        case .invalid:
            title = "send.address.invalid_address".localized
        case .valid:
            if defenseViewModel.isChecking {
                title = "send.address.checking".localized
                disabled = true
                showProgress = true
            } else {
                title = buttonTitle
                disabled = false
            }
        }

        return (title, disabled, showProgress)
    }
}

private struct AddressParserFilterKey: EnvironmentKey {
    static let defaultValue: AddressParserFactory.ParserFilter? = nil
}

extension EnvironmentValues {
    var addressParserFilter: AddressParserFactory.ParserFilter? {
        get { self[AddressParserFilterKey.self] }
        set { self[AddressParserFilterKey.self] = newValue }
    }
}
