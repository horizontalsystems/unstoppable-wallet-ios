import SwiftUI

struct WCNSignMessageView: View {
    @StateObject private var viewModel: WCNSignMessageViewModel
    @State private var path = NavigationPath()
    @Environment(\.presentationMode) private var presentationMode

    private enum Route: Hashable {
        case message
    }

    init(item: WCNRequestItem) {
        _viewModel = StateObject(wrappedValue: WCNSignMessageViewModel(item: item))
    }

    var body: some View {
        ThemeNavigationStack(path: $path) {
            ThemeView {
                BottomGradientWrapper {
                    ScrollView {
                        VStack(spacing: 0) {
                            WCNDAppTitleView(iconUrl: viewModel.iconUrl, title: "wallet_connect.sign.request_title".localized)
                            BSModule.view(for: .subtitle(text: viewModel.dAppHost ?? viewModel.dAppName))

                            ListSection {
                                ForEach(viewModel.rows) { row in
                                    Cell(
                                        middle: {
                                            MiddleTextIcon(text: row.title)
                                        },
                                        right: {
                                            RightTextIcon(text: ComponentText(text: row.value, colorStyle: .primary), icon: row.copyable ? "copy_20" : nil)
                                        },
                                        action: row.copyable ? { CopyHelper.copyAndNotify(value: row.value) } : nil
                                    )
                                }
                                Cell(
                                    middle: {
                                        MiddleTextIcon(text: "wallet_connect.sign.message".localized)
                                    },
                                    right: {
                                        RightTextIcon(text: ComponentText(text: viewModel.message, colorStyle: .primary)).lineLimit(1)
                                        Image.disclosureIcon
                                    },
                                    action: { path.append(Route.message) }
                                )
                            }
                            .themeListStyle(.bordered)
                            .padding(.horizontal, .margin16)
                            .padding(.vertical, .margin8)

                            ForEach(viewModel.cautions, id: \.self) { caution in
                                BSModule.view(for: .highlightedDescription(text: caution.text, type: .init(cautionType: caution.type), style: .inline))
                            }
                        }
                        .padding(.bottom, .margin32)
                    }
                } bottomContent: {
                    HStack(spacing: .margin8) {
                        Button(action: {
                            viewModel.reject()
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("button.reject".localized)
                        }
                        .buttonStyle(PrimaryButtonStyle(style: .gray))

                        Button(action: { viewModel.sign() }) {
                            HStack(spacing: .margin8) {
                                if viewModel.signing { ProgressView().progressViewStyle(.circular) }
                                Text("button.sign".localized)
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle(style: .yellow))
                        .disabled(!viewModel.signEnabled)
                    }
                }
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .message: WCNMessageView(text: viewModel.message)
                }
            }
            .onReceive(viewModel.finishPublisher) {
                HudHelper.instance.show(banner: .done)
                presentationMode.wrappedValue.dismiss()
            }
            .onReceive(viewModel.errorPublisher) { error in
                HudHelper.instance.show(banner: .error(string: error))
            }
            .onDisappear { viewModel.rejectIfBlocked() }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        viewModel.reject()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image("close")
                    }
                }
            }
        }
    }
}
