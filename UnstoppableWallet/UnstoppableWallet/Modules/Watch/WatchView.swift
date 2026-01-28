import SwiftUI

struct WatchView: View {
    @StateObject private var viewModel = WatchViewModel()
    @Binding var isPresented: Bool
    var onWatch: (() -> Void)? = nil

    @State private var path = NavigationPath()
    @FocusState private var focusedField: Field?

    var body: some View {
        ThemeNavigationStack(path: $path) {
            ThemeView {
                BottomGradientWrapper {
                    ScrollView {
                        VStack(spacing: .margin24) {
                            VStack(spacing: 0) {
                                ListSectionHeader(text: "watch_address.name".localized)

                                InputTextRow {
                                    InputTextView(
                                        placeholder: viewModel.defaultAccountName,
                                        text: $viewModel.name
                                    )
                                    .autocapitalization(.words)
                                    .autocorrectionDisabled()
                                    .focused($focusedField, equals: .name)
                                }
                            }

                            VStack(spacing: 0) {
                                LargeTextField(
                                    placeholder: "watch_address.watch_data.placeholder".localized,
                                    text: $viewModel.text,
                                    statPage: .watchWallet,
                                    statEntity: .key,
                                    onButtonTap: { focusedField = nil }
                                )
                                .focused($focusedField, equals: .text)
                                .modifier(CautionBorder(cautionState: $viewModel.textCaution))
                                .modifier(CautionPrompt(cautionState: $viewModel.textCaution))
                            }

                            ForEach(viewModel.requiredFields, id: \.self) { field in
                                VStack(spacing: 0) {
                                    switch field {
                                    case .viewKey:
                                        SingleLineLargeTextField(
                                            placeholder: "watch_address.view_key.placeholder".localized,
                                            text: $viewModel.viewKey,
                                            statPage: .watchWallet,
                                            statEntity: .viewKey,
                                            keyboardType: UIKeyboardType.asciiCapableNumberPad,
                                            onButtonTap: { focusedField = nil }
                                        )
                                        .focused($focusedField, equals: .viewKey)
                                        .modifier(CautionBorder(cautionState: $viewModel.viewKeyCaution))
                                        .modifier(CautionPrompt(cautionState: $viewModel.viewKeyCaution))
                                    }
                                }
                            }
                        }
                        .animation(.default, value: viewModel.text)
                        .animation(.default, value: viewModel.textCaution)
                        .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
                    }
                    .onTapGesture {
                        focusedField = nil
                    }
                } bottomContent: {
                    ThemeButton(text: "watch_address.watch".localized) {
                        proceed()
                    }
                }
            }
            .navigationTitle("watch_address.title".localized)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("button.cancel".localized) {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("watch_address.watch".localized) {
                        proceed()
                    }
                }
            }
            .onReceive(viewModel.itemsSubject) { items in
                path.append(items)
            }
            .onReceive(viewModel.successSubject) {
                HudHelper.instance.show(banner: .walletAdded)

                if let onWatch {
                    onWatch()
                } else {
                    isPresented = false
                }
            }
            .navigationDestination(for: WatchViewModel.Items.self) { items in
                WatchSelectView(items: items) { uids in
                    viewModel.watch(items: items, enabledUids: uids)
                }
            }
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
