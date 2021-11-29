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

    private let tableView = SectionsTableView(style: .grouped)
    let bottomWrapper = BottomGradientHolder()

    private let estimatedFeeCell: SendFeeCell
    private let maxFeeCell: SendFeeCell
    private let feePriorityCell: SendFeePriorityCell
    private let errorCell = SendEthereumErrorCell()

    private var sectionViewItems = [SendEvmTransactionViewModel.SectionViewItem]()
    private var isLoaded = false

    var topDescription: String?

    init(transactionViewModel: SendEvmTransactionViewModel, feeViewModel: EthereumFeeViewModel) {
        self.transactionViewModel = transactionViewModel

        estimatedFeeCell = SendFeeCell(driver: feeViewModel.estimatedFeeDriver)
        maxFeeCell = SendFeeCell(driver: feeViewModel.feeDriver)
        feePriorityCell = SendFeePriorityCell(viewModel: feeViewModel)

        super.init()

        feePriorityCell.delegate = self

        estimatedFeeCell.titleType = .estimatedFee
        subscribe(disposeBag, feeViewModel.estimatedFeeDriver) { [weak self] in self?.maxFeeCell.titleType = $0 == nil ? .fee : .maxFee }
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
        tableView.allowsSelection = false

        tableView.registerCell(forClass: B7Cell.self)
        tableView.registerCell(forClass: D7Cell.self)
        tableView.registerCell(forClass: D9Cell.self)
        tableView.registerCell(forClass: AdditionalDataCell.self)
        tableView.registerCell(forClass: TitledHighlightedDescriptionCell.self)
        tableView.registerHeaderFooter(forClass: BottomDescriptionHeaderFooterView.self)
        tableView.registerHeaderFooter(forClass: SubtitleHeaderFooterView.self)
        tableView.sectionDataSource = self

        view.addSubview(bottomWrapper)
        bottomWrapper.snp.makeConstraints { maker in
            maker.top.equalTo(tableView.snp.bottom).offset(-CGFloat.margin16)
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        subscribe(disposeBag, transactionViewModel.errorDriver) { [weak self] in self?.handle(error: $0) }
        subscribe(disposeBag, transactionViewModel.sendingSignal) { HudHelper.instance.showSpinner() }
        subscribe(disposeBag, transactionViewModel.sendSuccessSignal) { [weak self] in self?.handleSendSuccess(transactionHash: $0) }
        subscribe(disposeBag, transactionViewModel.sendFailedSignal) { [weak self] in self?.handleSendFailed(error: $0) }

        subscribe(disposeBag, transactionViewModel.sectionViewItemsDriver) { [weak self] in
            self?.sectionViewItems = $0
            self?.reloadTable()
        }

        tableView.buildSections()

        isLoaded = true
    }

    private func handle(error: String?) {
        errorCell.bind(text: error)
        reloadTable()
    }

    func handleSendSuccess(transactionHash: Data) {
        HudHelper.instance.showSuccess(title: "alert.success_action".localized)

        dismiss(animated: true)
    }

    private func handleSendFailed(error: String) {
        HudHelper.instance.showError(title: error)
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

    private func header(text: String) -> ViewState<SubtitleHeaderFooterView> {
        .cellType(
                hash: text,
                binder: { view in
                    view.bind(text: text)
                },
                dynamicHeight: { _ in
                    SubtitleHeaderFooterView.height
                }
        )
    }

    private func row(title: String, value: String) -> RowProtocol {
        Row<AdditionalDataCell>(
                id: title,
                height: AdditionalDataCell.height,
                bind: { cell, _ in
                    cell.bind(title: title, value: value)
                }
        )
    }

    private func hexRow(title: String, valueTitle: String, value: String, index: Int, isFirst: Bool, isLast: Bool) -> RowProtocol {
        Row<D9Cell>(
                id: "address-\(index)",
                height: .heightCell48,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
                    cell.title = title
                    cell.viewItem = .init(type: .title(text: valueTitle), value: { value })
                }
        )
    }

    private func subheadRow(title: String, value: String, index: Int, isFirst: Bool, isLast: Bool) -> RowProtocol {
        Row<B7Cell>(
                id: "subhead-\(index)",
                height: .heightCell48,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
                    cell.title = title
                    cell.value = value
                    cell.valueColor = .themeGray
                    cell.valueItalic = false
                }
        )
    }

    private func valueRow(title: String, value: String, type: SendEvmTransactionViewModel.ValueType, index: Int, isFirst: Bool, isLast: Bool) -> RowProtocol {
        Row<D7Cell>(
                id: "value-\(index)",
                hash: value,
                height: .heightCell48,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
                    cell.title = title
                    cell.value = value
                    cell.valueItalic = false

                    switch type {
                    case .regular: cell.valueColor = .themeBran
                    case .disabled: cell.valueColor = .themeGray
                    case .outgoing, .warning: cell.valueColor = .themeJacob
                    case .incoming: cell.valueColor = .themeRemus
                    case .alert: cell.valueColor = .themeLucian
                    }
                }
        )
    }

    private func warningRow(title: String, value: String, index: Int, isFirst: Bool, isLast: Bool) -> RowProtocol {
        Row<TitledHighlightedDescriptionCell>(
                id: title,
                dynamicHeight: { containerWidth in TitledHighlightedDescriptionCell.height(containerWidth: containerWidth, text: value) },
                bind: { cell, _ in
                    cell.titleIcon = UIImage(named: "warning_2_20")?.withRenderingMode(.alwaysTemplate)
                    cell.tintColor = .themeJacob
                    cell.titleText = title
                    cell.descriptionText = value
                }
        )
    }

    private func row(viewItem: SendEvmTransactionViewModel.ViewItem, index: Int, isFirst: Bool, isLast: Bool) -> RowProtocol {
        switch viewItem {
        case let .subhead(title, value): return subheadRow(title: title, value: value, index: index, isFirst: isFirst, isLast: isLast)
        case let .value(title, value, type): return valueRow(title: title, value: value, type: type, index: index, isFirst: isFirst, isLast: isLast)
        case let .address(title, valueTitle, value): return hexRow(title: title, valueTitle: valueTitle, value: value, index: index, isFirst: isFirst, isLast: isLast)
        case .input(let value): return hexRow(title: "Input", valueTitle: value, value: value, index: index, isFirst: isFirst, isLast: isLast)
        case let .warning(title, value): return warningRow(title: title, value: value, index: index, isFirst: isFirst, isLast: isLast)
        }
    }

    private func section(sectionViewItem: SendEvmTransactionViewModel.SectionViewItem, index: Int) -> SectionProtocol {
        var headerState: ViewState<BottomDescriptionHeaderFooterView>?

        if index == 0, let topDescription = topDescription?.localized {
            headerState = .cellType(hash: "top_description", binder: { view in
                view.bind(text: topDescription)
            }, dynamicHeight: { [weak self] containerWidth in
                BottomDescriptionHeaderFooterView.height(containerWidth: self?.view.width ?? 0, text: topDescription)
            })
        }

        return Section(
                id: "section_\(index)",
                headerState: headerState ?? .margin(height: .margin12),
                rows: sectionViewItem.viewItems.enumerated().map { index, viewItem in
                    row(viewItem: viewItem, index: index, isFirst: index == 0, isLast: index == sectionViewItem.viewItems.count - 1)
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
                                cell: estimatedFeeCell,
                                id: "estimated-fee",
                                height: estimatedFeeCell.cellHeight
                        ),
                        StaticRow(
                                cell: maxFeeCell,
                                id: "fee",
                                height: maxFeeCell.cellHeight
                        )
                    ]
            ),
            Section(
                    id: "fee-priority",
                    headerState: .margin(height: 6),
                    footerState: .margin(height: .margin32),
                    rows: [
                        StaticRow(
                                cell: feePriorityCell,
                                id: "fee-priority",
                                height: feePriorityCell.cellHeight
                        ),
                        StaticRow(
                                cell: errorCell,
                                id: "error",
                                dynamicHeight: { [weak self] width in
                                    self?.errorCell.cellHeight(width: width) ?? 0
                                }
                        )
                    ]
            )
        ]

        return transactionSections + feeSections
    }

}

extension SendEvmTransactionViewController: ISendFeePriorityCellDelegate {

    func open(viewController: UIViewController) {
        present(viewController, animated: true)
    }

    func onChangeHeight() {
        reloadTable()
    }

}
