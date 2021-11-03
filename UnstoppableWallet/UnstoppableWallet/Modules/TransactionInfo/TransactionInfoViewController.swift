import UIKit
import ActionSheet
import ThemeKit
import SectionsTableView
import CurrencyKit
import ComponentKit
import RxSwift
import SafariServices

class TransactionInfoViewController: ThemeViewController {
    private let disposeBag = DisposeBag()

    private let viewModel: TransactionInfoViewModel
    private let pageTitle: String
    private var urlManager: IUrlManager
    private let adapter: ITransactionsAdapter

    private var viewItems = [[TransactionInfoModule.ViewItem]]()

    private let tableView = SectionsTableView(style: .grouped)

    init(adapter: ITransactionsAdapter, viewModel: TransactionInfoViewModel, pageTitle: String, urlManager: IUrlManager) {
        self.adapter = adapter
        self.viewModel = viewModel
        self.pageTitle = pageTitle
        self.urlManager = urlManager

        viewItems = viewModel.viewItems

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = pageTitle
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onTapCloseButton))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.registerCell(forClass: A1Cell.self)
        tableView.registerCell(forClass: B7Cell.self)
        tableView.registerCell(forClass: D6Cell.self)
        tableView.registerCell(forClass: D7Cell.self)
        tableView.registerCell(forClass: D7MultiLineCell.self)
        tableView.registerCell(forClass: D9Cell.self)
        tableView.registerCell(forClass: D10Cell.self)
        tableView.registerCell(forClass: D10SecondaryCell.self)
        tableView.registerCell(forClass: CMultiLineCell.self)
        tableView.registerCell(forClass: C4MultiLineCell.self)
        tableView.registerCell(forClass: C6Cell.self)
        tableView.registerCell(forClass: C24Cell.self)
        tableView.sectionDataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        subscribe(disposeBag, viewModel.viewItemsDriver) { [weak self] viewItems in
            self?.viewItems = viewItems
            self?.tableView.reload()
        }

        tableView.reload()
    }

    @objc private func onTapCloseButton() {
        dismiss(animated: true)
    }

    private func openStatusInfo() {
        let viewController = TransactionStatusInfoViewController()
        present(ThemeNavigationController(rootViewController: viewController), animated: true)
    }

    private func openResend(action: TransactionInfoModule.Option) {
        do {
            let viewController = try SendEvmConfirmationModule.resendViewController(adapter: adapter, action: action, transactionHash: viewModel.transactionHash)
            present(ThemeNavigationController(rootViewController: viewController), animated: true)
        } catch {
            HudHelper.instance.showError(title: error.localizedDescription)
        }
    }


    private func pendingStatusCell(rowInfo: RowInfo, progress: Double, label: String) -> RowProtocol {
        Row<C24Cell>(
                id: "status",
                hash: "pending-\(progress)-\(label)",
                height: .heightCell48,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)
                    cell.titleImage = UIImage(named: "circle_information_20")?.withTintColor(.themeJacob)
                    cell.titleImageAction = { [weak self] in
                        self?.openStatusInfo()
                    }
                    cell.title = "status".localized
                    cell.value = label
                    cell.valueColor = .themeLeah
                    cell.set(progress: progress)
                }
        )
    }

    private func statusRow(rowInfo: RowInfo, status: TransactionStatus) -> RowProtocol {
        let statusText: String
        switch status {
        case .pending: statusText = "transactions.pending".localized
        case .processing: statusText = "transactions.processing".localized
        case .completed: statusText = "transactions.completed".localized
        case .failed: statusText = "transactions.failed".localized
        }

        switch status {
        case .completed:
            return Row<D6Cell>(
                    id: "status",
                    hash: "completed",
                    height: .heightCell48,
                    bind: { cell, _ in
                        cell.set(backgroundStyle: .lawrence, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)
                        cell.title = "status".localized
                        cell.value = statusText
                        cell.valueImage = UIImage(named: "check_1_20")?.withRenderingMode(.alwaysTemplate)
                        cell.valueImageTintColor = .themeRemus
                        cell.selectionStyle = .none
                    }
            )
        case .failed:
            return Row<C6Cell>(
                    id: "status",
                    hash: "failed",
                    height: .heightCell48,
                    bind: { cell, _ in
                        cell.set(backgroundStyle: .lawrence, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)
                        cell.title = "status".localized
                        cell.titleImage = UIImage(named: "circle_information_20")?.withTintColor(.themeJacob)
                        cell.value = statusText
                        cell.valueImage = UIImage(named: "warning_2_20")?.withRenderingMode(.alwaysTemplate)
                        cell.valueImageTintColor = .themeLucian
                        cell.titleImageAction = { [weak self] in
                            self?.openStatusInfo()
                        }
                    }
            )

        case .pending:
            return pendingStatusCell(rowInfo: rowInfo, progress: 0.2, label: statusText)
        case .processing(let progress):
            return pendingStatusCell(rowInfo: rowInfo, progress: progress * 0.8 + 0.2, label: statusText)
        }
    }

    private func optionsRow(viewItems: [TransactionInfoModule.OptionViewItem]) -> RowProtocol {
        Row<D10SecondaryCell>(
                id: "options",
                hash: "options",
                height: .heightCell48,
                autoDeselect: true,
                bind: { [weak self] cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: false, isLast: false)
                    cell.title = "Options"
                    cell.set(viewItems: viewItems.map { D10SecondaryCell.ViewItem(title: $0.title, enabled: $0.active) })
                    cell.onTapButton = { index in
                        if viewItems.count > index {
                            self?.openResend(action: viewItems[index].option)
                        }
                    }
                }
        )
    }

    private func fromToRow(rowInfo: RowInfo, title: String, value: String) -> RowProtocol {
        Row<D9Cell>(
                id: title,
                hash: value,
                height: .heightCell48,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)
                    cell.title = title
                    if let title = TransactionInfoAddressMapper.title(value: value) {
                        cell.viewItem = .init(type: .title(text: title), value: { value })
                    } else {
                        cell.viewItem = .init(type: .raw, value: { value })
                    }
                }
        )
    }

    private func fromRow(rowInfo: RowInfo, value: String) -> RowProtocol {
        fromToRow(rowInfo: rowInfo, title: "tx_info.from_hash".localized, value: value)
    }

    private func toRow(rowInfo: RowInfo, value: String) -> RowProtocol {
        fromToRow(rowInfo: rowInfo, title: "tx_info.to_hash".localized, value: value)
    }

    private func recipientRow(rowInfo: RowInfo, value: String) -> RowProtocol {
        fromToRow(rowInfo: rowInfo, title: "tx_info.recipient_hash".localized, value: value)
    }

    private func idRow(rowInfo: RowInfo, value: String) -> RowProtocol {
        Row<D10Cell>(
                id: "transaction_id",
                hash: value,
                height: .heightCell48,
                bind: { [weak self] cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)
                    cell.title = "tx_info.transaction_id".localized
                    cell.viewItem = .init(type: .raw, value: { value })
                    cell.set(iconButtonImage: UIImage(named: "share_1_20"))
                    cell.onTapIconButton = { [weak self] in
                        let activityViewController = UIActivityViewController(activityItems: [value], applicationActivities: [])
                        self?.present(activityViewController, animated: true)
                    }
                }
        )
    }

    private func valueRow(rowInfo: RowInfo, title: String, value: String?, valueItalic: Bool = false) -> RowProtocol {
        Row<D7Cell>(
                id: title,
                hash: value ?? "",
                height: .heightCell48,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)
                    cell.title = title
                    cell.value = value
                    cell.valueColor = .themeLeah
                    cell.valueItalic = valueItalic
                }
        )
    }

    private func multiLineValueRow(rowInfo: RowInfo, title: String, value: String?, valueItalic: Bool = false) -> RowProtocol {
        Row<D7MultiLineCell>(
                id: title,
                hash: value ?? "",
                dynamicHeight: { width in
                    D7MultiLineCell.height(containerWidth: width, backgroundStyle: .lawrence, title: title, value: value, valueItalic: valueItalic)
                },
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)
                    cell.title = title
                    cell.value = value
                    cell.valueColor = .themeLeah
                    cell.valueItalic = valueItalic
                }
        )
    }

    private func feeRow(rowInfo: RowInfo, title: String, value: String) -> RowProtocol {
        valueRow(
                rowInfo: rowInfo,
                title: title,
                value: value
        )
    }

    private func warningRow(rowInfo: RowInfo, id: String, image: UIImage?, text: String, onTapButton: @escaping () -> ()) -> RowProtocol {
        Row<C4MultiLineCell>(
                id: id,
                hash: text,
                autoDeselect: true,
                dynamicHeight: { containerWidth in
                    C4MultiLineCell.height(containerWidth: containerWidth, backgroundStyle: .lawrence, title: text)
                },
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)
                    cell.titleImage = image?.withTintColor(.themeGray)
                    cell.title = text
                    cell.valueImage = UIImage(named: "circle_information_20")?.withRenderingMode(.alwaysTemplate)
                    cell.valueImageTintColor = .themeGray
                },
                action: { _ in
                    onTapButton()
                }
        )
    }

    private func doubleSpendRow(rowInfo: RowInfo, txHash: String, conflictingTxHash: String) -> RowProtocol {
        warningRow(
                rowInfo: rowInfo,
                id: "double_spend",
                image: UIImage(named: "double_send_20"),
                text: "tx_info.double_spent_note".localized
        ) { [weak self] in
            let module = DoubleSpendInfoRouter.module(txHash: txHash, conflictingTxHash: conflictingTxHash)
            self?.present(module, animated: true)
        }
    }

    private func lockInfoRow(rowInfo: RowInfo, lockState: TransactionLockState) -> RowProtocol {
        let id = "lock_info"
        let image = UIImage(named: lockState.locked ? "lock_20" : "unlock_20")
        let formattedDate = DateHelper.instance.formatFullTime(from: lockState.date)

        if lockState.locked {
            return warningRow(rowInfo: rowInfo, id: id, image: image, text: "tx_info.locked_until".localized(formattedDate)) { [weak self] in
                let controller = InfoModule.viewController(dataSource: TimeLockInfoDataSource())
                self?.present(ThemeNavigationController(rootViewController: controller), animated: true)
            }
        } else {
            return noteRow(rowInfo: rowInfo, id: id, image: image, imageTintColor: .themeGray, text: "tx_info.unlocked_at".localized(formattedDate))
        }
    }

    private func noteRow(rowInfo: RowInfo, id: String, image: UIImage?, imageTintColor: UIColor, text: String) -> RowProtocol {
        Row<CMultiLineCell>(
                id: id,
                hash: text,
                dynamicHeight: { containerWidth in
                    CMultiLineCell.height(containerWidth: containerWidth, backgroundStyle: .lawrence, title: text)
                },
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)
                    cell.titleImage = image?.withTintColor(imageTintColor)
                    cell.title = text
                }
        )
    }

    private func sentToSelfRow(rowInfo: RowInfo) -> RowProtocol {
        noteRow(
                rowInfo: rowInfo,
                id: "sent_to_self",
                image: UIImage(named: "arrow_medium_main_down_left_20")?.withRenderingMode(.alwaysTemplate),
                imageTintColor: .themeRemus,
                text: "tx_info.to_self_note".localized
        )
    }

    private func rawTransactionRow(rowInfo: RowInfo) -> RowProtocol {
        Row<D9Cell>(
                id: "raw_transaction",
                height: .heightCell48,
                bind: { [weak self] cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)
                    cell.title = "tx_info.raw_transaction".localized
                    cell.viewItem = .init(type: .image, value: { [weak self] in self?.viewModel.rawTransaction ?? "" })
                }
        )
    }

    private func explorerRow(rowInfo: RowInfo, title: String, url: String?) -> RowProtocol {
        Row<A1Cell>(
                id: "explorer_row",
                hash: "explorer_row",
                height: .heightCell48,
                autoDeselect: true,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)
                    cell.title = title
                    cell.titleImage = UIImage(named: "globe_20")
                },
                action: { [weak self] _ in
                    guard let url = url else {
                        return
                    }

                    self?.urlManager.open(url: url, from: self)
                }
        )
    }

    private func actionTitleRow(rowInfo: RowInfo, title: String, value: String) -> RowProtocol {
        Row<B7Cell>(
                id: "action_\(rowInfo.index)",
                hash: "action_\(value)",
                height: .heightCell48,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)
                    cell.title = title
                    cell.value = value
                    cell.valueColor = .themeGray
                }
        )
    }

    private func amountRow(rowInfo: RowInfo, coinAmount: String, currencyAmount: String?, incoming: Bool?) -> RowProtocol {
        Row<D7Cell>(
                id: "amount_\(rowInfo.index)",
                hash: "amount_\(coinAmount)",
                height: .heightCell48,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)
                    cell.title = coinAmount
                    cell.value = currencyAmount
                    cell.valueColor = .themeLeah
                    cell.valueItalic = false
                    incoming.flatMap {
                        cell.valueColor = $0 ? .themeGreenD : .themeYellowD
                    }
                }
        )
    }

    private func dateRow(rowInfo: RowInfo, date: Date) -> RowProtocol {
        Row<D7Cell>(
                id: "date",
                hash: "date_\(date.description)",
                height: .heightCell48,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)
                    cell.title = "tx_info.date".localized
                    cell.value = DateHelper.instance.formatFullTime(from: date)
                    cell.valueColor = .themeLeah
                    cell.valueItalic = false
                }
        )
    }

    private func priceRow(rowInfo: RowInfo, price: String) -> RowProtocol {
        Row<D7Cell>(
                id: "price",
                hash: "\(price)",
                height: .heightCell48,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)
                    cell.title = "tx_info.price".localized
                    cell.value = price
                    cell.valueColor = .themeLeah
                    cell.valueItalic = false
                }
        )
    }
    private func row(viewItem: TransactionInfoModule.ViewItem, rowInfo: RowInfo) -> RowProtocol {
        switch viewItem {
        case let .actionTitle(title, subTitle): return actionTitleRow(rowInfo: rowInfo, title: title, value: subTitle ?? "")
        case let .amount(coinAmount, currencyAmount, incoming): return amountRow(rowInfo: rowInfo, coinAmount: coinAmount, currencyAmount: currencyAmount, incoming: incoming)
        case let .status(status): return statusRow(rowInfo: rowInfo, status: status)
        case let .options(actions: viewItems): return optionsRow(viewItems: viewItems)
        case let .date(date): return dateRow(rowInfo: rowInfo, date: date)
        case let .from(value): return fromRow(rowInfo: rowInfo, value: value)
        case let .to(value): return toRow(rowInfo: rowInfo, value: value)
        case let .recipient(value): return recipientRow(rowInfo: rowInfo, value: value)
        case let .id(value): return idRow(rowInfo: rowInfo, value: value)
        case let .rate(value): return valueRow(rowInfo: rowInfo, title: "tx_info.rate".localized, value: value)
        case let .fee(title, value): return feeRow(rowInfo: rowInfo, title: title, value: value)
        case let .price(price): return priceRow(rowInfo: rowInfo, price: price)
        case let .doubleSpend(txHash, conflictingTxHash): return doubleSpendRow(rowInfo: rowInfo, txHash: txHash, conflictingTxHash: conflictingTxHash)
        case let .lockInfo(lockState): return lockInfoRow(rowInfo: rowInfo, lockState: lockState)
        case .sentToSelf: return sentToSelfRow(rowInfo: rowInfo)
        case .rawTransaction: return rawTransactionRow(rowInfo: rowInfo)
        case let .memo(value): return multiLineValueRow(rowInfo: rowInfo, title: "tx_info.memo".localized, value: value, valueItalic: true)
        case let .service(value): return valueRow(rowInfo: rowInfo, title: "tx_info.service".localized, value: value)
        case let .explorer(title, url): return explorerRow(rowInfo: rowInfo, title: title, url: url)
        }
    }

}

extension TransactionInfoViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        viewItems.enumerated().map { (index: Int, sectionViewItems: [TransactionInfoModule.ViewItem]) -> SectionProtocol in
            Section(
                    id: "section_\(index)",
                    headerState: .margin(height: .margin12),
                    rows: sectionViewItems.enumerated().map { (index, viewItem) in
                        row(viewItem: viewItem, rowInfo: RowInfo(index: index, isFirst: index == 0, isLast: index == sectionViewItems.count - 1))
                    }
            )
        }
    }

}

fileprivate struct RowInfo {
    let index: Int
    let isFirst: Bool
    let isLast: Bool
}
