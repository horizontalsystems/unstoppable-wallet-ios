import Combine
import Foundation

class HDReceiveAddressViewModel: BaseReceiveAddressViewModel {
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var usedAddresses: DataStatus<[AddressChain: [UsedAddress]]?> = .loading

    init(service: HDReceiveAddressService, viewItemFactory: ReceiveAddressViewItemFactory, decimalParser: AmountDecimalParser) {
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
        usedAddresses = state.map { address in
            guard let address = address as? HDReceiveAddressService.HDAssetReceiveAddress else {
                return nil
            }

            return address.usedAddresses
        }
    }
}

extension HDReceiveAddressViewModel {
    enum AddressChain: Int, Comparable {
        case external
        case change

        var title: String {
            switch self {
            case .external: return "receive_used_addresses.external".localized
            case .change: return "receive_used_addresses.change".localized
            }
        }

        static func < (lhs: AddressChain, rhs: AddressChain) -> Bool { lhs.rawValue < rhs.rawValue }
    }
}
