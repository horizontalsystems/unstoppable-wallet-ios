import RxSwift
import RxRelay
import RxCocoa

class SendXTimeLockErrorService {
    private let disposeBag = DisposeBag()

    private let timeLockService: SendXTimeLockService
    private let addressService: AddressService
    private let adapter: ISendBitcoinAdapter

    private let errorRelay = BehaviorRelay<Error?>(value: nil)
    private(set) var error: Error? = nil {
        didSet {
            errorRelay.accept(error)
        }
    }

    init(timeLockService: SendXTimeLockService, addressService: AddressService, adapter: ISendBitcoinAdapter) {
        self.timeLockService = timeLockService
        self.addressService = addressService
        self.adapter = adapter

        subscribe(disposeBag, timeLockService.pluginDataObservable) { [weak self] _ in
            self?.sync()
        }
        subscribe(disposeBag, addressService.stateObservable) { [weak self] _ in
            self?.sync()
        }
    }

    private func sync() {
        guard !timeLockService.pluginData.isEmpty,
              let address = addressService.state.address else {
            error = nil
            return
        }

        do {
            _ = try adapter.validate(address: address.raw, pluginData: timeLockService.pluginData)
            error = nil
        } catch {
            self.error = error.convertedError
        }
    }

}

extension SendXTimeLockErrorService: IErrorService {

    var errorObservable: Observable<Error?> {
        errorRelay.asObservable()
    }

}
