import UIKit
import ActionSheet
import ThemeKit
import SectionsTableView
import CurrencyKit

class TransactionInfoViewController: ThemeActionSheetController {
    private let delegate: ITransactionInfoViewDelegate

    private let titleView = BottomSheetTitleView()
    private let amountInfoView = AmountInfoView()
    private let separatorView = UIView()
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

        view.addSubview(separatorView)
        separatorView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalTo(amountInfoView)
            maker.height.equalTo(1 / UIScreen.main.scale)
        }

        separatorView.backgroundColor = .themeSteel20

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(amountInfoView.snp.bottom)
        }

        tableView.registerCell(forClass: TransactionInfoStatusCell.self)
        tableView.registerCell(forClass: TransactionInfoFromToCell.self)
        tableView.registerCell(forClass: TransactionInfoTransactionIdCell.self)
        tableView.registerCell(forClass: TransactionInfoValueCell.self)
        tableView.registerCell(forClass: TransactionInfoWarningCell.self)
        tableView.registerCell(forClass: TransactionInfoNoteCell.self)
        tableView.registerCell(forClass: TransactionInfoCopyCell.self)
        tableView.sectionDataSource = self
        tableView.allowsSelection = false

        view.addSubview(verifyButton)
        verifyButton.snp.makeConstraints { maker in
            maker.leading.trailing.bottom.equalToSuperview()
            maker.top.equalTo(tableView.snp.bottom)
            maker.height.equalTo(CGFloat.heightButton)
        }

        verifyButton.apply(style: .primaryTransparent)
        verifyButton.setTitle("tx_info.button_verify".localized, for: .normal)
        verifyButton.addTarget(self, action: #selector(_onTapVerify), for: .touchUpInside)

        delegate.onLoad()

        tableView.reload()
    }

    @objc private func _onTapVerify() {
        delegate.onTapVerify()
    }

    private func statusRow(status: TransactionStatus, incoming: Bool) -> RowProtocol {
        Row<TransactionInfoStatusCell>(
                id: "status",
                hash: "\(status)",
                height: .heightSingleLineCell,
                bind: { cell, _ in
                    cell.bind(status: status, incoming: incoming)
                }
        )
    }

    private func fromToRow(title: String, value: String, onTap: @escaping () -> ()) -> RowProtocol {
        Row<TransactionInfoFromToCell>(
                id: title,
                hash: value,
                height: .heightSingleLineCell,
                bind: { cell, _ in
                    cell.bind(title: title, value: value, onTap: onTap)
                }
        )
    }

    private func fromRow(value: String) -> RowProtocol {
        fromToRow(title: "tx_info.from_hash".localized, value: TransactionInfoAddressMapper.map(value)) { [weak self] in
            self?.delegate.onTapFrom()
        }
    }

    private func toRow(value: String) -> RowProtocol {
        fromToRow(title: "tx_info.to_hash".localized, value: TransactionInfoAddressMapper.map(value)) { [weak self] in
            self?.delegate.onTapTo()
        }
    }

    private func recipientRow(value: String) -> RowProtocol {
        fromToRow(title: "tx_info.recipient_hash".localized, value: TransactionInfoAddressMapper.map(value)) { [weak self] in
            self?.delegate.onTapRecipient()
        }
    }

    private func idRow(value: String) -> RowProtocol {
        Row<TransactionInfoTransactionIdCell>(
                id: "transaction_id",
                hash: value,
                height: .heightSingleLineCell,
                bind: { [weak self] cell, _ in
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

    private func valueRow(title: String, value: String?) -> RowProtocol {
        Row<TransactionInfoValueCell>(
                id: title,
                hash: value ?? "",
                height: .heightSingleLineCell,
                bind: { cell, _ in
                    cell.bind(title: title, value: value)
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
                    cell.bind(image: image, text: text, onTapButton: onTapButton)
                }
        )
    }

    private func doubleSpendRow() -> RowProtocol {
        warningRow(
                id: "double_spend",
                image: UIImage(named: "Transaction Double Spend Icon"),
                text: "tx_info.double_spent_note".localized
        ) { [weak self] in
            self?.delegate.onTapDoubleSpendInfo()
        }
    }

    private func lockInfoRow(lockState: TransactionLockState) -> RowProtocol {
        let id = "lock_info"
        let image = UIImage(named: lockState.locked ? "Transaction Lock Icon" : "Transaction Unlock Icon")
        let formattedDate = DateHelper.instance.formatFullTime(from: lockState.date)

        if lockState.locked {
            return warningRow(id: id, image: image, text: "tx_info.locked_until".localized(formattedDate)) { [weak self] in
                self?.delegate.onTapLockInfo()
            }
        } else {
            return noteRow(id: id, image: image, text: "tx_info.unlocked_at".localized(formattedDate))
        }
    }

    private func noteRow(id: String, image: UIImage?, text: String) -> RowProtocol {
        Row<TransactionInfoNoteCell>(
                id: id,
                hash: text,
                dynamicHeight: { containerWidth in
                    TransactionInfoNoteCell.height(containerWidth: containerWidth, text: text)
                },
                bind: { cell, _ in
                    cell.bind(image: image, text: text)
                }
        )
    }

    private func sentToSelfRow() -> RowProtocol {
        noteRow(
                id: "sent_to_self",
                image: UIImage(named: "Transaction In Icon")?.tinted(with: .themeRemus),
                text: "tx_info.to_self_note".localized
        )
    }

    private func rawTransactionRow() -> RowProtocol {
        Row<TransactionInfoCopyCell>(
                id: "raw_transaction",
                height: .heightSingleLineCell,
                bind: { [weak self] cell, _ in
                    cell.bind(
                            title: "tx_info.raw_transaction".localized,
                            onTapCopy: {
                                self?.delegate.onTapCopyRawTransaction()
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
        }
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

        let iconImage: UIImage? = {
            switch type {
            case .incoming:
                return UIImage(named: "Transaction In Icon")
            case .outgoing, .sentToSelf:
                return UIImage(named: "Transaction Out Icon")
            case .approve:
                return UIImage(named: "Transaction Approve Icon")?.tinted(with: .themeLeah)
            }
        }()

        titleView.bind(
                title: title,
                subtitle: DateHelper.instance.formatFullTime(from: date),
                image: iconImage
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

    func showCopied() {
        HudHelper.instance.showSuccess(title: "alert.copied".localized)
    }

}
