import UIKit
import ThemeKit
import SnapKit
import SectionsTableView
import RxSwift
import RxCocoa
import ComponentKit

class SendEvmTransactionViewController: ThemeViewController {
    let disposeBag = DisposeBag()

    let transactionViewModel: SendEvmTransactionViewModel
    let feeViewModel: EvmFeeViewModel

    private let tableView = SectionsTableView(style: .grouped)
    let bottomWrapper = BottomGradientHolder()

    private let maxFeeCell: EditableFeeCell

    private var sectionViewItems = [SendEvmTransactionViewModel.SectionViewItem]()
    private let caution1Cell = TitledHighlightedDescriptionCell()
    private let caution2Cell = TitledHighlightedDescriptionCell()
    private var isLoaded = false

    var topDescription: String?

    init(transactionViewModel: SendEvmTransactionViewModel, feeViewModel: EvmFeeViewModel) {
        self.transactionViewModel = transactionViewModel
        self.feeViewModel = feeViewModel

        maxFeeCell = EditableFeeCell(viewModel: feeViewModel)

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.delaysContentTouches = false

        tableView.sectionDataSource = self

        view.addSubview(bottomWrapper)
        bottomWrapper.snp.makeConstraints { maker in
            maker.top.equalTo(tableView.snp.bottom).offset(-CGFloat.margin16)
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        subscribe(disposeBag, transactionViewModel.cautionsDriver) { [weak self] in self?.handle(cautions: $0) }
        subscribe(disposeBag, transactionViewModel.sendingSignal) { [weak self] in self?.handleSending() }
        subscribe(disposeBag, transactionViewModel.sendSuccessSignal) { [weak self] in self?.handleSendSuccess(transactionHash: $0) }
        subscribe(disposeBag, transactionViewModel.sendFailedSignal) { [weak self] in self?.handleSendFailed(error: $0) }

        subscribe(disposeBag, transactionViewModel.sectionViewItemsDriver) { [weak self] in
            self?.sectionViewItems = $0
            self?.reloadTable()
        }

        tableView.buildSections()

        isLoaded = true
    }

    private func handle(cautions: [TitledCaution]) {
        if let caution = cautions.first {
            caution1Cell.bind(caution: caution)
            caution1Cell.isVisible = true
        } else {
            caution1Cell.isVisible = false
        }

        if cautions.count > 1 {
            caution2Cell.bind(caution: cautions[1])
            caution2Cell.isVisible = true
        } else {
            caution2Cell.isVisible = false
        }

        reloadTable()
    }

    func handleSending() {
    }

    func handleSendSuccess(transactionHash: Data) {
        dismiss(animated: true)
    }

    private func openFeeSettings() {
        guard let controller = EvmFeeModule.viewController(feeViewModel: feeViewModel) else {
            return
        }

        present(controller, animated: true)
    }

    private func handleSendFailed(error: String) {
        HudHelper.instance.show(banner: .error(string: error))
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

    private func row(viewItem: SendEvmTransactionViewModel.ViewItem, rowInfo: RowInfo) -> RowProtocol {
        switch viewItem {
        case let .subhead(iconName, title, value):
            return CellComponent.actionTitleRow(tableView: tableView, rowInfo: rowInfo, iconName: iconName, iconDimmed: true, title: title, value: value)
        case let .amount(iconUrl, iconPlaceholderImageName, coinAmount, currencyAmount, type):
            return CellComponent.amountRow(tableView: tableView, rowInfo: rowInfo, iconUrl: iconUrl, iconPlaceholderImageName: iconPlaceholderImageName, coinAmount: coinAmount, currencyAmount: currencyAmount, type: type)
        case let .nftAmount(iconUrl, iconPlaceholderImageName, nftAmount, type):
            return CellComponent.nftAmountRow(tableView: tableView, rowInfo: rowInfo, iconUrl: iconUrl, iconPlaceholderImageName: iconPlaceholderImageName, nftAmount: nftAmount, type: type, onTapOpenNft: nil)
        case let .doubleAmount(iconUrl, iconPlaceholderImageName, primaryCoinAmount, primaryCurrencyAmount, primaryType, secondaryCoinAmount, secondaryCurrencyAmount, secondaryType):
            return CellComponent.doubleAmountRow(tableView: tableView, rowInfo: rowInfo, iconUrl: iconUrl, iconPlaceholderImageName: iconPlaceholderImageName, primaryCoinAmount: primaryCoinAmount, primaryCurrencyAmount: primaryCurrencyAmount, primaryType: primaryType, secondaryCoinAmount: secondaryCoinAmount, secondaryCurrencyAmount: secondaryCurrencyAmount, secondaryType: secondaryType)
        case let .address(title, value, valueTitle):
            return CellComponent.fromToRow(tableView: tableView, rowInfo: rowInfo, title: title, value: value, valueTitle: valueTitle)
        case let .value(title, value, type):
            return CellComponent.valueRow(tableView: tableView, rowInfo: rowInfo, iconName: nil, title: title, value: value, type: type)
        case .input(let value):
            return CellComponent.fromToRow(tableView: tableView, rowInfo: rowInfo, title: "Input", value: value, valueTitle: nil)
        }
    }

    private func section(sectionViewItem: SendEvmTransactionViewModel.SectionViewItem, index: Int) -> SectionProtocol {
        var headerText: String?

        if index == 0, let topDescription = topDescription {
            headerText = topDescription
        }

        return Section(
                id: "section_\(index)",
                headerState: headerText.map { tableView.sectionFooter(text: $0) } ?? .margin(height: .margin12),
                rows: sectionViewItem.viewItems.enumerated().map { index, viewItem in
                    row(viewItem: viewItem, rowInfo: RowInfo(index: index, isFirst: index == 0, isLast: index == sectionViewItem.viewItems.count - 1))
                }
        )
    }

}

extension SendEvmTransactionViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        let transactionSections: [SectionProtocol] = sectionViewItems.enumerated().map { index, sectionViewItem in
            section(sectionViewItem: sectionViewItem, index: index)
        }

        let feeSections: [SectionProtocol] = [
            Section(
                    id: "fee",
                    headerState: .margin(height: .margin12),
                    rows: [
                        StaticRow(
                                cell: maxFeeCell,
                                id: "fee",
                                height: .heightCell48,
                                autoDeselect: true,
                                action: { [weak self] in
                                    self?.openFeeSettings()
                                }
                        )
                    ]
            )
        ]

        let cautionsSections: [SectionProtocol] = [
            Section(
                    id: "caution1",
                    headerState: .margin(height: .margin12),
                    rows: [
                        StaticRow(
                                cell: caution1Cell,
                                id: "caution1",
                                dynamicHeight: { [weak self] containerWidth in
                                    self?.caution1Cell.cellHeight(containerWidth: containerWidth) ?? 0
                                }
                        )
                    ]
            ),
            Section(
                    id: "caution2",
                    headerState: .margin(height: .margin12),
                    rows: [
                        StaticRow(
                                cell: caution2Cell,
                                id: "caution2",
                                dynamicHeight: { [weak self] containerWidth in
                                    self?.caution2Cell.cellHeight(containerWidth: containerWidth) ?? 0
                                }
                        )]
            )
        ]

        return transactionSections + feeSections + cautionsSections
    }

}
