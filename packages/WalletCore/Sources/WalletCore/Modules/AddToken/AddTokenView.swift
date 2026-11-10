import SwiftUI

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
                    Button(action: {
                        isPresented = false
                    }) {
                        Image("close")
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
                    ThemeImage("blocks", size: .iconSize24)
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

    private var inputSection: some View {
        ThemeInput(
            caution: viewModel.cautionState,
            buttons: ThemeInputButton.shortcuts(
                isEmpty: viewModel.reference.isEmpty,
                whenEmpty: [
                    .scan(options: [.picker], identifier: TestTags.addTokenScan) { text in
                        viewModel.reference = text
                        stat(page: .addToken, event: .scanQr(entity: .token))
                    },
                    .paste(identifier: TestTags.addTokenPaste) { string in
                        viewModel.reference = string.pastedSingleLine
                        stat(page: .addToken, event: .paste(entity: .token))
                    },
                ],
                deleteIdentifier: TestTags.addTokenClear,
                onDelete: {
                    viewModel.reference = ""
                }
            )
        ) {
            InputTextView(
                placeholder: viewModel.placeholder,
                multiline: true,
                text: $viewModel.reference
            )
            .lineLimit(1 ... 3)
            .autocorrectionDisabled()
            .autocapitalization(.none)
            .accessibilityIdentifier(TestTags.addTokenInput)
            .modifier(RightChecking(state: checkingStateBinding))
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
