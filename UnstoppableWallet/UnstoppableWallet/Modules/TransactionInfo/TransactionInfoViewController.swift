import UIKit
import ActionSheet
import ThemeKit
import SectionsTableView
import CurrencyKit
import ComponentKit

class TransactionInfoViewController: ThemeActionSheetController {
    private let delegate: ITransactionInfoViewDelegate

    private let titleView = BottomSheetTitleView()
    private let amountInfoView = AmountInfoView()
    private let tableView = SelfSizedSectionsTableView(style: .grouped)
    private let verifyButton = ThemeButton()

    private var viewItems = [TransactionInfoModule.ViewItem]()

    init(delegate: ITransactionInfoViewDelegate) {
        self.delegate = delegate
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(titleView)
        titleView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        titleView.onTapClose = { [weak self] in
            self?.dismiss(animated: true)
        }

        view.addSubview(amountInfoView)
        amountInfoView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(titleView.snp.bottom)
            maker.height.equalTo(72)
        }

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(amountInfoView.snp.bottom)
        }

        tableView.registerCell(forClass: TransactionInfoPendingStatusCell.self)
        tableView.registerCell(forClass: D9Cell.self)
        tableView.registerCell(forClass: TransactionInfoTransactionIdCell.self)
        tableView.registerCell(forClass: D7Cell.self)
        tableView.registerCell(forClass: TransactionInfoWarningCell.self)
        tableView.registerCell(forClass: TransactionInfoNoteCell.self)
        tableView.registerCell(forClass: TransactionInfoShareCell.self)
        tableView.registerCell(forClass: D6Cell.self)
        tableView.registerCell(forClass: C6Cell.self)
        tableView.sectionDataSource = self
        tableView.allowsSelection = false

        let separator = UIView()

        view.addSubview(separator)
        separator.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(tableView.snp.bottom)
            maker.height.equalTo(CGFloat.heightOneDp)
        }

        separator.backgroundColor = .themeSteel10

        view.addSubview(verifyButton)
        verifyButton.snp.makeConstraints { maker in
            maker.leading.trailing.bottom.equalToSuperview()
            maker.top.equalTo(tableView.snp.bottom)
            maker.height.equalTo(CGFloat.heightButton)
        }

        verifyButton.apply(style: .primaryTransparent)
        verifyButton.addTarget(self, action: #selector(onTapVerify), for: .touchUpInside)

        delegate.onLoad()

        tableView.reload()
    }

    @objc private func onTapVerify() {
        delegate.onTapVerify()
    }

    private var completedStatusCell: RowProtocol {
        Row<D6Cell>(
                id: "status",
                hash: "completed",
                height: .heightCell48,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .transparent)
                    cell.title = "status".localized
                    cell.value = "tx_info.status.completed".localized
                    cell.valueImage = UIImage(named: "check_1_20")?.withRenderingMode(.alwaysTemplate)
                    cell.valueImageTintColor = .themeRemus
                    cell.selectionStyle = .none
                }
        )
    }

    private var failedStatusCell: RowProtocol {
        Row<C6Cell>(
                id: "status",
                hash: "failed",
                height: .heightCell48,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .transparent)
                    cell.title = "status".localized
                    cell.titleImage = UIImage(named: "circle_information_20")?.withRenderingMode(.alwaysTemplate)
                    cell.titleImageTintColor = .themeJacob
                    cell.value = "tx_info.status.failed".localized
                    cell.valueImage = UIImage(named: "warning_2_20")?.withRenderingMode(.alwaysTemplate)
                    cell.valueImageTintColor = .themeLucian
                    cell.titleImageAction = { [weak self] in
                        self?.openStatusInfo()
                    }
                }
        )
    }

    private func pendingStatusCell(progress: Double, incoming: Bool) -> RowProtocol {
        Row<TransactionInfoPendingStatusCell>(
                id: "status",
                hash: "pending-\(progress)-\(incoming)",
                height: .heightCell48,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .transparent)
                    cell.bind(progress: progress, incoming: incoming) { [weak self] in
                        self?.openStatusInfo()
                    }
                }
        )
    }

    private func statusRow(status: TransactionStatus, incoming: Bool) -> RowProtocol {
        switch status {
        case .completed:
            return completedStatusCell
        case .failed:
            return failedStatusCell
        case .pending:
            return pendingStatusCell(progress: 0, incoming: incoming)
        case .processing(let progress):
            return pendingStatusCell(progress: progress, incoming: incoming)
        }
    }

    private func fromToRow(title: String, value: String) -> RowProtocol {
        Row<D9Cell>(
                id: title,
                hash: value,
                height: .heightCell48,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .transparent)
                    cell.title = title
                    cell.viewItem = .init(title: TransactionInfoAddressMapper.title(value: value), value: value)
                }
        )
    }

    private func fromRow(value: String) -> RowProtocol {
        fromToRow(title: "tx_info.from_hash".localized, value: value)
    }

    private func toRow(value: String) -> RowProtocol {
        fromToRow(title: "tx_info.to_hash".localized, value: value)
    }

    private func recipientRow(value: String) -> RowProtocol {
        fromToRow(title: "tx_info.recipient_hash".localized, value: value)
    }

    private func idRow(value: String) -> RowProtocol {
        Row<TransactionInfoTransactionIdCell>(
                id: "transaction_id",
                hash: value,
                height: .heightCell48,
                bind: { [weak self] cell, _ in
                    cell.set(backgroundStyle: .transparent)
                    cell.bind(
                            value: value,
                            onTapId: {
                                self?.delegate.onTapTransactionId()
                            },
                            onTapShare: {
                                self?.delegate.onTapShareTransactionId()
                            }
                    )
                }
        )
    }

    private func valueRow(title: String, value: String?, valueItalic: Bool = false) -> RowProtocol {
        Row<D7Cell>(
                id: title,
                hash: value ?? "",
                dynamicHeight: { width in
                    D7Cell.height(containerWidth: width, backgroundStyle: .transparent, title: title, value: value, valueItalic: valueItalic)
                },
                bind: { cell, _ in
                    cell.set(backgroundStyle: .transparent)
                    cell.title = title
                    cell.value = value
                    cell.valueItalic = valueItalic
                }
        )
    }

    private func rateRow(currencyValue: CurrencyValue, coinCode: String) -> RowProtocol {
        let formattedValue = ValueFormatter.instance.format(currencyValue: currencyValue, fractionPolicy: .threshold(high: 1000, low: 0.1), trimmable: false)

        return valueRow(
                title: "tx_info.rate".localized,
                value: formattedValue.map { "balance.rate_per_coin".localized($0, coinCode) }
        )
    }

    private func feeRow(coinValue: CoinValue, currencyValue: CurrencyValue?) -> RowProtocol {
        var parts = [String]()

        if let formattedCoinValue = ValueFormatter.instance.format(coinValue: coinValue) {
            parts.append(formattedCoinValue)
        }

        if let currencyValue = currencyValue, let formattedCurrencyValue = ValueFormatter.instance.format(currencyValue: currencyValue) {
            parts.append(formattedCurrencyValue)
        }

        return valueRow(
                title: "tx_info.fee".localized,
                value: parts.joined(separator: " | ")
        )
    }

    private func warningRow(id: String, image: UIImage?, text: String, onTapButton: @escaping () -> ()) -> RowProtocol {
        Row<TransactionInfoWarningCell>(
                id: id,
                hash: text,
                dynamicHeight: { containerWidth in
                    TransactionInfoWarningCell.height(containerWidth: containerWidth, text: text)
                },
                bind: { cell, _ in
                    cell.set(backgroundStyle: .transparent)
                    cell.bind(image: image, text: text, onTapButton: onTapButton)
                }
        )
    }

    private func doubleSpendRow() -> RowProtocol {
        warningRow(
                id: "double_spend",
                image: UIImage(named: "double_send_20"),
                text: "tx_info.double_spent_note".localized
        ) { [weak self] in
            self?.delegate.onTapDoubleSpendInfo()
        }
    }

    private func lockInfoRow(lockState: TransactionLockState) -> RowProtocol {
        let id = "lock_info"
        let image = UIImage(named: lockState.locked ? "lock_20" : "unlock_20")
        let formattedDate = DateHelper.instance.formatFullTime(from: lockState.date)

        if lockState.locked {
            return warningRow(id: id, image: image, text: "tx_info.locked_until".localized(formattedDate)) { [weak self] in
                self?.delegate.onTapLockInfo()
            }
        } else {
            return noteRow(id: id, image: image, imageTintColor: .themeGray, text: "tx_info.unlocked_at".localized(formattedDate))
        }
    }

    private func noteRow(id: String, image: UIImage?, imageTintColor: UIColor?, text: String) -> RowProtocol {
        Row<TransactionInfoNoteCell>(
                id: id,
                hash: text,
                dynamicHeight: { containerWidth in
                    TransactionInfoNoteCell.height(containerWidth: containerWidth, text: text)
                },
                bind: { cell, _ in
                    cell.set(backgroundStyle: .transparent)
                    cell.bind(image: image, imageTintColor: imageTintColor, text: text)
                }
        )
    }

    private func sentToSelfRow() -> RowProtocol {
        noteRow(
                id: "sent_to_self",
                image: UIImage(named: "arrow_medium_main_down_left_20")?.withRenderingMode(.alwaysTemplate),
                imageTintColor: .themeRemus,
                text: "tx_info.to_self_note".localized
        )
    }

    private func rawTransactionRow() -> RowProtocol {
        Row<TransactionInfoShareCell>(
                id: "raw_transaction",
                height: .heightCell48,
                bind: { [weak self] cell, _ in
                    cell.set(backgroundStyle: .transparent)
                    cell.bind(
                            title: "tx_info.raw_transaction".localized,
                            onTapShare: {
                                self?.delegate.onTapShareRawTransaction()
                            }
                    )
                }
        )
    }

    private func row(viewItem: TransactionInfoModule.ViewItem) -> RowProtocol {
        switch viewItem {
        case let .status(status, incoming): return statusRow(status: status, incoming: incoming)
        case let .from(value): return fromRow(value: value)
        case let .to(value): return toRow(value: value)
        case let .recipient(value): return recipientRow(value: value)
        case let .id(value): return idRow(value: value)
        case let .rate(currencyValue, coinCode): return rateRow(currencyValue: currencyValue, coinCode: coinCode)
        case let .fee(coinValue, currencyValue): return feeRow(coinValue: coinValue, currencyValue: currencyValue)
        case .doubleSpend: return doubleSpendRow()
        case let .lockInfo(lockState): return lockInfoRow(lockState: lockState)
        case .sentToSelf: return sentToSelfRow()
        case .rawTransaction: return rawTransactionRow()
        case let .memo(text): return valueRow(title: "tx_info.memo".localized, value: text, valueItalic: true)
        }
    }

    private func openStatusInfo() {
        let viewController = TransactionStatusInfoViewController()
        present(ThemeNavigationController(rootViewController: viewController), animated: true)
    }

}

