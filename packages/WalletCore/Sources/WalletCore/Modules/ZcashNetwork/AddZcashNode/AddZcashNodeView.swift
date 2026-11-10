import MarketKit
import SwiftUI

struct AddZcashNodeView: View {
    @StateObject private var viewModel: AddZcashNodeViewModel
    @Binding private var isPresented: Bool

    @FocusState private var focused: Bool

    init(blockchainType: BlockchainType, isPresented: Binding<Bool>) {
        _viewModel = .init(wrappedValue: AddZcashNodeViewModel(blockchainType: blockchainType))
        _isPresented = isPresented
    }

    var body: some View {
        ThemeNavigationStack {
            ThemeView {
                BottomGradientWrapper {
                    ScrollView {
                        VStack(spacing: 0) {
                            ListSectionHeader(text: "add_zcash_node.node_url".localized)

                            ThemeInput(
                                caution: viewModel.cautionState,
                                buttons: ThemeInputButton.shortcuts(
                                    isEmpty: viewModel.address.isEmpty,
                                    whenEmpty: [
                                        .scan(identifier: TestTags.zcashNodeUrlScan) { text in
                                            viewModel.address = text.trimmingCharacters(in: .whitespacesAndNewlines)
                                        },
                                        .paste(identifier: TestTags.zcashNodeUrlPaste) { string in
                                            viewModel.address = string.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
                                        },
                                    ],
                                    deleteIdentifier: TestTags.zcashNodeUrlClear,
                                    onDelete: {
                                        viewModel.address = ""
                                    }
                                )
                            ) {
                                InputTextView(
                                    placeholder: "add_zcash_node.node_url".localized,
                                    text: $viewModel.address
                                )
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .keyboardType(.URL)
                                .focused($focused)
                                .accessibilityIdentifier(TestTags.zcashNodeUrlInput)
                            }
                        }
                        .padding(EdgeInsets(top: 12, leading: 16, bottom: 32, trailing: 16))
                    }
                    .onTapGesture { focused = false }
                } bottomContent: {
                    ThemeButton(text: "button.add".localized) {
                        viewModel.onTapAdd()
                    }
                }
            }
            .navigationTitle("add_zcash_node.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { isPresented = false }) {
                        Text("button.cancel".localized)
                    }
                }
            }
            .onReceive(viewModel.finishPublisher) { _ in
                isPresented = false
            }
            .onAppear { focused = true }
        }
    }
}
