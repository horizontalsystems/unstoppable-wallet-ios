import Combine
import Foundation
import MarketKit
import RxSwift

final class TransactionInfoViewModel: ObservableObject {
    private let disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()

    private let service: TransactionInfoService
    private let factory: TransactionInfoViewItemFactory
    private let adapter: ITransactionsAdapter

    @Published private(set) var sections: [TransactionInfoModule.SectionViewItem]

    init(service: TransactionInfoService, factory: TransactionInfoViewItemFactory, contactLabelService: ContactLabelService, adapter: ITransactionsAdapter) {
        self.service = service
        self.factory = factory
        self.adapter = adapter

        sections = factory.items(item: service.item, balanceHidden: service.balanceHidden)

        service.transactionItemUpdatedObserver
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in self?.update(item: $0) })
            .disposed(by: disposeBag)

        service.balanceHiddenObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in self?.reSyncServiceItem() })
            .disposed(by: disposeBag)

        contactLabelService.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.reSyncServiceItem() }
            .store(in: &cancellables)

        factory.updatedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.reSyncServiceItem() }
            .store(in: &cancellables)
    }

    private func reSyncServiceItem() {
        update(item: service.item)
    }

    private func update(item: TransactionInfoService.Item) {
        sections = factory.items(item: item, balanceHidden: service.balanceHidden)
    }
}

extension TransactionInfoViewModel {
    var rawTransaction: String? {
        service.rawTransaction()
    }

    private var transactionHash: String {
        service.item.record.transactionHash
    }

    private var transactionRecord: TransactionRecord {
        service.item.record
    }

    func togglePrice() {
        factory.priceReversed.toggle()
        reSyncServiceItem()

        stat(page: .transactionInfo, event: .togglePrice)
    }

    func resend(type: ResendTransactionType) {
        do {
            if let evmAdapter = adapter as? BaseEvmAdapter {
                try EvmResendModule.present(adapter: adapter, type: type, transactionHash: transactionHash)

                stat(page: .transactionInfo, event: .openResend(chainUid: evmAdapter.evmKitWrapper.blockchainType.uid, type: type.rawValue))
            } else if let btcAdapter = adapter as? BitcoinBaseAdapter, let transactionRecord = transactionRecord as? BitcoinOutgoingTransactionRecord {
                try ResendBitcoinModule.present(adapter: btcAdapter, type: type, transactionRecord: transactionRecord)

                stat(page: .transactionInfo, event: .openResend(chainUid: btcAdapter.token.blockchainType.uid, type: type.rawValue))
            }
        } catch {
            HudHelper.instance.show(banner: .error(string: error.localizedDescription))
        }
    }

    func zcashResend() {
        do {
            try ZcashResendModule.present(adapter: adapter, transactionRecord: transactionRecord) {
                HudHelper.instance.show(banner: .sent)
            }
        } catch {
            HudHelper.instance.show(banner: .error(string: error.localizedDescription))
        }
    }
}
