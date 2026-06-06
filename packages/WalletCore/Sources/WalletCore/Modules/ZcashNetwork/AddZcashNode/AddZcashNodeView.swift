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

                            InputTextRow {
                                PrimarySizedHStack {
                                    InputTextView(
                                        placeholder: "add_zcash_node.node_url".localized,
                                        text: $viewModel.address
                                    )
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .keyboardType(.URL)
                                    .focused($focused)
                                } trailing: {
                                    ShortcutButtonsView(
                                        showDelete: .init(get: { !viewModel.address.isEmpty }, set: { _ in }),
                                        items: [.icon("scan"), .text("button.paste".localized)],
                                        onTap: { index in
                                            switch index {
                                            case 0:
                                                Coordinator.shared.present { isPresented in
                                                    ScanQrViewNew(isPresented: isPresented) { text in
                                                        viewModel.address = text.trimmingCharacters(in: .whitespacesAndNewlines)
                                                    }
                                                    .ignoresSafeArea()
                                                }
                                            case 1:
                                                if let string = UIPasteboard.general.string {
                                                    viewModel.address = string.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
                                                }
                                            default: ()
                                            }
                                        },
                                        onTapDelete: {
                                            viewModel.address = ""
                                        }
                                    )
                                }
                            }
                            .modifier(CautionBorder(cautionState: $viewModel.cautionState))
                            .modifier(CautionPrompt(cautionState: $viewModel.cautionState))
                        }
                        .padding(EdgeInsets(top: 12, leading: 16, bottom: 32, trailing: 16))
                    }
                    .onTapGesture { focused = false }
                } bottomContent: {
                    Button(action: {
                        viewModel.onTapAdd()
                    }) {
                        Text("button.add".localized)
                    }
                    .buttonStyle(PrimaryButtonStyle(style: .yellow))
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
