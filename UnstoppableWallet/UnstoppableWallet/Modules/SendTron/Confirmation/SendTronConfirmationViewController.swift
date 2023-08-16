import UIKit
import ThemeKit
import SnapKit
import SectionsTableView
import RxSwift
import RxCocoa
import ComponentKit
import Foundation
import MarketKit

class SendTronConfirmationViewController: ThemeViewController {
    let disposeBag = DisposeBag()

    let transactionViewModel: SendTronConfirmationViewModel
    let feeViewModel: SendFeeViewModel

    private let tableView = SectionsTableView(style: .grouped)
    let bottomWrapper = BottomGradientHolder()

    private let sendButton = SliderButton()
    private let feeCell: FeeCell

    private var sectionViewItems = [SendTronConfirmationViewModel.SectionViewItem]()
    private var feeViewItems = [SendTronConfirmationViewModel.TronFeeViewItem]()
    private let cautionCell = TitledHighlightedDescriptionCell()
    private var isLoaded = false

    init(transactionViewModel: SendTronConfirmationViewModel, feeViewModel: SendFeeViewModel) {
        self.transactionViewModel = transactionViewModel
        self.feeViewModel = feeViewModel

        feeCell = FeeCell(viewModel: feeViewModel, title: "send.fee".localized, isLast: false)

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "confirm".localized
        navigationItem.largeTitleDisplayMode = .never

        feeCell.onOpenInfo = { [weak self] in
            self?.openInfo(title: "send.fee".localized, description: "tron.send.fee.info".localized)
        }

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.delaysContentTouches = false

        tableView.sectionDataSource = self

        bottomWrapper.add(to: self, under: tableView)

        bottomWrapper.addSubview(sendButton)

        sendButton.title = "send.confirmation.slide_to_send".localized
        sendButton.finalTitle = "send.confirmation.sending".localized
        sendButton.slideImage = UIImage(named: "arrow_medium_2_right_24")
        sendButton.finalImage = UIImage(named: "check_2_24")
        sendButton.onTap = { [weak self] in
            self?.transactionViewModel.send()
        }

        subscribe(disposeBag, transactionViewModel.cautionsDriver) { [weak self] in self?.handle(cautions: $0) }
        subscribe(disposeBag, transactionViewModel.sendingSignal) { [weak self] in self?.handleSending() }
        subscribe(disposeBag, transactionViewModel.sendSuccessSignal) { [weak self] in self?.handleSendSuccess() }
        subscribe(disposeBag, transactionViewModel.sendFailedSignal) { [weak self] in self?.handleSendFailed(error: $0) }
        subscribe(disposeBag, transactionViewModel.sendEnabledDriver) { [weak self] in self?.sendButton.isEnabled = $0 }
        subscribe(disposeBag, transactionViewModel.feesSignal) { [weak self] in self?.handleFeeItems(items: $0) }

        subscribe(disposeBag, transactionViewModel.sectionViewItemsDriver) { [weak self] in
            self?.sectionViewItems = $0
            self?.reloadTable()
        }

        tableView.buildSections()

        isLoaded = true
    }

    private func handle(cautions: [TitledCaution]) {
        if let caution = cautions.first {
            cautionCell.bind(caution: caution)
            cautionCell.isVisible = true
        } else {
            cautionCell.isVisible = false
        }

        reloadTable()
    }

    private func handleFeeItems(items: [SendTronConfirmationViewModel.TronFeeViewItem]) {
        self.feeViewItems = items
        reloadTable()
    }

    func handleSending() {
    }

    func handleSendSuccess() {
        dismiss(animated: true)
    }

    private func openInfo(title: String, description: String) {
        let viewController = BottomSheetModule.description(title: title, text: description)
        present(viewController, animated: true)
    }

    private func handleSendFailed(error: String) {
        HudHelper.instance.show(banner: .error(string: error))
        sendButton.reset()
    }

    private func reloadTable() {
        guard isLoaded else {
            return
        }

        tableView.reload(animated: true)

        UIView.animate(withDuration: 0.2) {
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        }
    }

    private func row(viewItem: SendTronConfirmationViewModel.ViewItem, rowInfo: RowInfo) -> RowProtocol {
        switch viewItem {
            case let .subhead(iconName, title, value):
                return CellComponent.actionTitleRow(tableView: tableView, rowInfo: rowInfo, iconName: iconName, iconDimmed: true, title: title, value: value)
            case let .amount(iconUrl, iconPlaceholderImageName, coinAmount, currencyAmount, type):
                return CellComponent.amountRow(tableView: tableView, rowInfo: rowInfo, iconUrl: iconUrl, iconPlaceholderImageName: iconPlaceholderImageName, coinAmount: coinAmount, currencyAmount: currencyAmount, type: type)
            case let .address(title, value, valueTitle, contactAddress):
                var onAddToContact: (() -> ())? = nil
                if let contactAddress {
                    onAddToContact = { [weak self] in
                        ContactBookModule.showAddition(contactAddress: contactAddress, parentViewController: self)
                    }
                }
                return CellComponent.fromToRow(tableView: tableView, rowInfo: rowInfo, title: title, value: value, valueTitle: valueTitle, onAddToContact: onAddToContact)
            case let .value(title, value, type):
                return CellComponent.valueRow(tableView: tableView, rowInfo: rowInfo, iconName: nil, title: title, value: value, type: type)
            case let .warning(text, title, info):
                return warningRow(tableView: tableView, rowInfo: rowInfo, text: text, title: title, info: info)
        }
    }

