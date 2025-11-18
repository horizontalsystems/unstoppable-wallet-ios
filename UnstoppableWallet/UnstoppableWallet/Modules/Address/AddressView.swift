
import MarketKit
import SwiftUI

struct AddressView: View {
    @StateObject var viewModel: AddressViewModel
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
        _viewModel = StateObject(wrappedValue: AddressViewModel(token: token, destination: destination, address: address))
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
                        case .checking, .valid:
                            ListSection {
                                VStack(spacing: 0) {
                                    ForEach(viewModel.issueTypes) { type in
                                        checkView(title: type.checkTitle, checkDescription: type.description, state: viewModel.checkStates[type] ?? .notAvailable)
                                    }
                                }
                            }
                            .themeListStyle(.bordered)
                            .padding(.top, .margin16)

                            let cautions = viewModel.issueTypes.filter { viewModel.checkStates[$0] == .detected }.map(\.caution)

                            if !cautions.isEmpty {
                                VStack(spacing: .margin16) {
                                    ForEach(cautions.indices, id: \.self) { index in
                                        HighlightedTextView(caution: cautions[index])
                                    }
                                }
                                .padding(.top, .margin16)
                            }
                        }
                    }
                }
                .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin16, trailing: .margin16))
            }
        } bottomContent: {
            let (title, disabled, showProgress) = buttonState()

            Button(action: {
                guard case let .valid(resolvedAddress) = viewModel.state else {
                    return
                }

                onFinish(resolvedAddress)
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

    @ViewBuilder private func checkView(title: String, checkDescription: InfoDescription, state: AddressViewModel.CheckState) -> some View {
        HStack(spacing: .margin8) {
            HStack(spacing: .margin8) {
                Image("star_premium_20").themeIcon(color: .themeJacob)
                Text(title).textSubhead2()
            }

            Spacer()

            switch state {
            case .checking:
                ProgressView()
            case .clear:
                HStack(spacing: .margin8) {
                    Text("send.address.check.clear".localized).textSubhead2(color: .themeRemus)
                }
            case .detected:
                Text("send.address.check.detected".localized).textSubhead2(color: .themeLucian)
            case .notAvailable:
                Text("n/a".localized).textSubhead2()
            case .locked:
                Image("lock_20").themeIcon()
            case .disabled:
                Text("send.address.check.disabled".localized).textSubhead2(color: .themeLeah)
            }
        }
        .padding(.horizontal, .margin16)
        .frame(minHeight: 40)
        .contentShape(Rectangle())
        .onTapGesture {
            switch state {
            case .locked:
                Coordinator.shared.presentPurchase(page: viewModel.destination.sourceStatPage, trigger: .addressChecker)
            default:
                Coordinator.shared.present(info: checkDescription)
            }
        }
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
        case .checking:
            title = "send.address.checking".localized
            showProgress = true
        case .valid:
            title = buttonTitle
            disabled = false
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
