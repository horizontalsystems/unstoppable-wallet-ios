import UIKit
import SnapKit
import SectionsTableView
import ThemeKit
import RxSwift
import RxCocoa

class SwapConfirmationView: ThemeViewController {
    private let disposeBag = DisposeBag()

    private let viewModel: SwapConfirmationViewModel
    private let tableView = SectionsTableView(style: .grouped)

    private var amountViewItem: SwapModule.ConfirmationAmountViewItem?
    private var additionalViewItems = [SwapModule.ConfirmationAdditionalViewItem]()

    init(viewModel: SwapConfirmationViewModel) {
        self.viewModel = viewModel

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func subscribeToPresenter() {

        subscribe(disposeBag, viewModel.loadingSignal) { HudHelper.instance.showSpinner(userInteractionEnabled: false) }
        subscribe(disposeBag, viewModel.errorSignal) { HudHelper.instance.showError(title: $0.smartDescription) }
        subscribe(disposeBag, viewModel.completedSignal) { [weak self] in self?.showSuccess() }

        subscribe(disposeBag, viewModel.amountData) { [weak self] in self?.handle(amountViewItem: $0) }
        subscribe(disposeBag, viewModel.additionalData) { [weak self] in self?.handle(additionalViewItems: $0) }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "confirm".localized

        view.addSubview(tableView)

        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.registerCell(forClass: SwapConfirmationAmountCell.self)
        tableView.registerCell(forClass: AdditionalDataCell.self)
        tableView.registerCell(forClass: ButtonCell.self)
        tableView.sectionDataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.delaysContentTouches = false

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .done, target: self, action: #selector(onTapCancel))


        subscribeToPresenter()
    }

    private var swapAmountSectionRows: [RowProtocol] {
        var rows = [RowProtocol]()

        guard let viewItem = amountViewItem else {
            return rows
        }

        rows.append(Row<SwapConfirmationAmountCell>(
                id: "swap_amount",
                height: SwapConfirmationAmountCell.height,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
                    cell.bind(payTitle: "swap.confirmation.pay".localized(viewItem.payTitle),
                            payValue: viewItem.payValue,
                            getTitle: "swap.confirmation.get".localized(viewItem.getTitle),
                            getValue: viewItem.getValue)
                })
        )
        return rows
    }

    private var swapAdditionalDataRows: [RowProtocol] {
        var rows = [RowProtocol]()

        additionalViewItems.forEach { data in
            rows.append(Row<AdditionalDataCell>(
                    id: data.title,
                    height: AdditionalDataCell.height,
                    bind: { cell, _ in
                       cell.bind(title: data.title.localized, value: data.value)
                    }
            ))
        }
        return rows
    }

    @objc private func onTapCancel() {
        dismiss(animated: true)
    }

    private func onTapSwap() {
        viewModel.swap()
    }

    private func showSuccess() {
        HudHelper.instance.showSuccess()

        dismiss(animated: true)
    }

}

extension SwapConfirmationView: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        sections.append(Section(id: "swap_amount_section", headerState: .margin(height: .margin2x), rows: swapAmountSectionRows))
        sections.append(Section(id: "swap_additional_data_section", headerState: .margin(height: .margin3x), rows: swapAdditionalDataRows))
        sections.append(Section(id: "button_section", rows: [
            Row<ButtonCell>(
                id: "swap_row",
                height: ButtonCell.height(style: .primaryYellow),
                bind: { [weak self] cell, _ in
                    cell.bind(style: .primaryYellow, title: "swap.confirmation.swap_button".localized) { [weak self] in
                        self?.onTapSwap()
                    }
                }
            )
        ]))

        return sections
    }

    func handle(amountViewItem: SwapModule.ConfirmationAmountViewItem?) {
        self.amountViewItem = amountViewItem

        tableView.reload()
    }

    func handle(additionalViewItems: [SwapModule.ConfirmationAdditionalViewItem]) {
        self.additionalViewItems = additionalViewItems

        tableView.reload()
    }

}