    private func section(sectionViewItem: SendTronConfirmationViewModel.SectionViewItem, index: Int) -> SectionProtocol {
        return Section(
            id: "section_\(index)",
            headerState: .margin(height: .margin12),
            rows: sectionViewItem.viewItems.enumerated().map { index, viewItem in
                row(viewItem: viewItem, rowInfo: RowInfo(index: index, isFirst: index == 0, isLast: index == sectionViewItem.viewItems.count - 1))
            }
        )
    }

    private func warningRow(tableView: SectionsTableView, rowInfo: RowInfo, text: String, title: String, info: String) -> RowProtocol {
        CellBuilderNew.row(
            rootElement: .hStack([
                .secondaryButton { [weak self] component in
                    component.button.set(style: .transparent2, image: UIImage(named: "circle_information_20"))
                    component.button.setTitle(text, for: .normal)
                    component.button.setTitleColor(.themeJacob, for: .normal)
                    component.onTap = { [weak self] in
                        self?.openInfo(title: title, description: info)
                    }
                },
                .margin0,
                .text { _ in },
            ]),
            tableView: tableView,
            id: "warning-\(rowInfo.index)",
            hash: "warning-\(title)",
            height: .heightDoubleLineCell,
            bind: { cell in
                cell.set(backgroundStyle: .lawrence, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)
            }
        )
    }

    private func doubleAmountRow(tableView: SectionsTableView, rowInfo: RowInfo, item: SendTronConfirmationViewModel.TronFeeViewItem) -> RowProtocol {
        let value2Font: UIFont = item.value2IsSecondary ? .caption : .subhead2
        let value2Color: UIColor = item.value2IsSecondary ? .themeGray : .themeLeah

        return CellBuilderNew.row(
            rootElement: .hStack([
                    .secondaryButton { [weak self] component in
                        component.button.set(style: .transparent2, image: UIImage(named: "circle_information_20"))
                        component.button.setTitle(item.title, for: .normal)
                        component.onTap = { [weak self] in
                            self?.openInfo(title: item.title, description: item.info)
                        }
                    },
                    .margin0,
                    .text { _ in },
                    .vStackCentered([
                    .text { (component: TextComponent) -> () in
                        component.font = .subhead2
                        component.textColor = .themeLeah
                        component.textAlignment = .right
                        component.text = item.value1
                    },
                    .margin(1),
                    .text { (component: TextComponent) -> () in
                        component.font = value2Font
                        component.textColor = value2Color
                        component.textAlignment = .right
                        component.text = item.value2
                    }
                ])
            ]),
            tableView: tableView,
            id: "double-amount-\(rowInfo.index)",
            hash: "double-amount-\(item.value1)-\(item.value2 ?? "-")",
            height: .heightDoubleLineCell,
            bind: { cell in
                cell.set(backgroundStyle: .lawrence, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)
            }
        )
    }

}

extension SendTronConfirmationViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        let transactionSections: [SectionProtocol] = sectionViewItems.enumerated().map { index, sectionViewItem in
            section(sectionViewItem: sectionViewItem, index: index)
        }

        var feeSections: [SectionProtocol] = []
        let feeRows: [RowProtocol] = feeViewItems.enumerated().map { index, viewItem in
            let rowInfo = RowInfo(index: index + 1, isFirst: false, isLast: index == feeViewItems.count - 1)

            return doubleAmountRow(tableView: tableView, rowInfo: rowInfo, item: viewItem)
        }

        feeSections.append(
            Section(
                id: "fee",
                headerState: .margin(height: .margin16),
                rows: [StaticRow(
                    cell: feeCell,
                    id: "fee",
                    height: .heightDoubleLineCell
                )] + feeRows
            )
        )

        let cautionsSections: [SectionProtocol] = [
            Section(
                id: "caution1",
                headerState: .margin(height: .margin16),
                rows: [
                    StaticRow(
                        cell: cautionCell,
                        id: "caution1",
                        dynamicHeight: { [weak self] containerWidth in
                            self?.cautionCell.cellHeight(containerWidth: containerWidth) ?? 0
                        }
                    )
                ]
            )
        ]

        return transactionSections + feeSections + cautionsSections
    }

}
