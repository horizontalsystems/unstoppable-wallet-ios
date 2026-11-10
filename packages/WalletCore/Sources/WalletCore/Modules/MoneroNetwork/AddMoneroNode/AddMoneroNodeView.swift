import MarketKit
import SwiftUI

struct AddMoneroNodeView: View {
    @StateObject private var viewModel: AddMoneroNodeViewModel
    @Binding private var isPresented: Bool

    @FocusState private var focusedField: Field?
    @State private var passwordSecureLock = true
    /// the masked field is a UIKit text field that @FocusState does not track
    @State private var passwordFocused = false

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

                            ThemeInput(
                                caution: viewModel.urlCautionState,
                                buttons: ThemeInputButton.shortcuts(
                                    isEmpty: viewModel.url.isEmpty,
                                    whenEmpty: [
                                        .scan(identifier: TestTags.moneroNodeUrlScan) { text in
                                            viewModel.url = text.trimmingCharacters(in: .whitespacesAndNewlines)
                                        },
                                        .paste(identifier: TestTags.moneroNodeUrlPaste) { string in
                                            viewModel.url = string.pastedSingleLine
                                        },
                                    ],
                                    deleteIdentifier: TestTags.moneroNodeUrlClear,
                                    onDelete: {
                                        viewModel.url = ""
                                    }
                                )
                            ) {
                                InputTextView(
                                    placeholder: "add_monero_node.node_url".localized,
                                    text: $viewModel.url
                                )
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .keyboardType(.URL)
                                .focused($focusedField, equals: .url)
                                .accessibilityIdentifier(TestTags.moneroNodeUrlInput)
                            }

                            ListSectionHeader(text: "add_monero_node.login".localized)
                                .padding(.top, .margin24)

                            ThemeInput(
                                buttons: ThemeInputButton.shortcuts(
                                    isEmpty: viewModel.login.isEmpty,
                                    whenEmpty: [
                                        .paste(identifier: TestTags.moneroNodeLoginPaste) { string in
                                            viewModel.login = string.pastedSingleLine
                                        },
                                    ],
                                    deleteIdentifier: TestTags.moneroNodeLoginClear,
                                    onDelete: {
                                        viewModel.login = ""
                                    }
                                )
                            ) {
                                InputTextView(
                                    placeholder: "add_monero_node.login".localized,
                                    text: $viewModel.login
                                )
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .login)
                                .accessibilityIdentifier(TestTags.moneroNodeLoginInput)
                            }

                            ListSectionHeader(text: "add_monero_node.password".localized)
                                .padding(.top, .margin32)

                            ThemeInput(
                                buttons: ThemeInputButton.shortcuts(
                                    isEmpty: viewModel.password.isEmpty,
                                    whenEmpty: [
                                        .paste(identifier: TestTags.moneroNodePasswordPaste) { string in
                                            viewModel.password = string.pastedSingleLine
                                        },
                                    ],
                                    deleteIdentifier: TestTags.moneroNodePasswordClear,
                                    onDelete: {
                                        viewModel.password = ""
                                    }
                                ) + [.secureToggle($passwordSecureLock, identifier: TestTags.moneroNodePasswordEye)]
                            ) {
                                InputTextView(
                                    placeholder: "add_monero_node.password".localized,
                                    text: $viewModel.password
                                )
                                .secure($passwordSecureLock, identifier: TestTags.moneroNodePasswordInput, isFocused: $passwordFocused)
                            }
                        }
                        .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
                    }
                    .onTapGesture {
                        focusedField = nil
                        passwordFocused = false
                    }
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
    }
}
