import MarketKit
import SwiftUI

struct AddEvmSyncSourceView: View {
    @StateObject private var viewModel: AddEvmSyncSourceViewModel
    @Binding private var isPresented: Bool

    @FocusState private var focusedField: Field?
    @State private var basicAuthSecureLock = true
    /// the masked field is a UIKit text field that @FocusState does not track
    @State private var basicAuthFocused = false

    init(blockchainType: BlockchainType, isPresented: Binding<Bool>) {
        _viewModel = .init(wrappedValue: AddEvmSyncSourceViewModel(blockchainType: blockchainType))
        _isPresented = isPresented
    }

    var body: some View {
        ThemeNavigationStack {
            ThemeView {
                BottomGradientWrapper {
                    ScrollView {
                        VStack(spacing: 0) {
                            ListSectionHeader(text: "add_evm_sync_source.rpc_url".localized)

                            ThemeInput(
                                caution: viewModel.urlCautionState,
                                buttons: ThemeInputButton.shortcuts(
                                    isEmpty: viewModel.url.isEmpty,
                                    whenEmpty: [
                                        .scan(identifier: TestTags.evmSourceUrlScan) { text in
                                            viewModel.url = text.trimmingCharacters(in: .whitespacesAndNewlines)
                                        },
                                        .paste(identifier: TestTags.evmSourceUrlPaste) { string in
                                            viewModel.url = string.pastedSingleLine
                                        },
                                    ],
                                    deleteIdentifier: TestTags.evmSourceUrlClear,
                                    onDelete: {
                                        viewModel.url = ""
                                    }
                                )
                            ) {
                                InputTextView(
                                    placeholder: "add_evm_sync_source.rpc_url".localized,
                                    text: $viewModel.url
                                )
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .keyboardType(.URL)
                                .focused($focusedField, equals: .url)
                                .accessibilityIdentifier(TestTags.evmSourceUrlInput)
                            }

                            ListSectionHeader(text: "add_evm_sync_source.basic_auth".localized)
                                .padding(.top, .margin24)

                            ThemeInput(
                                buttons: ThemeInputButton.shortcuts(
                                    isEmpty: viewModel.basicAuth.isEmpty,
                                    whenEmpty: [
                                        .paste(identifier: TestTags.evmSourceAuthPaste) { string in
                                            viewModel.basicAuth = string.pastedSingleLine
                                        },
                                    ],
                                    deleteIdentifier: TestTags.evmSourceAuthClear,
                                    onDelete: {
                                        viewModel.basicAuth = ""
                                    }
                                ) + [.secureToggle($basicAuthSecureLock, identifier: TestTags.evmSourceAuthEye)]
                            ) {
                                InputTextView(
                                    placeholder: "add_evm_sync_source.basic_auth".localized,
                                    text: $viewModel.basicAuth
                                )
                                .secure($basicAuthSecureLock, identifier: TestTags.evmSourceAuthInput, isFocused: $basicAuthFocused)
                            }
                        }
                        .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
                    }
                    .onTapGesture {
                        focusedField = nil
                        basicAuthFocused = false
                    }
                } bottomContent: {
                    ThemeButton(text: "button.add".localized) {
                        viewModel.onTapAdd()
                    }
                }
            }
            .navigationTitle("add_evm_sync_source.title".localized)
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

extension AddEvmSyncSourceView {
    private enum Field {
        case url
    }
}
