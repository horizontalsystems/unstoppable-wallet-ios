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
                                    statEntity: .key
                                )
                                .focused($focusedField, equals: .text)
                                .modifier(CautionBorder(cautionState: $viewModel.textCaution))
                                .modifier(CautionPrompt(cautionState: $viewModel.textCaution))

                                ListSectionFooter(text: "watch_address.watch_data.description".localized)
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
                        viewModel.onProceed()
                    }
                    .disabled(!viewModel.state.watchEnabled)
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
                        viewModel.onProceed()
                    }
                    .disabled(!viewModel.state.watchEnabled)
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
}

extension WatchView {
    enum Field {
        case name
        case text
    }
}
