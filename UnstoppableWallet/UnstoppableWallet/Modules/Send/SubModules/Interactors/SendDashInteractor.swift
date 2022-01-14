import RxSwift
import HsToolKit

class SendDashInteractor {
    weak var delegate: ISendDashInteractorDelegate?

    private let adapter: ISendDashAdapter
    private let transactionDataSortModeSettingsManager: ITransactionDataSortModeSettingManager

    init(adapter: ISendDashAdapter, transactionDataSortModeSettingsManager: ITransactionDataSortModeSettingManager) {
        self.adapter = adapter
        self.transactionDataSortModeSettingsManager = transactionDataSortModeSettingsManager
    }

}

extension SendDashInteractor: ISendDashInteractor {

    func fetchAvailableBalance(address: String?) {
        DispatchQueue.global(qos: .userInitiated).async {
            let balance = self.adapter.availableBalance(address: address)

            DispatchQueue.main.async {
                self.delegate?.didFetch(availableBalance: balance)
            }
        }
    }

    func fetchMinimumAmount(address: String?) {
        DispatchQueue.global(qos: .userInitiated).async {
            let amount = self.adapter.minimumSendAmount(address: address)

            DispatchQueue.main.async {
                self.delegate?.didFetch(minimumAmount: amount)
            }
        }
    }

    func fetchFee(amount: Decimal, address: String?) {
        DispatchQueue.global(qos: .userInitiated).async {
            let fee = self.adapter.fee(amount: amount, address: address)

            DispatchQueue.main.async {
                self.delegate?.didFetch(fee: fee)
            }
        }
    }

    func sendSingle(amount: Decimal, address: String, logger: Logger) -> Single<Void> {
        adapter.sendSingle(amount: amount, address: address, sortMode: transactionDataSortModeSettingsManager.setting, logger: logger)
    }

}
