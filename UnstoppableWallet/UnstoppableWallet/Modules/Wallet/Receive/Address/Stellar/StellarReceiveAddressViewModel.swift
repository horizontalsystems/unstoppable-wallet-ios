import Combine
import Foundation
import SwiftUI

class StellarReceiveAddressViewModel: BaseReceiveAddressViewModel {
    private var cancellables = Set<AnyCancellable>()
    private let stellarService: StellarReceiveAddressService

    @Published private(set) var activated: DataStatus<Bool> = .loading

    init(service: StellarReceiveAddressService, viewItemFactory: StellarReceiveAddressViewItemFactory, decimalParser: AmountDecimalParser) {
        stellarService = service
        super.init(service: service, viewItemFactory: viewItemFactory, decimalParser: decimalParser)

        service.statusUpdatedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.sync(state: $0)
            }
            .store(in: &cancellables)

        sync(state: service.state)
    }

    private func sync(state: DataStatus<ReceiveAddress>) {
        activated = state.map { address in
            guard let address = address as? StellarReceiveAddressService.StellarAssetReceiveAddress else {
                return true
            }

            return address.activated
        }
    }

    var stellarSendData: SendData? {
        guard let adapter = stellarService.stellarAdapter else {
            return nil
        }

        return .stellar(data: .changeTrust(asset: adapter.asset, limit: StellarAdapter.maxValue), token: stellarService.wallet.token, memo: nil)
    }

    override func popupButtons(mode: ReceiveAddressModule.PopupWarningItem.Mode, isPresented: Binding<Bool>) -> [BottomSheetView.ButtonItem] {
        if mode is ActivateStellarAssetMode {
            return [
                .init(style: .yellow, title: "deposit.activate".localized) { [weak self] in
                    isPresented.wrappedValue = false

                    Coordinator.shared.present { isPresented in
                        if let sendData = self?.stellarSendData {
                            ThemeNavigationStack {
                                RegularSendView(sendData: sendData) {
                                    HudHelper.instance.show(banner: .sent)
                                    isPresented.wrappedValue = false
                                }
                            }
                        }
                    }
                },
                .init(style: .transparent, title: "button.later".localized) {
                    isPresented.wrappedValue = false
                },
            ]
        }

        return super.popupButtons(mode: mode, isPresented: isPresented)
    }
}

extension StellarReceiveAddressViewModel {
    class ActivateStellarAssetMode: ReceiveAddressModule.PopupWarningItem.Mode {}
}

extension ReceiveAddressModule.PopupWarningItem.Mode {
    static let activateStellarAsset = StellarReceiveAddressViewModel.ActivateStellarAssetMode()
}
