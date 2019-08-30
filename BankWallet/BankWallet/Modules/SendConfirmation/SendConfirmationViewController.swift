import UIKit
import SnapKit
import SectionsTableView

class SendConfirmationViewController: UIViewController, SectionsDataSource {
    private let delegate: ISendConfirmationViewDelegate

    private let tableView = SectionsTableView(style: .grouped)
    private var rows = [RowProtocol]()

    private let decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ""
        return formatter
    }()

    init(delegate: ISendConfirmationViewDelegate) {
        self.delegate = delegate

        super.init(nibName: nil, bundle: nil)
    }

    @objc func onClose() {
//        delegate.onClose()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = AppTheme.controllerBackground
        title = "send.confirmation.title".localized

        tableView.registerCell(forClass: SendConfirmationPrimaryCell.self)
        tableView.registerCell(forClass: SendConfirmationFieldCell.self)
        tableView.registerCell(forClass: SendButtonCell.self)
        tableView.sectionDataSource = self
        tableView.separatorColor = .clear
        tableView.backgroundColor = .clear
        tableView.delaysContentTouches = false
        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .done, target: self, action: #selector(onTapCancel))

        delegate.viewDidLoad()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return AppTheme.statusBarStyle
    }

    @objc private func onTapCancel() {
        delegate.onCancelClicked()
    }

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()
        var rows = [RowProtocol]()
        rows.append(contentsOf: self.rows)
        let sendButtonRow = Row<SendButtonCell>(id: "send_row", height: SendTheme.sendButtonHolderHeight, bind: { [weak self] cell, _ in
            cell.bind { [weak self] in
                self?.onSendTap()
            }
        })
        rows.append(sendButtonRow)
        sections.append(Section(id: "confirmation_section", rows: rows))
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
        let primaryText: String?
        var secondaryText: String? = nil

        switch viewItem.primaryInfo {
        case .coinValue(let coinValue):
            primaryText = ValueFormatter.instance.format(coinValue: coinValue)
        case .currencyValue(let currencyValue):
            primaryText = ValueFormatter.instance.format(currencyValue: currencyValue)
        }

        if let secondaryInfo = viewItem.secondaryInfo {
            switch secondaryInfo {
            case .coinValue(let coinValue):
                secondaryText = ValueFormatter.instance.format(coinValue: coinValue)
            case .currencyValue(let currencyValue):
                secondaryText = ValueFormatter.instance.format(currencyValue: currencyValue)
            }
        }
        let row = Row<SendConfirmationPrimaryCell>(id: "send_primary_row", height: SendTheme.confirmationPrimaryHeight, bind: { [weak self] cell, _ in
            cell.bind(primaryAmount: primaryText, secondaryAmount: secondaryText, receiver: viewItem.receiver) { [weak self] in
                self?.onHashTap(receiver: viewItem.receiver)
            }
        })

        rows.append(row)
    }

    func show(viewItem: SendConfirmationMemoViewItem) {
        guard !viewItem.memo.isEmpty else {
            return
        }
        let row = Row<SendConfirmationFieldCell>(id: "send_memo_row", height: SendTheme.confirmationFieldHeight, bind: { cell, _ in
            cell.bind(title: "send.confirmation.memo_placeholder".localized + ":", text: viewItem.memo)
        })

        rows.append(row)
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

        let row = Row<SendConfirmationFieldCell>(id: "send_fee_row", height: SendTheme.confirmationFieldHeight, bind: { cell, _ in
            cell.bind(title: "send.fee".localized + ":", text: text)
        })

        rows.append(row)
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

        let row = Row<SendConfirmationFieldCell>(id: "send_total_row", height: SendTheme.confirmationFieldHeight, bind: { cell, _ in
            cell.bind(title: "send.confirmation.total".localized + ":", text: primaryText)
        })
        rows.append(row)
    }

    func show(viewItem: SendConfirmationDurationViewItem) {

        let row = Row<SendConfirmationFieldCell>(id: "send_duration_row", height: SendTheme.confirmationFieldHeight, bind: { cell, _ in
            cell.bind(title: "send.tx_duration".localized + ":", text: viewItem.timeInterval.map { "send.duration.within".localized($0.approximateHoursOrMinutes) } ?? "send.duration.instant".localized)
        })

        rows.append(row)
    }

    func buildData() {
        tableView.reload()
    }

    func showCopied() {
        HudHelper.instance.showSuccess(title: "alert.copied".localized)
    }

}
