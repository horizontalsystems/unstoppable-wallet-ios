import Combine
import Foundation
import SwiftUI

class TronReceiveAddressViewModel: BaseReceiveAddressViewModel {
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var activated: DataStatus<Bool> = .loading

    init(service: TronReceiveAddressService, viewItemFactory: TronReceiveAddressViewItemFactory, decimalParser: AmountDecimalParser) {
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
            guard let address = address as? TronReceiveAddressService.TronAssetReceiveAddress else {
                return true
            }

            return address.activated
        }
    }

    override func popupButtons(mode: ReceiveAddressModule.PopupWarningItem.Mode, isPresented: Binding<Bool>) -> [ButtonGroupViewModel.ButtonItem] {
        if let done = mode as? DoneMode {
            return [
                .init(style: .yellow, title: done.title) {
                    isPresented.wrappedValue = false
                },
            ]
        }
        return super.popupButtons(mode: mode, isPresented: isPresented)
    }
}

extension TronReceiveAddressViewModel {
    class DoneMode: ReceiveAddressModule.PopupWarningItem.Mode {
        let title: String

        init(title: String) {
            self.title = title
        }
    }
}

extension ReceiveAddressModule.PopupWarningItem.Mode {
    static func done(title: String) -> ReceiveAddressModule.PopupWarningItem.Mode { TronReceiveAddressViewModel.DoneMode(title: title) }
}
