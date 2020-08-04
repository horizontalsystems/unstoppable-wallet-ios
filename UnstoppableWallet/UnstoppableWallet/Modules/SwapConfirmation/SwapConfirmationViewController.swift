import UIKit
import SnapKit
import SectionsTableView
import ThemeKit
import CurrencyKit

class SwapConfirmationViewController: ThemeViewController, SectionsDataSource {
    private let delegate: ISwapConfirmationViewDelegate

    private let tableView = SectionsTableView(style: .grouped)

    private var viewItem: SwapConfirmationModule.ViewItem?

    init(delegate: ISwapConfirmationViewDelegate) {
        self.delegate = delegate

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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

        delegate.onViewDidLoad()
    }

    @objc private func onTapCancel() {
        delegate.onCancelClicked()
    }

    private var swapAmountSectionRows: [RowProtocol] {
        var rows = [RowProtocol]()

        guard let viewItem = viewItem else {
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

        guard let viewItem = viewItem else {
            return rows
        }

        viewItem.additionalDataItems.forEach { data in
            rows.append(Row<AdditionalDataCell>(
                    id: data.title,
                    height: AdditionalDataCell.height,
                    bind: { cell, _ in
                        cell.bind(title: data.title.localized, value: data.value)
                        if let color = data.color {
                            cell.set(valueColor: color)
                        }
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
        delegate.onSwapClicked()
    }

}

extension SwapConfirmationViewController: ISwapConfirmationView {

    func set(viewItem: SwapConfirmationModule.ViewItem) {
        self.viewItem = viewItem

        tableView.reload()
    }

}
