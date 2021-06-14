import CoinKit
import RxSwift
import RxRelay

class ActiveWallet {
    let wallet: Wallet
    private let adapterProvider: IAdapterProvider
    private let disposeBag = DisposeBag()
    private var adapterDisposeBag = DisposeBag()

    private let adapterQueue: DispatchQueue
    private var _adapter: IAdapter?

    private let isMainNetField: Field<Bool>
    private let balanceDataField: Field<BalanceData>
    private let stateField: Field<AdapterState>

    init(wallet: Wallet, adapterProvider: IAdapterProvider) {
        self.wallet = wallet
        self.adapterProvider = adapterProvider

        adapterQueue = DispatchQueue(label: "io.horizontalsystems.unstoppable.active-wallet.\(wallet.coin.id)", qos: .userInitiated)

        isMainNetField = Field(value: true)
        balanceDataField = Field(value: BalanceData(balance: 0))
        stateField = Field(value: .syncing(progress: 10, lastBlockDate: nil))

        subscribe(disposeBag, adapterProvider.adapterInvalidatedObservable) { [weak self] in self?.reinitAdapter() }
    }

    deinit {
        adapterQueue.sync { _adapter?.stop() }
    }

    private func _initAdapter() {
        guard _adapter == nil else {
            return
        }

        do {
            _adapter = try adapterProvider.adapter()
        } catch {
            print("COULD NOT CREATE ADAPTER: \(error)")
            return
        }

        _adapter?.start()

        if let adapter = _adapter {
            isMainNetField.value = adapter.isMainNet
        }

        if let balanceAdapter = _adapter as? IBalanceAdapter {
            balanceDataField.value = balanceAdapter.balanceData
            stateField.value = balanceAdapter.balanceState

            subscribe(adapterDisposeBag, balanceAdapter.balanceDataUpdatedObservable) { [weak self] in
                self?.balanceDataField.value = $0
            }

            subscribe(adapterDisposeBag, balanceAdapter.balanceStateUpdatedObservable) { [weak self] in
                self?.stateField.value = $0
            }
        }
    }

    private func reinitAdapter() {
        adapterQueue.async { [weak self] in
            self?.adapterDisposeBag = DisposeBag()
            self?._adapter?.stop()
            self?._adapter = nil

            self?._initAdapter()
        }
    }

}

extension ActiveWallet {

    func initAdapter() {
        adapterQueue.async { [weak self] in self?._initAdapter() }
    }

    var statusInfo: [(String, Any)] {
        adapterQueue.sync { _adapter?.statusInfo ?? [] }
    }

    var adapter: IAdapter? {
        adapterQueue.sync { _adapter }
    }

    var transactionAdapter: ITransactionsAdapter? {
        adapterQueue.sync { _adapter as? ITransactionsAdapter }
    }

    var depositAdapter: IDepositAdapter? {
        adapterQueue.sync { _adapter as? IDepositAdapter }
    }

    var isMainNet: Bool {
        isMainNetField.value
    }

    var balanceData: BalanceData {
        balanceDataField.value
    }

    var state: AdapterState {
        stateField.value
    }

    var isMainNetObservable: Observable<Bool> {
        isMainNetField.observable
    }

    var balanceDataObservable: Observable<BalanceData> {
        balanceDataField.observable
    }

    var stateObservable: Observable<AdapterState> {
        stateField.observable
    }

    func refresh() {
        adapterQueue.sync { _adapter?.refresh() }
    }

}

extension ActiveWallet: Hashable {

    public static func ==(lhs: ActiveWallet, rhs: ActiveWallet) -> Bool {
        lhs.wallet == rhs.wallet
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(wallet)
    }

}
