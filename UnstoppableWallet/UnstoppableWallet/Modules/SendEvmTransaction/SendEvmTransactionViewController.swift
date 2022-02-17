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

        subscribe(disposeBag, transactionViewModel.cautionsDriver) { [weak self] in self?.handle(cautions: $0) }
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

    func handleSendSuccess(transactionHash: Data) {
        HudHelper.instance.showSuccess(title: "alert.success_action".localized)

        dismiss(animated: true)
    }

    private func openFeeSettings() {
        guard let controller = EvmFeeModule.viewController(feeViewModel: feeViewModel) else {
            return
        }

        present(controller, animated: true)
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

    private func row(viewItem: SendEvmTransactionViewModel.ViewItem, index: Int, isFirst: Bool, isLast: Bool) -> RowProtocol {
        switch viewItem {
        case let .subhead(title, value): return subheadRow(title: title, value: value, index: index, isFirst: isFirst, isLast: isLast)
        case let .value(title, value, type): return valueRow(title: title, value: value, type: type, index: index, isFirst: isFirst, isLast: isLast)
        case let .address(title, valueTitle, value): return hexRow(title: title, valueTitle: valueTitle, value: value, index: index, isFirst: isFirst, isLast: isLast)
        case .input(let value): return hexRow(title: "Input", valueTitle: value, value: value, index: index, isFirst: isFirst, isLast: isLast)
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
