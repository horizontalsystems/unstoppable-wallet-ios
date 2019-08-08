//import RxSwift
//
//class SendInteractor {
//    private let disposeBag = DisposeBag()
//    private var validateDisposable: Disposable?
//    private var feeDisposable: Disposable?
//
//    weak var delegate: ISendInteractorDelegate?
//
//    private let pasteboardManager: IPasteboardManager
//    private let adapter: IAdapter
//    private let async: Bool
//
//    init(pasteboardManager: IPasteboardManager, adapter: IAdapter, backgroundManager: BackgroundManager, async: Bool = true) {
//        self.pasteboardManager = pasteboardManager
//        self.adapter = adapter
//        self.async = async
//
//        backgroundManager.didBecomeActiveSubject.subscribe(onNext: { [weak self] in
//            self?.delegate?.onBecomeActive()
//        }).disposed(by: disposeBag)
//    }
//
//}
//
//extension SendInteractor: ISendInteractor {
//
//    var coin: Coin {
//        return adapter.wallet.coin
//    }
//
//    var decimal: Int {
//        return adapter.decimal
//    }
//
//    func availableBalance(params: [String: Any]) throws -> Decimal {
//        return try adapter.availableBalance(params: params)
//    }
//
//    func copy(address: String) {
//        pasteboardManager.set(value: address)
//    }
//
//    func parse(paymentAddress: String) -> PaymentRequestAddress {
//        fatalError()
////        return adapter.parse(paymentAddress: paymentAddress)
//    }
//
//    func updateFee(params: [String: Any]) {
//        feeDisposable?.dispose()
//
//        var single = Single<Decimal>.create { observer in
//            do {
//                let fee = try self.adapter.fee(params: params)
//                observer(.success(fee))
//            } catch {
//                observer(.error(error))
//            }
//            return Disposables.create()
//        }
//        if async {
//            single = single.subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
//                    .observeOn(MainScheduler.instance)
//        }
//        feeDisposable = single.subscribe(onSuccess: { [weak self] fee in
//            self?.delegate?.didUpdate(fee: fee)
//        }, onError: { error in
//            // request with wrong parameters!
//        })
//    }
//
//    func feeRate(priority: FeeRatePriority) -> Int {
//        fatalError()
////        return adapter.feeRate(priority: priority)
//    }
//
//    func validate(params: [String: Any]) {
//        validateDisposable?.dispose()
//
//        var single = Single<[SendStateError]>.create { observer in
//            do {
//                let errors = try self.adapter.validate(params: params)
//                observer(.success(errors))
//            } catch {
//                observer(.error(error))
//            }
//            return Disposables.create()
//        }
//        if async {
//            single = single.subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
//                    .observeOn(MainScheduler.instance)
//        }
//        validateDisposable = single.subscribe(onSuccess: { [weak self] errors in
//            self?.delegate?.didValidate(with: errors)
//        }, onError: { error in
//            // request with wrong parameters!
//        })
//    }
//
//    func send(params: [String: Any]) {
//        var single = adapter.sendSingle(params: params)
//        if async {
//            single = single.subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
//                    .observeOn(MainScheduler.instance)
//        }
//        single.subscribe(onSuccess: { [weak self] in
//                    self?.delegate?.didSend()
//                }, onError: { [weak self] error in
//                    self?.delegate?.didFailToSend(error: error)
//                })
//                .disposed(by: disposeBag)
//    }
//
//}
