import Foundation
import RxCocoa
import RxRelay
import RxSwift

class SendAmountCautionService {
    private let disposeBag = DisposeBag()
    private var availableBalanceDisposeBag = DisposeBag()

    private let amountInputService: IAmountInputService
    weak var availableBalanceService: IAvailableBalanceService? {
        didSet {
            setAvailableBalanceService()
        }
    }

    weak var sendAmountBoundsService: ISendXSendAmountBoundsService?

    private let amountCautionRelay = BehaviorRelay<Caution?>(value: nil)
    private(set) var amountCaution: Caution? {
        didSet {
            amountCautionRelay.accept(amountCaution)
        }
    }

    init(amountInputService: IAmountInputService) {
        self.amountInputService = amountInputService

        subscribe(disposeBag, amountInputService.amountObservable) { [weak self] _ in self?.sync() }
    }

    private func setAvailableBalanceService() {
        availableBalanceDisposeBag = DisposeBag()
        if let availableBalanceService {
            subscribe(availableBalanceDisposeBag, availableBalanceService.availableBalanceObservable) { [weak self] _ in
                self?.sync()
            }
        }
    }

    private func sync() {
        let amount = amountInputService.amount
        guard !amount.isZero else {
            amountCaution = nil
            return
        }
        if let availableBalance = availableBalanceService?.availableBalance.data,
           availableBalance < amount
        {
            amountCaution = .insufficientBalance(availableBalance: availableBalance)
            return
        }
        if let maximumAmount = sendAmountBoundsService?.maximumSendAmount,
           maximumAmount < amount
        {
            amountCaution = .maximumAmountExceeded(maximumAmount: maximumAmount)
            return
        }
        if let minimumAmount = sendAmountBoundsService?.minimumSendAmount,
           minimumAmount > amount
        {
            amountCaution = .tooFewAmount(minimumAmount: minimumAmount)
            return
        }

        amountCaution = nil
    }
}

extension SendAmountCautionService {
    var amountCautionObservable: Observable<Caution?> {
        amountCautionRelay.asObservable()
    }
}

extension SendAmountCautionService {
    enum Caution {
        case insufficientBalance(availableBalance: Decimal)
        case maximumAmountExceeded(maximumAmount: Decimal)
        case tooFewAmount(minimumAmount: Decimal)

        var value: Decimal {
            switch self {
            case let .insufficientBalance(value): return value
            case let .maximumAmountExceeded(value): return value
            case let .tooFewAmount(value): return value
            }
        }
    }
}
