import UIKit
import SnapKit
import SectionsTableView
import ThemeKit
import RxSwift
import RxCocoa
import UIExtensions

class SwapConfirmationView: ThemeViewController, SectionsDataSource {
    private let disposeBag = DisposeBag()

    private let presenter: Swap2ConfirmationPresenter
    private let delegate: ISwapConfirmationDelegate
    private let tableView = SectionsTableView(style: .grouped)

    private var amountViewItem: SwapModule.ConfirmationAmountViewItem?
    private var additionalViewItems = [SwapModule.ConfirmationAdditionalViewItem]()

    init(presenter: Swap2ConfirmationPresenter, delegate: ISwapConfirmationDelegate) {
        self.presenter = presenter
        self.delegate = delegate

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func subscribeToPresenter() {

        subscribe(disposeBag, presenter.isLoading) { [weak self] in self?.handleLoading() }
        subscribe(disposeBag, presenter.success) {
            HudHelper.instance.showSuccess()
        }
        subscribe(disposeBag, presenter.error) {
            HudHelper.instance.showError(title: $0?.smartDescription)
        }

        subscribe(disposeBag, presenter.amountData) { [weak self] in self?.handle(amountData: $0) }
        subscribe(disposeBag, presenter.additionalData) { [weak self] in self?.handle(additionalData: $0) }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "send.confirmation.title".localized

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

    @objc private func onTapCancel() {
        delegate.onCancel()
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
                            self?.onSwapTap()
                        }
                    }
            )
        ]))

        return sections
    }

    private func onSwapTap() {
        delegate.onSwap()
    }

}

extension SwapConfirmationView {

    func handleLoading() {
        HudHelper.instance.showSpinner()
    }

    func handle(amountData: SwapModule.ConfirmationAmountViewItem?) {
        self.amountViewItem = amountData

        tableView.reload()
    }

    func handle(additionalData: [SwapModule.ConfirmationAdditionalViewItem]) {
        self.additionalViewItems = additionalData

        tableView.reload()
    }

}
