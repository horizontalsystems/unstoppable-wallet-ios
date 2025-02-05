import ComponentKit
import SwiftUI
import ThemeKit

struct AddressView: View {
    @StateObject var viewModel: AddressViewModel
    private var onFinish: (ResolvedAddress) -> Void

    @Environment(\.presentationMode) private var presentationMode

    init(wallet: Wallet, address: String? = nil, onFinish: @escaping (ResolvedAddress) -> Void) {
        _viewModel = StateObject(wrappedValue: AddressViewModel(wallet: wallet, address: address))
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
                        result: $viewModel.addressResult
                    )
                    .padding(.bottom, .margin12)

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
                                    checkView(title: type.title, state: viewModel.checkStates[type] ?? .notAvailable)
                                }
                            }
                        }
                        .themeListStyle(.bordered)
                        .padding(.top, .margin16)

                        let cautions = viewModel.issueTypes.filter { viewModel.checkStates[$0] == .detected }.map { $0.caution }

                        if !cautions.isEmpty {
                            VStack(spacing: .margin12) {
                                ForEach(cautions.indices, id: \.self) { index in
                                    HighlightedTextView(caution: cautions[index])
                                }
                            }
                            .padding(.top, .margin16)
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

    @ViewBuilder private func checkView(title: String, state: AddressViewModel.CheckState) -> some View {
        HStack(spacing: .margin8) {
            HStack(spacing: 2) {
                Text(title).textSubhead2()
                Image("crown_20").themeIcon(color: .themeJacob)
            }

            Spacer()

            switch state {
            case .checking:
                ProgressView()
            case .clear:
                Text("send.address.check.clear".localized).textSubhead2(color: .themeRemus)
            case .detected:
                Text("send.address.check.detected".localized).textSubhead2(color: .themeLucian)
            case .notAvailable:
                Text("n/a".localized).textSubhead2()
            case .locked:
                Image("lock_20").themeIcon()
            }
        }
        .padding(.horizontal, .margin16)
        .frame(minHeight: 40)
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
            title = "send.next_button".localized
            disabled = false
        }

        return (title, disabled, showProgress)
    }
}
