import UIKit
import ThemeKit
import SnapKit
import SectionsTableView
import RxSwift
import RxCocoa
import ComponentKit

class Eip1559EvmFeeViewController: ThemeViewController {
    let disposeBag = DisposeBag()

    private let viewModel: Eip1559EvmFeeViewModel

    private let tableView = SectionsTableView(style: .grouped)
    let bottomWrapper = BottomGradientHolder()

    private let maxFeeCell: FeeCell
    private var gasLimitCell = A7Cell()
    private var currentBaseFeeCell = A7Cell()
    private var baseFeeCell = A7Cell()
    private let baseFeeSliderCell: FeeSliderCell
    private var tipsCell = A7Cell()
    private let tipsSliderCell: FeeSliderCell
    private var cautionViewItems = [TitledCaution]()
    private let doneButton = ThemeButton()

    init(viewModel: Eip1559EvmFeeViewModel) {
        self.viewModel = viewModel

        maxFeeCell = FeeCell(feeViewModel: viewModel)
        baseFeeSliderCell = FeeSliderCell(sliderDriver: viewModel.baseFeeSliderDriver)
        tipsSliderCell = FeeSliderCell(sliderDriver: viewModel.tipsSliderDriver)

        super.init()

        maxFeeCell.delegate = self
        baseFeeSliderCell.onFinishTracking = { [weak self] value in self?.viewModel.set(baseFee: value) }
        tipsSliderCell.onFinishTracking = { [weak self] value in self?.viewModel.set(tips: value) }
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

        currentBaseFeeCell.set(backgroundStyle: .transparent, isFirst: true, isLast: true)
        currentBaseFeeCell.titleColor = .themeGray
        currentBaseFeeCell.set(titleImageSize: .iconSize24)
        currentBaseFeeCell.valueColor = .themeGray
        currentBaseFeeCell.selectionStyle = .none
        currentBaseFeeCell.title = "fee_settings.current_base_fee".localized
        currentBaseFeeCell.titleImage = UIImage(named: "circle_information_20")

        baseFeeCell.set(backgroundStyle: .transparent, isFirst: true, isLast: true)
        baseFeeCell.titleColor = .themeGray
        baseFeeCell.set(titleImageSize: .iconSize24)
        baseFeeCell.valueColor = .themeGray
        baseFeeCell.selectionStyle = .none
        baseFeeCell.title = "fee_settings.base_fee".localized
        baseFeeCell.titleImage = UIImage(named: "circle_information_20")

        tipsCell.set(backgroundStyle: .transparent, isFirst: true, isLast: true)
        tipsCell.titleColor = .themeGray
        tipsCell.set(titleImageSize: .iconSize24)
        tipsCell.valueColor = .themeGray
        tipsCell.selectionStyle = .none
        tipsCell.title = "fee_settings.tips".localized
        tipsCell.titleImage = UIImage(named: "circle_information_20")

        subscribe(disposeBag, viewModel.currentBaseFeeDriver) { [weak self] in self?.currentBaseFeeCell.value = $0 }
        subscribe(disposeBag, viewModel.gasLimitDriver) { [weak self] in self?.gasLimitCell.value = $0 }
        subscribe(disposeBag, viewModel.baseFeeDriver) { [weak self] in self?.baseFeeCell.value = $0 }
        subscribe(disposeBag, viewModel.tipsDriver) { [weak self] in self?.tipsCell.value = $0 }
        subscribe(disposeBag, viewModel.cautionsDriver) { [weak self] in self?.handle(cautions: $0) }

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

extension Eip1559EvmFeeViewController: SectionsDataSource {

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
            ),
            Section(
                    id: "current-base-fee",
                    headerState: .margin(height: 6),
                    footerState: .margin(height: .margin32),
                    rows: [
                        StaticRow(
                                cell: gasLimitCell,
                                id: "gas-limit",
                                height: gasLimitCell.cellHeight
                        )
                    ]
            )
        ]

        let gasDataSections: [SectionProtocol] = [
            Section(
                    id: "gas-data",
                    headerState: .margin(height: 2),
                    footerState: .margin(height: .margin32),
                    rows: [
                        StaticRow(
                                cell: currentBaseFeeCell,
                                id: "current-base-fee-cell",
                                height: currentBaseFeeCell.cellHeight
                        ),
                        StaticRow(
                                cell: baseFeeCell,
                                id: "base-fee",
                                height: baseFeeCell.cellHeight
                        ),
                        StaticRow(
                                cell: baseFeeSliderCell,
                                id: "base-fee-slider",
                                height: baseFeeSliderCell.cellHeight
                        ),
                        StaticRow(
                                cell: tipsCell,
                                id: "tips",
                                height: tipsCell.cellHeight
                        ),
                        StaticRow(
                                cell: tipsSliderCell,
                                id: "tips-slider",
                                height: tipsSliderCell.cellHeight
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

extension Eip1559EvmFeeViewController: IFeeSliderCellDelegate {

    func open(viewController: UIViewController) {
        present(viewController, animated: true)
    }

}
