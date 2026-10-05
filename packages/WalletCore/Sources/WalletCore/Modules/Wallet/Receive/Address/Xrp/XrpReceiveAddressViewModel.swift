import Combine
import Foundation
import SwiftUI

class XrpReceiveAddressViewModel: BaseReceiveAddressViewModel {
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var activated: DataStatus<Bool> = .loading
    private var activationSendData: SendData?

    init(service: XrpReceiveAddressService, viewItemFactory: XrpReceiveAddressViewItemFactory) {
        super.init(service: service, viewItemFactory: viewItemFactory)

        service.statusUpdatedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.sync(state: $0)
            }
            .store(in: &cancellables)

        sync(state: service.state)
    }

    private func sync(state: DataStatus<ReceiveAddress>) {
        activationSendData = (state.data as? XrpReceiveAddressService.XrpAssetReceiveAddress)?.activationSendData

        activated = state.map { address in
            guard let address = address as? XrpReceiveAddressService.XrpAssetReceiveAddress else {
                return true
            }

            return address.activated
        }
    }

    override func popupButtons(mode: ReceiveAddressModule.PopupWarningItem.Mode, isPresented: Binding<Bool>) -> [ButtonGroupViewModel.ButtonItem] {
        if mode is ActivateXrpAssetMode {
            return [
                .init(style: .yellow, title: "deposit.activate".localized) { [weak self] in
                    isPresented.wrappedValue = false

                    Coordinator.shared.present { isPresented in
                        if let sendData = self?.activationSendData {
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

extension XrpReceiveAddressViewModel {
    class ActivateXrpAssetMode: ReceiveAddressModule.PopupWarningItem.Mode {}
}

extension ReceiveAddressModule.PopupWarningItem.Mode {
    static let activateXrpAsset = XrpReceiveAddressViewModel.ActivateXrpAssetMode()
}
