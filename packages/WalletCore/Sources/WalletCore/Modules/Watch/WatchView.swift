import SwiftUI

struct WatchView: View {
    @StateObject private var viewModel = WatchViewModel()
    @Binding var isPresented: Bool
    var parentPresented: Binding<Bool>?
    var showClose: Bool = false

    @FocusState private var focusedField: Field?

    @State private var selectItems: WatchViewModel.Items?
    @State private var selectPresented = false

    var body: some View {
        ThemeView {
            BottomGradientWrapper {
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 0) {
                            ListSectionHeader(text: "watch_address.name".localized, uppercased: false)

                            ThemeInput(
                                buttons: [
                                    .icon("swap_e", identifier: TestTags.watchNameRandom) {
                                        viewModel.refreshName()
                                    },
                                ]
                            ) {
                                InputTextView(text: $viewModel.name)
                                    .autocapitalization(.words)
                                    .autocorrectionDisabled()
                                    .focused($focusedField, equals: .name)
                                    .accessibilityIdentifier(TestTags.watchNameInput)
                            }
                        }

                        ThemeInput(
                            kind: .area,
                            caution: viewModel.textCaution,
                            buttons: ThemeInputButton.shortcuts(
                                isEmpty: viewModel.text.isEmpty,
                                whenEmpty: [
                                    .scan(options: [.picker], identifier: TestTags.watchScan) { text in
                                        viewModel.text = text
                                        focusedField = nil
                                        stat(page: .watchWallet, event: .scanQr(entity: .key))
                                    },
                                    .paste(identifier: TestTags.watchPaste) { string in
                                        viewModel.text = string
                                        focusedField = nil
                                        stat(page: .watchWallet, event: .paste(entity: .key))
                                    },
                                ],
                                deleteIdentifier: TestTags.watchClear,
                                onDelete: {
                                    viewModel.text = ""
                                    focusedField = nil
                                }
                            )
                        ) {
                            InputTextView(
                                placeholder: "watch_address.watch_data.placeholder".localized,
                                multiline: true,
                                text: $viewModel.text
                            )
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .text)
                            .accessibilityIdentifier(TestTags.watchInput)
                        }

                        ForEach(viewModel.requiredFields, id: \.self) { field in
                            VStack(spacing: 0) {
                                switch field {
                                case .viewKey:
                                    ThemeInput(
                                        caution: viewModel.viewKeyCaution,
                                        buttons: ThemeInputButton.shortcuts(
                                            isEmpty: viewModel.viewKey.isEmpty,
                                            whenEmpty: [
                                                .paste(identifier: TestTags.watchViewKeyPaste) { string in
                                                    viewModel.viewKey = string
                                                    focusedField = nil
                                                    stat(page: .watchWallet, event: .paste(entity: .viewKey))
                                                },
                                            ],
                                            deleteIdentifier: TestTags.watchViewKeyClear,
                                            onDelete: {
                                                viewModel.viewKey = ""
                                                focusedField = nil
                                            }
                                        )
                                    ) {
                                        InputTextView(
                                            placeholder: "watch_address.view_key.placeholder".localized,
                                            multiline: true,
                                            text: $viewModel.viewKey
                                        )
                                        .lineLimit(1 ... 3)
                                        .keyboardType(.asciiCapableNumberPad)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()
                                        .focused($focusedField, equals: .viewKey)
                                        .accessibilityIdentifier(TestTags.watchViewKeyInput)
                                    }
                                }
                            }
                        }
                    }
                    .animation(.default, value: viewModel.text)
                    .animation(.default, value: viewModel.textCaution)
                    .padding(EdgeInsets(top: 24, leading: 16, bottom: 32, trailing: 16))
                }
                .onTapGesture {
                    focusedField = nil
                }
            } bottomContent: {
                ThemeButton(text: "watch_address.watch".localized) {
                    proceed()
                }
                .disabled(!viewModel.watchEnabled)
                .accessibilityIdentifier(TestTags.watchSubmit)
            }
        }
        .navigationTitle("watch_address.title".localized)
        .toolbar {
            if showClose {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image("close")
                    }
                }
            }
        }
        .navigationDestination(isPresented: $selectPresented) {
            if let selectItems {
                WatchSelectView(items: selectItems) { uids in
                    viewModel.watch(items: selectItems, enabledUids: uids)
                }
            }
        }
        .onReceive(viewModel.itemsSubject) { items in
            selectItems = items
            selectPresented = true
        }
        .onReceive(viewModel.successSubject) {
            HudHelper.instance.show(banner: .walletAdded)
            (parentPresented ?? $isPresented).wrappedValue = false
        }
    }

    private func proceed() {
        if let blockchain = viewModel.birthdayHeightBlockchain {
            guard let provider = BirthdayInputProviderFactory.provider(blockchainType: blockchain.type) else {
                return
            }

            Coordinator.shared.present { _ in
                BirthdayInputView(blockchain: blockchain, provider: provider, onEnterBirthdayHeight: { height in
                    viewModel.birthdayHeight = height

                    DispatchQueue.main.async {
                        viewModel.onProceed()
                    }
                })
            }
        } else {
            viewModel.onProceed()
        }
    }
}

extension WatchView {
    enum Field {
        case name
        case text
        case viewKey
        case height
    }
}
