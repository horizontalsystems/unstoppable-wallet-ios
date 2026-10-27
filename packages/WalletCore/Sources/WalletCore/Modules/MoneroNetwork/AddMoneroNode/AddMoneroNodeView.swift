import MarketKit
import SwiftUI

struct AddMoneroNodeView: View {
    @StateObject private var viewModel: AddMoneroNodeViewModel
    @Binding private var isPresented: Bool

    @FocusState private var focusedField: Field?

    init(blockchainType: BlockchainType, isPresented: Binding<Bool>) {
        _viewModel = .init(wrappedValue: AddMoneroNodeViewModel(blockchainType: blockchainType))
        _isPresented = isPresented
    }

    var body: some View {
        ThemeNavigationStack {
            ThemeView {
                BottomGradientWrapper {
                    ScrollView {
                        VStack(spacing: 0) {
                            ListSectionHeader(text: "add_monero_node.node_url".localized)

                            InputTextRow {
                                PrimarySizedHStack {
                                    InputTextView(
                                        placeholder: "add_monero_node.node_url".localized,
                                        text: $viewModel.url
                                    )
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .keyboardType(.URL)
                                    .focused($focusedField, equals: .url)
                                } trailing: {
                                    ShortcutButtonsView(
                                        showDelete: .init(get: { !viewModel.url.isEmpty }, set: { _ in }),
                                        items: [.icon("scan"), .text("button.paste".localized)],
                                        onTap: { index in
                                            switch index {
                                            case 0:
                                                Coordinator.shared.present { isScanPresented in
                                                    ScanQrView(isPresented: isScanPresented) { text in
                                                        viewModel.url = text.trimmingCharacters(in: .whitespacesAndNewlines)
                                                    }
                                                    .ignoresSafeArea()
                                                }
                                            case 1:
                                                if let string = UIPasteboard.general.string {
                                                    viewModel.url = string.pastedSingleLine
                                                }
                                            default: ()
                                            }
                                        },
                                        onTapDelete: {
                                            viewModel.url = ""
                                        }
                                    )
                                }
                            }
                            .modifier(CautionBorder(cautionState: $viewModel.urlCautionState))
                            .modifier(CautionPrompt(cautionState: $viewModel.urlCautionState))

                            ListSectionHeader(text: "add_monero_node.login".localized)
                                .padding(.top, .margin24)

                            InputTextRow {
                                PrimarySizedHStack {
                                    InputTextView(
                                        placeholder: "add_monero_node.login".localized,
                                        text: $viewModel.login
                                    )
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .focused($focusedField, equals: .login)
                                } trailing: {
                                    ShortcutButtonsView(
                                        showDelete: .init(get: { !viewModel.login.isEmpty }, set: { _ in }),
                                        items: [.text("button.paste".localized)],
                                        onTap: { _ in
                                            if let string = UIPasteboard.general.string {
                                                viewModel.login = string.pastedSingleLine
                                            }
                                        },
                                        onTapDelete: {
                                            viewModel.login = ""
                                        }
                                    )
                                }
                            }

                            ListSectionHeader(text: "add_monero_node.password".localized)
                                .padding(.top, .margin32)

                            InputTextRow {
                                PrimarySizedHStack {
                                    InputTextView(
                                        placeholder: "add_monero_node.password".localized,
                                        text: $viewModel.password
                                    )
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .focused($focusedField, equals: .password)
                                } trailing: {
                                    ShortcutButtonsView(
                                        showDelete: .init(get: { !viewModel.password.isEmpty }, set: { _ in }),
                                        items: [.text("button.paste".localized)],
                                        onTap: { _ in
                                            if let string = UIPasteboard.general.string {
                                                viewModel.password = string.pastedSingleLine
                                            }
                                        },
                                        onTapDelete: {
                                            viewModel.password = ""
                                        }
                                    )
                                }
                            }
                        }
                        .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
                    }
                    .onTapGesture { focusedField = nil }
                } bottomContent: {
                    ThemeButton(text: "button.add".localized) {
                        viewModel.onTapAdd()
                    }
                }
            }
            .navigationTitle("add_monero_node.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { isPresented = false }) {
                        Image("close")
                    }
                }
            }
            .onReceive(viewModel.finishPublisher) { _ in
                isPresented = false
            }
            .onAppear { focusedField = .url }
        }
    }
}

extension AddMoneroNodeView {
    private enum Field {
        case url
        case login
        case password
    }
}
