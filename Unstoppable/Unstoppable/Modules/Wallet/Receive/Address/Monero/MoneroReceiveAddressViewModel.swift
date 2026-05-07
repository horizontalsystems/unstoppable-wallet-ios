import Combine
import Foundation

class MoneroReceiveAddressViewModel: BaseReceiveAddressViewModel {
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var subAddresses: DataStatus<[UsedAddress]?> = .loading

    init(service: MoneroReceiveAddressService, viewItemFactory: ReceiveAddressViewItemFactory, decimalParser: AmountDecimalParser) {
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
        subAddresses = state.map { address in
            guard let address = address as? MoneroReceiveAddressService.MoneroAssetReceiveAddress else {
                return nil
            }

            return address.subAddresses
        }
    }
}
