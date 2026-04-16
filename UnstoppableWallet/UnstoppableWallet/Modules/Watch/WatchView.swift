import SwiftUI

struct WatchView: View {
    @StateObject private var viewModel = WatchViewModel()
    @Binding var isParentPresented: Bool
    var showClose: Bool = false

    @FocusState private var focusedField: Field?

    @State private var selectItems: WatchViewModel.Items?
    @State private var selectPresented = false

    var body: some View {
        ThemeView {
            BottomGradientWrapper {
                ScrollView {
                    VStack(spacing: .margin24) {
                        VStack(spacing: 0) {
                            ListSectionHeader(text: "watch_address.name".localized)

                            InputTextRow {
                                ShortcutButtonsView(
                                    content: {
                                        InputTextView(text: $viewModel.name)
                                            .autocapitalization(.words)
                                            .autocorrectionDisabled()
                                            .focused($focusedField, equals: .name)
                                    },
                                    showDelete: .init(get: { false }, set: { _ in }),
                                    items: [.icon("swap_e")],
                                    onTap: { _ in
                                        viewModel.refreshName()
                                    },
                                    onTapDelete: {}
                                )
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
                .disabled(!viewModel.watchEnabled)
            }
        }
        .navigationTitle("watch_address.title".localized)
        .toolbar {
            if showClose {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        isParentPresented = false
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
            isParentPresented = false
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