extension TransactionInfoViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "main",
                    rows: viewItems.map { viewItem in
                        row(viewItem: viewItem)
                    }
            )
        ]
    }

}

extension TransactionInfoViewController: ITransactionInfoView {

    func set(date: Date, primaryAmountInfo: AmountInfo, secondaryAmountInfo: AmountInfo?, type: TransactionType, lockState: TransactionLockState?) {
        let title: String = {
            switch type {
            case .approve:
                return "tx_info.title_approval".localized
            default:
                return "tx_info.title".localized
            }
        }()

        let iconImage: UIImage?
        let iconTintColor: UIColor?
        switch type {
        case .incoming:
            iconImage = UIImage(named: "arrow_medium_3_down_left_24")
            iconTintColor = .themeRemus
        case .outgoing, .sentToSelf:
            iconImage = UIImage(named: "arrow_medium_3_up_right_24")
            iconTintColor = .themeJacob
        case .approve:
            iconImage = UIImage(named: "arrow_swap_approval_2_24")
            iconTintColor = .themeLeah
        }

        titleView.bind(
                title: title,
                subtitle: DateHelper.instance.formatFullTime(from: date),
                image: iconImage,
                tintColor: iconTintColor
        )

        if secondaryAmountInfo != nil {
            amountInfoView.customPrimaryFractionPolicy = .threshold(high: 1000, low: 0.01)
            amountInfoView.primaryFormatTrimmable = false
        }

        amountInfoView.bind(primaryAmountInfo: primaryAmountInfo, secondaryAmountInfo: secondaryAmountInfo, type: type, lockState: lockState)
    }

    func set(viewItems: [TransactionInfoModule.ViewItem]) {
        self.viewItems = viewItems
    }

    func set(explorerTitle: String, enabled: Bool) {
        verifyButton.setTitle("tx_info.button_explorer".localized(explorerTitle), for: .normal)
        verifyButton.isEnabled = enabled
    }

    func showCopied() {
        HudHelper.instance.showSuccess(title: "alert.copied".localized)
    }

}
