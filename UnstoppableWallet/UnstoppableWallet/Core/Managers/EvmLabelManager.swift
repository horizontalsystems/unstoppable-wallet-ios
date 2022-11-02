import Foundation
import RxSwift
import EvmKit

class EvmLabelManager {
    private let keyMethodLabelsTimestamp = "evm-label-manager-method-labels-timestamp"
    private let keyAddressLabelsTimestamp = "evm-label-manager-address-labels-timestamp"

    private let provider: HsLabelProvider
    private let storage: EvmLabelStorage
    private let syncerStateStorage: SyncerStateStorage
    private let disposeBag = DisposeBag()

    init(provider: HsLabelProvider, storage: EvmLabelStorage, syncerStateStorage: SyncerStateStorage) {
        self.provider = provider
        self.storage = storage
        self.syncerStateStorage = syncerStateStorage
    }

    private func syncMethodLabels(timestamp: Int) {
        if let rawLastSyncTimestamp = try? syncerStateStorage.value(key: keyMethodLabelsTimestamp), let lastSyncTimestamp = Int(rawLastSyncTimestamp), timestamp == lastSyncTimestamp {
            return
        }

        provider.evmMethodLabelsSingle()
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .subscribe(onSuccess: { [weak self] labels in
                    try? self?.storage.save(evmMethodLabels: labels)
                    self?.saveMethodLabels(timestamp: timestamp)
                }, onError: { error in
                    print("Method Labels sync error: \(error)")
                })
                .disposed(by: disposeBag)
    }

    private func syncAddressLabels(timestamp: Int) {
        if let rawLastSyncTimestamp = try? syncerStateStorage.value(key: keyAddressLabelsTimestamp), let lastSyncTimestamp = Int(rawLastSyncTimestamp), timestamp == lastSyncTimestamp {
            return
        }

        provider.evmAddressLabelsSingle()
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .subscribe(onSuccess: { [weak self] labels in
                    try? self?.storage.save(evmAddressLabels: labels)
                    self?.saveAddressLabels(timestamp: timestamp)
                }, onError: { error in
                    print("Address Labels sync error: \(error)")
                })
                .disposed(by: disposeBag)
    }

    private func saveMethodLabels(timestamp: Int) {
        try? syncerStateStorage.save(value: String(timestamp), key: keyMethodLabelsTimestamp)
    }

    private func saveAddressLabels(timestamp: Int) {
        try? syncerStateStorage.save(value: String(timestamp), key: keyAddressLabelsTimestamp)
    }

}

extension EvmLabelManager {

    func sync() {
        provider.updateStatusSingle()
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .subscribe(onSuccess: { [weak self] status in
                    self?.syncMethodLabels(timestamp: status.methodLabels)
                    self?.syncAddressLabels(timestamp: status.addressLabels)
                }, onError: { error in
                    print("Update Status sync error: \(error)")
                })
                .disposed(by: disposeBag)
    }

    func methodLabel(input: Data) -> String? {
        let methodId = Data(input.prefix(4)).hs.hexString
        return (try? storage.evmMethodLabel(methodId: methodId))?.label
    }

    func addressLabel(address: String) -> String? {
        (try? storage.evmAddressLabel(address: address.lowercased()))?.label
    }

    func mapped(address: String) -> String {
        if let label = addressLabel(address: address) {
            return label
        }

        return address.shortened
    }

}
