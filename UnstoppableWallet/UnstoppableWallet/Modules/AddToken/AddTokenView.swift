import SwiftUI
import UIKit

struct AddTokenView: View {
    @StateObject private var viewModel: AddTokenViewModel
    @Binding var isPresented: Bool

    @State private var path = NavigationPath()

    init(viewModel: AddTokenViewModel, isPresented: Binding<Bool>) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _isPresented = isPresented
    }

    var body: some View {
        ThemeNavigationStack(path: $path) {
            ThemeView {
                BottomGradientWrapper {
                    ScrollView {
                        VStack(spacing: .margin24) {
                            blockchainSection
                            inputSection
                            tokenInfoSection
                        }
                        .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
                    }
                } bottomContent: {
                    ThemeButton(text: "button.add".localized) {
                        viewModel.save()
                    }
                    .disabled(!viewModel.buttonEnabled)
                }
            }
            .navigationTitle("add_token.title".localized)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("button.cancel".localized) {
                        isPresented = false
                    }
                }
            }
            .onReceive(viewModel.finishPublisher) {
                HudHelper.instance.show(banner: .addedToWallet)
                isPresented = false
            }
        }
    }

    private var blockchainSection: some View {
        ListSection {
            Cell(
                left: {
                    Image("blocks_24").themeIcon()
                },
                middle: {
                    MultiText(title: "add_token.blockchain".localized)
                },
                right: {
                    RightTextIcon(text: viewModel.currentBlockchainItem.blockchain.name).arrow(style: .dropdown)
                },
                action: {
                    openBlockchainSelector()
                }
            )
        }
    }

    @ViewBuilder
    private var inputSection: some View {
        VStack(spacing: 0) {
            InputTextRow {
                ShortcutButtonsView(
                    content: {
                        TextField(
                            viewModel.placeholder,
                            text: $viewModel.reference,
                            axis: .vertical
                        )
                        .lineLimit(1 ... 3)
                        .font(.themeBody)
                        .tint(.themeInputFieldTintColor)
                        .autocorrectionDisabled()
                        .autocapitalization(.none)
                        .modifier(RightChecking(state: checkingStateBinding))
                    },
                    showDelete: .init(get: { !viewModel.reference.isEmpty }, set: { _ in }),
                    items: [.icon("scan"), .text("button.paste".localized)],
                    onTap: onTap,
                    onTapDelete: {
                        viewModel.reference = ""
                    }
                )
            }
            .modifier(CautionBorder(cautionState: cautionStateBinding))
            .modifier(CautionPrompt(cautionState: cautionStateBinding))
        }
    }

    private func onTap(_ index: Int) {
        switch index {
        case 0:
            Coordinator.shared.present { isPresented in
                ScanQrViewNew(options: [.picker], isPresented: isPresented) { text in
                    viewModel.reference = text
                    stat(page: .addToken, event: .scanQr(entity: .token))
                }
                .ignoresSafeArea()
            }
        default:
            if let string = UIPasteboard.general.string?.replacingOccurrences(of: "\n", with: " ") {
                viewModel.reference = string
                stat(page: .addToken, event: .paste(entity: .token))
            }
        }
    }

    @ViewBuilder
    private var tokenInfoSection: some View {
        if let viewItem = viewModel.viewItem {
            ListSection {
                ForEach(viewItem.fields, id: \.0) { field in
                    Cell(
                        middle: {
                            MiddleTextIcon(text: field.0)
                        },
                        right: {
                            RightTextIcon(text: field.1)
                        }
                    )
                }
            }
        }
    }

    private var cautionStateBinding: Binding<CautionState> {
        Binding(
            get: { viewModel.cautionState },
            set: { _ in }
        )
    }

    private var checkingStateBinding: Binding<RightChecking.State> {
        Binding(
            get: { viewModel.loading ? .loading : .idle },
            set: { _ in }
        )
    }

    private func openBlockchainSelector() {
        Coordinator.shared.present { isPresented in
            AddTokenBlockchainSelectView(
                viewModel: viewModel,
                isPresented: isPresented
            )
        }
    }
}
