import SwiftUI

// Sign request as a bottom sheet: dApp header, one bordered card of request rows, Reject | Sign
struct WCSignMessageSheetView: View {
    @StateObject private var viewModel: WCSignMessageViewModel
    @StateObject private var expirationViewModel: WCRequestExpirationViewModel
    @Binding private var isPresented: Bool

    init(item: WCRequestItem, isPresented: Binding<Bool>) {
        _viewModel = StateObject(wrappedValue: WCSignMessageViewModel(item: item))
        _expirationViewModel = StateObject(wrappedValue: WCRequestExpirationViewModel(request: item.request))
        _isPresented = isPresented
    }

    var body: some View {
        ThemeView(style: .list) {
            VStack(spacing: 0) {
                WCDAppTitleView(iconUrl: viewModel.iconUrl, title: "wallet_connect.sign.request_title".localized, showGrabber: true)
                BSModule.view(for: .subtitle(text: viewModel.dAppHost ?? viewModel.dAppName))

                ListSection {
                    ForEach(viewModel.rows) { row in
                        Cell(
                            style: .secondary,
                            middle: {
                                MiddleTextIcon(text: row.title)
                            },
                            right: {
                                RightTextIcon(text: ComponentText(text: row.value, colorStyle: .primary), icon: row.copyable ? "copy_filled" : nil)
                            },
                            action: row.copyable ? { CopyHelper.copyAndNotify(value: row.value) } : nil
                        )
                    }
                    Cell(
                        style: .secondary,
                        middle: {
                            MiddleTextIcon(text: "wallet_connect.sign.message".localized)
                        },
                        right: {
                            RightTextIcon(text: ComponentText(text: viewModel.message, colorStyle: .primary)).lineLimit(1)
                            Image.disclosureIcon
                        },
                        action: {
                            Coordinator.shared.present(type: .bottomSheet) { isPresented in
                                WCMessageSheetView(text: viewModel.message, isPresented: isPresented)
                            }
                        }
                    )
                    ForEach(viewModel.contextRows) { row in
                        Cell(
                            style: .secondary,
                            middle: {
                                MiddleTextIcon(text: row.title)
                            },
                            right: {
                                RightTextIcon(text: ComponentText(text: row.value, colorStyle: .primary), icon: row.copyable ? "copy_filled" : nil)
                            },
                            action: row.copyable ? { CopyHelper.copyAndNotify(value: row.value) } : nil
                        )
                    }
                }
                .themeListStyle(.borderedPlain)
                .padding(.horizontal, .margin16)
                .padding(.top, .margin8)

                ForEach(viewModel.cautions, id: \.self) { caution in
                    AlertCardView(caution: caution)
                        .padding(.horizontal, .margin16)
                        .padding(.top, .margin8)
                }

                HStack(spacing: .margin8) {
                    Button(action: {
                        viewModel.reject()
                        isPresented = false
                    }) {
                        Text("button.reject".localized)
                    }
                    .buttonStyle(PrimaryButtonStyle(style: .gray))
                    .disabled(viewModel.signing)

                    Button(action: { viewModel.sign() }) {
                        HStack(spacing: .margin8) {
                            if viewModel.signing { ProgressView().progressViewStyle(.circular) }
                            Text((expirationViewModel.isExpired && !viewModel.signing ? "wallet_connect.button.expired" : "button.sign").localized)
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle(style: .yellow))
                    .disabled(expirationViewModel.isExpired || !viewModel.signEnabled)
                }
                .padding(EdgeInsets(top: .margin24, leading: .margin24, bottom: .margin16, trailing: .margin24))
            }
        }
        .onReceive(viewModel.finishPublisher) {
            HudHelper.instance.show(banner: .done)
            isPresented = false
        }
        .onReceive(viewModel.errorPublisher) { error in
            HudHelper.instance.show(banner: .error(string: error))
        }
        .onDisappear { viewModel.rejectIfBlocked() }
        .interactiveDismissDisabled(viewModel.signing)
    }
}
