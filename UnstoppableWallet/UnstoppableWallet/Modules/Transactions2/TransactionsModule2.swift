import CurrencyKit
import UIKit
import RxSwift

struct TransactionsModule2 {

    static let pageLimit = 10

    static func instance() -> UIViewController {
        let service = TransactionsService(
                walletManager: App.shared.walletManager,
                adapterManager: App.shared.transactionAdapterManager
        )
        let viewModel = TransactionsViewModel(service: service, factory: TransactionsViewItemFactory())
        let viewController = TransactionsViewController2(viewModel: viewModel)

        return viewController
    }

    enum TypeFilter: String, CaseIterable {
        case all, incoming, outgoing, swap, approve
    }

    struct Item {
        let record: TransactionRecord
        var lastBlockInfo: LastBlockInfo?
        var currencyValue: CurrencyValue?
    }

    struct ViewItem {
        let uid: String
        let date: Date
        let typeImage: ColoredImage
        let progress: Float?
        let title: String
        let subTitle: String
        let primaryValue: ColoredValue?
        let secondaryValue: ColoredValue?
        let sentToSelf: Bool
        let locked: Bool?
    }

}

struct ColoredValue {
    let value: String
    let color: UIColor
}

struct ColoredImage {
    let imageName: String
    let color: UIColor
}

protocol ITransactionRecordService {
    var recordsObservable: Observable<[TransactionRecord]> { get }
    var updatedRecordObservable: Observable<TransactionRecord>  { get }
    func load(count: Int, reload: Bool)
    func set(typeFilter: TransactionsModule2.TypeFilter)
}
