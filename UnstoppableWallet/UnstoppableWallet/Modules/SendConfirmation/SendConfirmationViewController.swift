import UIKit
import SnapKit
import SectionsTableView
import ThemeKit
import CurrencyKit

class SendConfirmationViewController: ThemeViewController, SectionsDataSource {
    private let delegate: ISendConfirmationViewDelegate

    private let tableView = SectionsTableView(style: .grouped)
    private var topRows = [RowProtocol]()
    private var bottomRows = [RowProtocol]()
    private var noMemo = true

    private let decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ""
        return formatter
    }()

    init(delegate: ISendConfirmationViewDelegate) {
        self.delegate = delegate

        super.init()
    }

    @objc func onClose() {
//        delegate.onClose()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "confirm".localized

        tableView.registerCell(forClass: SendConfirmationAmountCell.self)
        tableView.registerCell(forClass: SendConfirmationReceiverCell.self)
        tableView.registerCell(forClass: SendConfirmationMemoCell.self)
        tableView.registerCell(forClass: AdditionalDataCell.self)
        tableView.registerCell(forClass: ButtonCell.self)
        tableView.sectionDataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.delaysContentTouches = false
        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .done, target: self, action: #selector(onTapCancel))

        delegate.viewDidLoad()
    }

    @objc private func onTapCancel() {
        delegate.onCancelClicked()
    }

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        sections.append(Section(id: "top_section", rows: topRows))
        sections.append(Section(id: "bottom_section", headerState: .margin(height: .margin3x), rows: bottomRows))
        sections.append(Section(id: "button_section", rows: [
            Row<ButtonCell>(
                    id: "send_row",
                    height: ButtonCell.height(style: .primaryYellow),
                    bind: { [weak self] cell, _ in
                        cell.bind(style: .primaryYellow, title: "send.confirmation.send_button".localized) { [weak self] in
                            self?.onSendTap()
                        }
                    }
            )
        ]))

        return sections
    }

    private func onSendTap() {
        delegate.onSendClicked()
    }

    private func onHashTap(receiver: String) {
        delegate.onCopy(receiver: receiver)
    }

    private func format(coinValue: CoinValue) -> String? {
        decimalFormatter.maximumFractionDigits = min(coinValue.coin.decimal, 8)
        return decimalFormatter.string(from: coinValue.value as NSNumber)
    }

    private func format(currencyValue: CurrencyValue) -> String? {
        decimalFormatter.maximumFractionDigits = currencyValue.currency.decimal
        return decimalFormatter.string(from: currencyValue.value as NSNumber)
    }

}

extension SendConfirmationViewController: ISendConfirmationView {

    func show(viewItem: SendConfirmationAmountViewItem) {
        let primaryRow = Row<SendConfirmationAmountCell>(id: "send_primary_row", height: SendConfirmationAmountCell.height, bind: { cell, _ in
            cell.bind(primaryAmountInfo: viewItem.primaryInfo, secondaryAmountInfo: viewItem.secondaryInfo)
        })
        let receiverRow = Row<SendConfirmationReceiverCell>(id: "send_receiver_row", height: SendConfirmationReceiverCell.height(forContainerWidth: view.bounds.width, text: viewItem.receiver), bind: { [weak self] cell, _ in
            cell.bind(receiver: viewItem.receiver, last: self?.noMemo ?? false) { [weak self] in
                self?.onHashTap(receiver: viewItem.receiver)
            }
        })
        topRows.append(primaryRow)
        topRows.append(receiverRow)
    }

    func show(viewItem: SendConfirmationMemoViewItem) {
        guard !viewItem.memo.isEmpty else {
            return
        }
        noMemo = false
        let row = Row<SendConfirmationMemoCell>(id: "send_memo_row", height: .heightSingleLineCell, bind: { cell, _ in
            cell.bind(memo: viewItem.memo)
        })

        topRows.append(row)
    }

    func show(viewItem: SendConfirmationFeeViewItem) {
        let formattedPrimary: String?
        var formattedSecondary: String? = nil

        switch viewItem.primaryInfo {
        case .coinValue(let coinValue):
            formattedPrimary = ValueFormatter.instance.format(coinValue: coinValue)
        case .currencyValue(let currencyValue):
            formattedPrimary = ValueFormatter.instance.format(currencyValue: currencyValue)
        }

        if let secondaryInfo = viewItem.secondaryInfo {
            switch secondaryInfo {
            case .coinValue(let coinValue):
                formattedSecondary = ValueFormatter.instance.format(coinValue: coinValue)
            case .currencyValue(let currencyValue):
                formattedSecondary = ValueFormatter.instance.format(currencyValue: currencyValue)
            }
        }

        guard let primaryText = formattedPrimary else { return }
        let text = [primaryText, formattedSecondary != nil ? "|" : nil, formattedSecondary].compactMap { $0 }.joined(separator: " ")

        let row = Row<AdditionalDataCell>(
                id: "send_fee_row",
                height: AdditionalDataCell.height,
                bind: { cell, _ in
                    cell.bind(title: "send.fee".localized, value: text)
                }
        )

        bottomRows.append(row)
    }

    func show(viewItem: SendConfirmationTotalViewItem) {
        let formattedPrimary: String?

        switch viewItem.primaryInfo {
        case .coinValue(let coinValue):
            formattedPrimary = ValueFormatter.instance.format(coinValue: coinValue)
        case .currencyValue(let currencyValue):
            formattedPrimary = ValueFormatter.instance.format(currencyValue: currencyValue)
        }

        guard let primaryText = formattedPrimary else { return }

        let row = Row<AdditionalDataCell>(
                id: "send_total_row",
                height: AdditionalDataCell.height,
                bind: { cell, _ in
                    cell.bind(title: "send.confirmation.total".localized, value: primaryText)
                }
        )

        bottomRows.append(row)
    }

    func show(viewItem: SendConfirmationDurationViewItem) {
        let row = Row<AdditionalDataCell>(
                id: "send_duration_row",
                height: AdditionalDataCell.height,
                bind: { cell, _ in
                    cell.bind(title: "send.tx_duration".localized, value: viewItem.timeInterval.map {
                        "send.duration.within".localized($0.approximateHoursOrMinutes)
                    } ?? "send.duration.instant".localized)
                }
        )

        bottomRows.append(row)
    }

    func show(viewItem: SendConfirmationLockUntilViewItem) {
        let row = Row<AdditionalDataCell>(
                id: "send_lock_until_row",
                height: AdditionalDataCell.height,
                bind: { cell, _ in
                    cell.bind(title: "send.lock_time".localized, value: viewItem.lockValue.localized)
                }
        )

        bottomRows.append(row)
    }

    func buildData() {
        tableView.reload()
    }

    func showCopied() {
        HudHelper.instance.showSuccess(title: "alert.copied".localized)
    }

}
