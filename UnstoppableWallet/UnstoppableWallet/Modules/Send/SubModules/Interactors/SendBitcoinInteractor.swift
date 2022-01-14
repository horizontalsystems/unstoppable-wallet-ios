import Foundation
import RxSwift
import HsToolKit

class SendBitcoinInteractor {
    weak var delegate: ISendBitcoinInteractorDelegate?

    private let adapter: ISendBitcoinAdapter
    private let transactionDataSortModeSettingsManager: ITransactionDataSortModeSettingManager
    private let localStorage: ILocalStorage

    init(adapter: ISendBitcoinAdapter, transactionDataSortModeSettingsManager: ITransactionDataSortModeSettingManager, localStorage: ILocalStorage) {
        self.adapter = adapter
        self.transactionDataSortModeSettingsManager = transactionDataSortModeSettingsManager
        self.localStorage = localStorage
    }

}

extension SendBitcoinInteractor: ISendBitcoinInteractor {

    var balance: Decimal {
        adapter.balanceData.balance
    }

    var lockTimeEnabled: Bool {
        localStorage.lockTimeEnabled
    }

    func fetchAvailableBalance(feeRate: Int, address: String?, pluginData: [UInt8: IBitcoinPluginData]) {
        DispatchQueue.global(qos: .userInitiated).async {
            let balance = self.adapter.availableBalance(feeRate: feeRate, address: address, pluginData: pluginData)

            DispatchQueue.main.async {
                self.delegate?.didFetch(availableBalance: balance)
            }
        }
    }

    func fetchMaximumAmount(pluginData: [UInt8: IBitcoinPluginData] = [:]) {
        DispatchQueue.global(qos: .userInitiated).async {
            let amount = self.adapter.maximumSendAmount(pluginData: pluginData)

            DispatchQueue.main.async {
                self.delegate?.didFetch(maximumAmount: amount)
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

    func fetchFee(amount: Decimal, feeRate: Int, address: String?, pluginData: [UInt8: IBitcoinPluginData]) {
        DispatchQueue.global(qos: .userInitiated).async {
            let fee = self.adapter.fee(amount: amount, feeRate: feeRate, address: address, pluginData: pluginData)

            DispatchQueue.main.async {
                self.delegate?.didFetch(fee: fee)
            }
        }
    }

    func sendSingle(amount: Decimal, address: String, feeRate: Int, pluginData: [UInt8: IBitcoinPluginData], logger: Logger) -> Single<Void> {
        adapter.sendSingle(amount: amount, address: address, feeRate: feeRate, pluginData: pluginData, sortMode: transactionDataSortModeSettingsManager.setting, logger: logger)
    }

}
