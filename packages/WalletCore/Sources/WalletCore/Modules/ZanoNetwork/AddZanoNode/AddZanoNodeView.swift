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

                            InputTextRow {
                                PrimarySizedHStack {
                                    InputTextView(
                                        placeholder: "add_zano_node.node_url".localized,
                                        text: $viewModel.url
                                    )
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .keyboardType(.URL)
                                    .focused($focused)
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
                            .modifier(CautionBorder(cautionState: $viewModel.cautionState))
                            .modifier(CautionPrompt(cautionState: $viewModel.cautionState))
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
