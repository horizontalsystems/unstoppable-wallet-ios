import Combine
import Foundation

class ZCashReceiveAddressViewModel: BaseReceiveAddressViewModel {
    private var cancellables = Set<AnyCancellable>()

    init(service: ZCashReceiveAddressService, viewItemFactory: ReceiveAddressViewItemFactory, decimalParser: AmountDecimalParser) {
        super.init(service: service, viewItemFactory: viewItemFactory, decimalParser: decimalParser)

        // TODO: check updates for singleUseAddresses if needed
    }
}
