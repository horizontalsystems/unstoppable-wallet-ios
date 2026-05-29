import RxSwift

class TronRecipientAddressViewModel: RecipientAddressViewModel {
    private let sendService: SendTronService

    init(service: AddressService, handlerDelegate: IRecipientAddressService?, sendService: SendTronService) {
        self.sendService = sendService
        super.init(service: service, handlerDelegate: handlerDelegate)
    }

    override func sync(state: AddressService.State? = nil, customError: Error? = nil) {
        super.sync(state: state, customError: customError)

        if case let .success(address) = state {
            sendService.sync(address: address.raw)
        }
    }
}
