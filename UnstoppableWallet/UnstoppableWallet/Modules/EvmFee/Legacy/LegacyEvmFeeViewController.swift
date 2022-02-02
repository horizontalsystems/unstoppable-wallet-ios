import UIKit
import ThemeKit
import SnapKit
import SectionsTableView
import RxSwift
import RxCocoa
import ComponentKit

class LegacyEvmFeeViewController: ThemeViewController {
    let disposeBag = DisposeBag()

    private let viewModel: LegacyEvmFeeViewModel

    private let tableView = SectionsTableView(style: .grouped)
    let bottomWrapper = BottomGradientHolder()

    private let doneButton = ThemeButton()
    private let maxFeeCell: FeeCell
    private let feePriorityCell: FeeSliderCell

    private var cautionViewItems = [TitledCaution]()
    private var gasLimitCell = A7Cell()
    private var gasPriceCell = A7Cell()

    init(viewModel: LegacyEvmFeeViewModel) {
        self.viewModel = viewModel

        maxFeeCell = FeeCell(feeViewModel: viewModel)
        feePriorityCell = FeeSliderCell(viewModel: viewModel)

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "fee_settings".localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.done".localized, style: .done, target: self, action: #selector(onTapDone))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "button.reset".localized, style: .done, target: self, action: #selector(onTapReset))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.delaysContentTouches = false
        tableView.allowsSelection = false

        tableView.registerCell(forClass: A7Cell.self)
        tableView.registerCell(forClass: TitledHighlightedDescriptionCell.self)
        tableView.sectionDataSource = self

        view.addSubview(bottomWrapper)
        bottomWrapper.snp.makeConstraints { maker in
            maker.top.equalTo(tableView.snp.bottom).offset(-CGFloat.margin16)
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        bottomWrapper.addSubview(doneButton)
        doneButton.snp.makeConstraints { maker in
            maker.top.equalToSuperview().inset(CGFloat.margin32)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.bottom.equalToSuperview().inset(CGFloat.margin16)
            maker.height.equalTo(CGFloat.heightButton)
        }

        doneButton.apply(style: .primaryYellow)
        doneButton.setTitle("button.done".localized, for: .normal)
        doneButton.addTarget(self, action: #selector(onTapDone), for: .touchUpInside)

        gasLimitCell.set(backgroundStyle: .transparent, isFirst: true, isLast: true)
        gasLimitCell.titleColor = .themeGray
        gasLimitCell.set(titleImageSize: .iconSize24)
        gasLimitCell.valueColor = .themeGray
        gasLimitCell.selectionStyle = .none
        gasLimitCell.title = "fee_settings.gas_limit".localized
        gasLimitCell.titleImage = UIImage(named: "circle_information_20")

        gasPriceCell.set(backgroundStyle: .transparent, isFirst: true, isLast: true)
        gasPriceCell.titleColor = .themeGray
        gasPriceCell.set(titleImageSize: .iconSize24)
        gasPriceCell.valueColor = .themeGray
        gasPriceCell.selectionStyle = .none
        gasPriceCell.title = "fee_settings.gas_limit".localized
        gasPriceCell.titleImage = UIImage(named: "circle_information_20")

        subscribe(disposeBag, viewModel.cautionsDriver) { [weak self] in self?.handle(cautions: $0) }
        subscribe(disposeBag, viewModel.gasLimitDriver) { [weak self] in self?.gasLimitCell.value = $0 }
        subscribe(disposeBag, viewModel.gasPriceDriver) { [weak self] in self?.gasPriceCell.value = $0 }

        tableView.buildSections()
    }

    @objc private func onTapDone() {
        dismiss(animated: true)
    }

    @objc private func onTapReset() {
        viewModel.reset()
    }

    private func handle(cautions: [TitledCaution]) {
        cautionViewItems = cautions
        reloadTable()
    }

    private func errorRow(title: String, value: String, index: Int, isFirst: Bool, isLast: Bool) -> RowProtocol {
        Row<TitledHighlightedDescriptionCell>(
                id: title,
                dynamicHeight: { containerWidth in TitledHighlightedDescriptionCell.height(containerWidth: containerWidth, text: value) },
                bind: { cell, _ in
                    cell.titleIcon = UIImage(named: "warning_2_20")?.withRenderingMode(.alwaysTemplate)
                    cell.tintColor = .themeLucian
                    cell.titleText = title
                    cell.descriptionText = value
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

    private func reloadTable() {
        tableView.reload(animated: true)

        UIView.animate(withDuration: 0.2) {
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        }
    }

}

extension LegacyEvmFeeViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        let feeSections: [SectionProtocol] = [
            Section(
                    id: "fee",
                    headerState: .margin(height: .margin12),
                    rows: [
                        StaticRow(
                                cell: maxFeeCell,
                                id: "fee",
                                height: maxFeeCell.cellHeight
                        )
                    ]
            )
        ]

        let gasDataSections: [SectionProtocol] = [
            Section(
                id: "gas-data",
                headerState: .margin(height: 6),
                footerState: .margin(height: .margin32),
                rows: [
                    StaticRow(
                            cell: gasLimitCell,
                            id: "gas-limit",
                            height: gasLimitCell.cellHeight
                    ),
                    StaticRow(
                            cell: gasPriceCell,
                            id: "gas-price",
                            height: gasPriceCell.cellHeight
                    ),
                    StaticRow(
                            cell: feePriorityCell,
                            id: "fee-priority",
                            height: feePriorityCell.cellHeight
                    )
                ]
            )
        ]

        let cautionsSections: [SectionProtocol] = [
            Section(
                    id: "cautions",
                    headerState: .margin(height: .margin12),
                    rows: cautionViewItems.enumerated().map { index, caution in
                        switch caution.type {
                        case .error: return errorRow(title: caution.title, value: caution.text, index: index, isFirst: index == 0, isLast: index == cautionViewItems.count - 1)
                        case .warning: return warningRow(title: caution.title, value: caution.text, index: index, isFirst: index == 0, isLast: index == cautionViewItems.count - 1)
                        }
                    }
            )
        ]

        return feeSections + gasDataSections + cautionsSections
    }

}

extension LegacyEvmFeeViewController: ISendFeePriorityCellDelegate {

    func open(viewController: UIViewController) {
        present(viewController, animated: true)
    }

    func onChangeHeight() {
        reloadTable()
    }

}
