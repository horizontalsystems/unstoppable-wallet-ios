import Combine
import Foundation
import MarketKit
import RxSwift

class SendViewModelNew: ObservableObject {
    private let wallet: Wallet
    private let currencyManager = App.shared.currencyManager
    private let marketKit = App.shared.marketKit
    private let walletManager = App.shared.walletManager
    private let adapterManager = App.shared.adapterManager

    private var cancellables = Set<AnyCancellable>()
    private var rateInCancellable: AnyCancellable?
    private var balanceDisposeBag = DisposeBag()

    @Published var currency: Currency

    var amountIn: Decimal? {
        didSet {
            syncFiatAmountIn()

            let amount = Decimal(string: amountString)

            if amount != amountIn {
                amountString = amountIn?.description ?? ""
            }
        }
    }

    @Published var amountString: String = "" {
        didSet {
            var amount = Decimal(string: amountString)

            if amount == 0 {
                amount = nil
            }

            guard amount != amountIn else {
                return
            }

            enteringFiat = false

            amountIn = amount
        }
    }

    @Published var fiatAmountIn: Decimal? {
        didSet {
            syncAmountIn()

            let amount = Decimal(string: fiatAmountString)?.rounded(decimal: 2)

            if amount != fiatAmountIn {
                fiatAmountString = fiatAmountIn?.description ?? ""
            }
        }
    }

    @Published var fiatAmountString: String = "" {
        didSet {
            let amount = Decimal(string: fiatAmountString)?.rounded(decimal: 2)

            guard amount != fiatAmountIn else {
                return
            }

            enteringFiat = true

            fiatAmountIn = amount
        }
    }

    @Published var rateIn: Decimal? {
        didSet {
            syncFiatAmountIn()
        }
    }

    @Published var adapterState: AdapterState?
    @Published var availableBalance: Decimal?

    private var enteringFiat = false

    @Published var address: String = ""
    @Published var addressResult: AddressInput.Result = .idle
    @Published var addressCautionState: CautionState = .none

    @Published var isAddressActive: Bool = false {
        didSet {
            if isAddressActive {
                addressCautionState = .none
            } else {
                syncAddressCautionState()
            }
        }
    }

    init(wallet: Wallet) {
        self.wallet = wallet

        currency = currencyManager.baseCurrency

        currencyManager.$baseCurrency.sink { [weak self] in self?.currency = $0 }.store(in: &cancellables)
        rateIn = marketKit.coinPrice(coinUid: wallet.coin.uid, currencyCode: currency.code)?.value
        rateInCancellable = marketKit.coinPricePublisher(coinUid: wallet.coin.uid, currencyCode: currency.code)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] price in self?.rateIn = price.value }

        if let adapter = adapterManager.balanceAdapter(for: wallet) {
            adapterState = adapter.balanceState
            availableBalance = adapter.balanceData.available

            adapter.balanceStateUpdatedObservable
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe { [weak self] state in
                    self?.adapterState = state
                }
                .disposed(by: balanceDisposeBag)

            adapter.balanceDataUpdatedObservable
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe { [weak self] balanceData in
                    self?.availableBalance = balanceData.available
                }
                .disposed(by: balanceDisposeBag)
        } else {
            adapterState = nil
            availableBalance = nil
        }

        syncFiatAmountIn()
    }

    private func syncAmountIn() {
        guard enteringFiat else {
            return
        }

        guard let rateIn, let fiatAmountIn else {
            amountIn = nil
            return
        }

        amountIn = fiatAmountIn / rateIn
    }

    private func syncFiatAmountIn() {
        guard !enteringFiat else {
            return
        }

        guard let rateIn, let amountIn else {
            fiatAmountIn = nil
            return
        }

        fiatAmountIn = (amountIn * rateIn).rounded(decimal: 2)
    }

    private func syncAddressCautionState() {
        guard !isAddressActive else {
            addressCautionState = .none
            return
        }

        switch addressResult {
        case let .invalid(failure): addressCautionState = .caution(.init(text: failure.error.localizedDescription, type: .error))
        default: addressCautionState = .none
        }
    }
}

extension SendViewModelNew {
    var token: Token {
        wallet.token
    }

    func setAmountIn(percent: Int) {
        guard let availableBalance else {
            return
        }

        enteringFiat = false

        amountIn = availableBalance * Decimal(percent) / 100
    }

    func clearAmountIn() {
        enteringFiat = false
        amountIn = nil
    }

    func changeAddressFocus(active: Bool) {
        isAddressActive = active
    }
}
