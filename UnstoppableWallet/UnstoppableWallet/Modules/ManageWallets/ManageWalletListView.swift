import SwiftUI
import MarketKit

struct ManageWalletListView: View {
    @ObservedObject var viewModel: ManageWalletsViewModel2
    
    var body: some View {
        ThemeList(viewModel.items) { item in
            view(item: item, forceToggleOn: nil)
        }
    }
    
    @ViewBuilder private func view(item: ManageWalletsViewModel2.Item, forceToggleOn: Bool? = nil) -> some View {
        Cell(
            left: {
                CoinIconView(coin: item.token.coin)
            },
            middle: {
                MultiText(title: item.token.coin.code, badge: item.token.badge, subtitle: item.token.coin.name)
            },
            right: {
                HStack(spacing: .margin12) {
                    if item.hasInfo {
                        IconButton(icon: "info_filled", style: .secondary, mode: .transparent, size: .small) {
                            showInfo(item: item)
                        }
                    }

                    ThemeToggle(isOn: Binding(get: {
                        viewModel.enabledTokens[item.id] ?? false
                    }, set: { isEnabled in
                        viewModel.toggle(item: item, enabled: isEnabled)
                    }).animation(), style: .yellow)
                }
            }
        )
    }
    
    private func showInfo(item: ManageWalletsViewModel2.Item) {
        guard let infoItem = viewModel.showInfo(item: item) else {
            return
        }
        
        switch infoItem.type {
        case .derivation: showDerivation(coin: infoItem.token.coin)
        case let .birthdayHeight(height): showBirthdayHeight(coin: infoItem.token.coin, height: height)
        default: ()
            //        case .birthdayHeight(let coin, let height):
            //            showBirthdayHeightBottomSheet(coin: coin, height: height)
            //
            //        case .contractAddress(let coin, let blockchainImageUrl, let value, let explorerUrl):
            //            showContractBottomSheet(coin: coin, blockchainImageUrl: blockchainImageUrl, value: value, explorerUrl: explorerUrl)
            //        }
        }
    }

    private func showDerivation(coin: Coin) {
        Coordinator.shared.present(type: .bottomSheet) { isPresented in
            let coinName = coin.name
            BottomSheetView(items: [
                .title(icon: ComponentImage(url: coin.imageUrl), title: coin.code),
                .footer(text: "manage_wallets.derivation_description".localized(coinName, AppConfig.appName, coinName)),
                .buttonGroup(.init(buttons: [
                    .init(style: .gray, title: "button.close".localized) {
                        isPresented.wrappedValue = false
                    },
                ])),
            ])
        }
    }
        
    private func showBirthdayHeight(coin: Coin, height: Int) {
        Coordinator.shared.present(type: .bottomSheet) { isPresented in
            BottomSheetView(items: [
                .title(icon: ComponentImage(url: coin.imageUrl), title: coin.code),
                .list(items: [
                    .init(title: "birthday_height.title".localized, value: height.description)
                ]),
                .buttonGroup(.init(buttons: [
                    .init(style: .gray, title: "button.close".localized) {
                        isPresented.wrappedValue = false
                    },
                ])),
            ])
        }
    }

//
//        private func showContractBottomSheet(coin: Coin, blockchainImageUrl: String, value: String, explorerUrl: String?) {
//            Coordinator.shared.present(type: .bottomSheet) { isPresented in
//                BottomSheetView(
//                    image: .remote(url: coin.imageUrl, placeholder: coin.placeholderImageName),
//                    title: coin.code,
//                    subtitle: coin.name,
//                    items: [
//                        .contractAddress(imageUrl: blockchainImageUrl, value: value, explorerUrl: explorerUrl)
//                    ]
//                )
//            }
//        }
    
        
}




//        private func rootElement(index: Int, viewItem: ManageWalletsViewModel.ViewItem, forceToggleOn: Bool? = nil) -> CellBuilderNew.CellElement {
//            .hStack([
//                .image32 { component in
//                    component.imageView.setImage(coin: viewItem.coin, placeholder: viewItem.placeholderImageName)
//                },
//                .vStackCentered([
//                    .hStack([
//                        .textElement(text: .body(viewItem.coin.code), parameters: .highHugging),
//                        .margin8,
//                        .badge { component in
//                            component.isHidden = viewItem.badge == nil
//                            component.badgeView.set(style: .small)
//                            component.badgeView.text = viewItem.badge
//                        },
//                        .margin0,
//                        .text { _ in },
//                    ]),
//                    .margin(1),
//                    .textElement(text: .subhead2(viewItem.coin.name)),
//                ]),
//                .secondaryCircleButton { [weak self] component in
//                    component.isHidden = !viewItem.hasInfo
//                    component.button.set(image: UIImage(named: "circle_information_20"), style: .transparent)
//                    component.onTap = {
//                        self?.viewModel.onTapInfo(index: index)
//                    }
//                },
//                .switch { component in
//                    if let forceOn = forceToggleOn {
//                        component.switchView.setOn(forceOn, animated: true)
//                    } else {
//                        component.switchView.isOn = viewItem.enabled
//                    }
//
//                    component.onSwitch = { [weak self] enabled in
//                        self?.onToggle(index: index, enabled: enabled)
//                    }
//                },
//            ])
//        }
