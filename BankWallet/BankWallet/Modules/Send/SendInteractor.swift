import RxSwift

class SendInteractor {
    enum SendError: Error {
        case noAddress
        case noAmount
    }

    private let disposeBag = DisposeBag()
    private var validateDisposable: Disposable?
    private var feeDisposable: Disposable?

    weak var delegate: ISendInteractorDelegate?

    private let currencyManager: ICurrencyManager
    private let rateStorage: IRateStorage
    private let localStorage: ILocalStorage
    private let pasteboardManager: IPasteboardManager
    private let appConfigProvider: IAppConfigProvider
    private let state: SendInteractorState
    private let async: Bool

    init(currencyManager: ICurrencyManager, rateStorage: IRateStorage, localStorage: ILocalStorage, pasteboardManager: IPasteboardManager, state: SendInteractorState, appConfigProvider: IAppConfigProvider, backgroundManager: BackgroundManager, async: Bool = true) {
        self.currencyManager = currencyManager
        self.rateStorage = rateStorage
        self.localStorage = localStorage
        self.pasteboardManager = pasteboardManager
        self.appConfigProvider = appConfigProvider
        self.state = state
        self.async = async

        backgroundManager.didBecomeActiveSubject.subscribe(onNext: { [weak self] in
            self?.delegate?.onBecomeActive()
        }).disposed(by: disposeBag)
    }

}

extension SendInteractor: ISendInteractor {

    func availableBalance(params: [String: Any]) throws -> Decimal {
        return try state.adapter.availableBalance(params: params)
    }

    var coin: Coin {
        return state.adapter.wallet.coin
    }

    func parse(paymentAddress: String) -> PaymentRequestAddress {
        return state.adapter.parse(paymentAddress: paymentAddress)
    }

    func updateFee(params: [String: Any]) {
        feeDisposable?.dispose()

        var single = Single<Decimal>.create { observer in
            do {
                let fee = try self.state.adapter.fee(params: params)
                observer(.success(fee))
            } catch {
                observer(.error(error))
            }
            return Disposables.create()
        }
        if async {
            single = single.subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                    .observeOn(MainScheduler.instance)
        }
        feeDisposable = single.subscribe(onSuccess: { [weak self] fee in
            self?.delegate?.didUpdate(fee: fee)
        }, onError: { error in
            // request with wrong parameters!
        })
    }

    func validate(params: [String: Any]) {
        validateDisposable?.dispose()

        var single = Single<[SendStateError]>.create { observer in
            do {
                let errors = try self.state.adapter.validate(params: params)
                observer(.success(errors))
            } catch {
                observer(.error(error))
            }
            return Disposables.create()
        }
        if async {
            single = single.subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                    .observeOn(MainScheduler.instance)
        }
        validateDisposable = single.subscribe(onSuccess: { [weak self] errors in
            self?.delegate?.didValidate(with: errors)
        }, onError: { error in
            // request with wrong parameters!
        })
    }

    func copy(address: String) {
        pasteboardManager.set(value: address)
    }

    func send(userInput: SendUserInput) {
        guard let address = userInput.address else {
            delegate?.didFailToSend(error: SendError.noAddress)
            return
        }

        var computedAmount: Decimal?

        if userInput.inputType == .coin {
            computedAmount = userInput.amount
        } else if let rateValue = state.exchangeRate?.value {
            computedAmount = userInput.amount / rateValue
        }

        guard let amount = computedAmount else {
            delegate?.didFailToSend(error: SendError.noAmount)
            return
        }

        var params = [String: Any]()
        params[AdapterFields.amount.rawValue] = amount
        params[AdapterFields.address.rawValue] = userInput.address
        params[AdapterFields.feeRateRriority.rawValue] = userInput.feeRatePriority

        var single = state.adapter.sendSingle(params: params)
        if async {
            single = single.subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                    .observeOn(MainScheduler.instance)
        }
        single.subscribe(onSuccess: { [weak self] in
                    self?.delegate?.didSend()
                }, onError: { [weak self] error in
                    self?.delegate?.didFailToSend(error: error)
                })
                .disposed(by: disposeBag)
    }

}
