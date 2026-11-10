import MarketKit
import SwiftUI

struct AddZanoNodeView: View {
    @StateObject private var viewModel: AddZanoNodeViewModel
    @Binding private var isPresented: Bool

    @FocusState private var focused: Bool

    init(blockchainType: BlockchainType, isPresented: Binding<Bool>) {
        _viewModel = .init(wrappedValue: AddZanoNodeViewModel(blockchainType: blockchainType))
        _isPresented = isPresented
    }

    var body: some View {
        ThemeNavigationStack {
            ThemeView {
                BottomGradientWrapper {
                    ScrollView {
                        VStack(spacing: 0) {
                            ListSectionHeader(text: "add_zano_node.node_url".localized)

                            ThemeInput(
                                caution: viewModel.cautionState,
                                buttons: ThemeInputButton.shortcuts(
                                    isEmpty: viewModel.url.isEmpty,
                                    whenEmpty: [
                                        .scan(identifier: TestTags.zanoNodeUrlScan) { text in
                                            viewModel.url = text.trimmingCharacters(in: .whitespacesAndNewlines)
                                        },
                                        .paste(identifier: TestTags.zanoNodeUrlPaste) { string in
                                            viewModel.url = string.pastedSingleLine
                                        },
                                    ],
                                    deleteIdentifier: TestTags.zanoNodeUrlClear,
                                    onDelete: {
                                        viewModel.url = ""
                                    }
                                )
                            ) {
                                InputTextView(
                                    placeholder: "add_zano_node.node_url".localized,
                                    text: $viewModel.url
                                )
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .keyboardType(.URL)
                                .focused($focused)
                                .accessibilityIdentifier(TestTags.zanoNodeUrlInput)
                            }
                        }
                        .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
                    }
                    .onTapGesture { focused = false }
                } bottomContent: {
                    ThemeButton(text: "button.add".localized) {
                        viewModel.onTapAdd()
                    }
                }
            }
            .navigationTitle("add_zano_node.title".localized)
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
            .onAppear { focused = true }
        }
    }
}
