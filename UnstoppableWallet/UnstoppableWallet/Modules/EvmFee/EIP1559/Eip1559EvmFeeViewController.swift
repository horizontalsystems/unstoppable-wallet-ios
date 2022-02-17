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
    private var gasLimitCell = BaseSelectableThemeCell()
    private var currentBaseFeeCell = BaseThemeCell()
    private var baseFeeCell = BaseSelectableThemeCell()
    private let baseFeeSliderCell: FeeSliderCell
    private var tipsCell = BaseSelectableThemeCell()
    private let tipsSliderCell: FeeSliderCell
    private let cautionCell = TitledHighlightedDescriptionCell()
    private let doneButton = ThemeButton()

    private var loaded = false

    init(viewModel: Eip1559EvmFeeViewModel) {
        self.viewModel = viewModel

        maxFeeCell = FeeCell(viewModel: viewModel)
        baseFeeSliderCell = FeeSliderCell(sliderDriver: viewModel.baseFeeSliderDriver)
        tipsSliderCell = FeeSliderCell(sliderDriver: viewModel.tipsSliderDriver)

        super.init()

        baseFeeSliderCell.onFinishTracking = { [weak self] value in self?.viewModel.set(baseFee: value) }
        tipsSliderCell.onFinishTracking = { [weak self] value in self?.viewModel.set(tips: value) }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bindSelectableCell(cell: BaseThemeCell, title: String, subscribeTo driver: Driver<String>, isFirst: Bool = false, isLast: Bool = false) {
        cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
        CellBuilder.build(cell: cell, elements: [.image20, .text, .text])
        cell.bind(index: 0, block: { (component: ImageComponent) in
            component.imageView.image = UIImage(named: "circle_information_20")
        })
        cell.bind(index: 1, block: { (component: TextComponent) in
            component.set(style: .d1)
            component.text = title
        })
        cell.bind(index: 2, block: { (component: TextComponent) in
            component.set(style: .c2)
        })
        subscribe(disposeBag, driver) { value in
            cell.bind(index: 2, block: { (component: TextComponent) in
                component.text = value
            })
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "fee_settings".localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.done".localized, style: .done, target: self, action: #selector(onTapDone))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "button.reset".localized, style: .plain, target: self, action: #selector(onTapReset))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.delaysContentTouches = false

        bindSelectableCell(cell: gasLimitCell, title: "fee_settings.gas_limit".localized, subscribeTo: viewModel.gasLimitDriver, isFirst: true, isLast: false)
        currentBaseFeeCell.set(backgroundStyle: .lawrence, isFirst: false, isLast: true)
        CellBuilder.build(cell: currentBaseFeeCell, elements: [.text, .text])
        currentBaseFeeCell.bind(index: 0, block: { (component: TextComponent) in
            component.set(style: .d1)
            component.text = "fee_settings.current_base_fee".localized
        })
        currentBaseFeeCell.bind(index: 1, block: { (component: TextComponent) in
            component.set(style: .c2)
        })
        subscribe(disposeBag, viewModel.currentBaseFeeDriver) { [weak self] value in
           self?.currentBaseFeeCell.bind(index: 1, block: { (component: TextComponent) in
                component.text = value
            })
        }

        baseFeeCell.set(backgroundStyle: .lawrence, isFirst: true, isLast: false)
        CellBuilder.build(cell: baseFeeCell, elements: [.image20, .text, .text])
        baseFeeCell.bind(index: 0, block: { (component: ImageComponent) in
            component.imageView.image = UIImage(named: "circle_information_20")
        })
        baseFeeCell.bind(index: 1, block: { (component: TextComponent) in
            component.set(style: .d1)
            component.text = "fee_settings.base_fee".localized
        })
        baseFeeCell.bind(index: 2, block: { (component: TextComponent) in
            component.set(style: .c2)
        })
        subscribe(disposeBag, viewModel.baseFeeDriver) { [weak self] value in
            self?.baseFeeCell.bind(index: 2, block: { (component: TextComponent) in
                component.text = value
            })
        }

        baseFeeSliderCell.set(backgroundStyle: .lawrence, isFirst: false, isLast: false)

        bindSelectableCell(cell: tipsCell, title: "fee_settings.tips".localized, subscribeTo: viewModel.tipsDriver, isFirst: false, isLast: false)
        tipsSliderCell.set(backgroundStyle: .lawrence, isFirst: false, isLast: true)

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

        subscribe(disposeBag, viewModel.cautionDriver) { [weak self] in self?.handle(caution: $0) }
        subscribe(disposeBag, viewModel.resetButtonActiveDriver) { [weak self] active in
            self?.navigationItem.leftBarButtonItem?.isEnabled = active
        }

        tableView.buildSections()

        loaded = true
    }

    @objc private func onTapDone() {
        dismiss(animated: true)
    }

    @objc private func onTapReset() {
        viewModel.reset()
    }

    private func handle(caution: TitledCaution?) {
        cautionCell.isVisible = caution != nil

        if let caution = caution {
            cautionCell.bind(caution: caution)
        }

        if loaded {
            UIView.animate(withDuration: 0.15) {
                self.tableView.beginUpdates()
                self.tableView.endUpdates()
            }
        }
    }

    private func openInfo(title: String, description: String) {
        let viewController = EvmGasDataInfoViewController(title: title, description: description)
        present(viewController.toBottomSheet, animated: true)
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
                                height: .heightCell48,
                                autoDeselect: true,
                                action: { [weak self] in
                                    self?.openInfo(title: "fee_settings.max_fee".localized, description: "fee_settings.max_fee.info".localized)
                                }
                        )
                    ]
            ),
            Section(
                    id: "gas-data-0",
                    headerState: .margin(height: .margin8),
                    rows: [
                        StaticRow(
                                cell: gasLimitCell,
                                id: "gas-limit",
                                height: .heightCell48,
                                autoDeselect: true,
                                action: { [weak self] in
                                    self?.openInfo(title: "fee_settings.gas_limit".localized, description: "fee_settings.gas_limit.info".localized)
                                }
                        ),
                        StaticRow(
                                cell: currentBaseFeeCell,
                                id: "current-base-fee-cell",
                                height: .heightCell48
                        )
                    ]
            )
        ]

        let gasDataSections: [SectionProtocol] = [
            Section(
                    id: "gas-data-1",
                    headerState: .margin(height: .margin8),
                    rows: [
                        StaticRow(
                                cell: baseFeeCell,
                                id: "base-fee",
                                height: .heightCell48,
                                autoDeselect: true,
                                action: { [weak self] in
                                    self?.openInfo(title: "fee_settings.base_fee".localized, description: "fee_settings.base_fee.info".localized)
                                }
                        ),
                        StaticRow(
                                cell: baseFeeSliderCell,
                                id: "base-fee-slider",
                                height: .heightCell48
                        ),
                        StaticRow(
                                cell: tipsCell,
                                id: "tips",
                                height: .heightCell48,
                                autoDeselect: true,
                                action: { [weak self] in
                                    self?.openInfo(title: "fee_settings.tips".localized, description: "fee_settings.tips.info".localized)
                                }
                        ),
                        StaticRow(
                                cell: tipsSliderCell,
                                id: "tips-slider",
                                height: .heightCell48
                        )
                    ]
            )
        ]

        let cautionsSections: [SectionProtocol] = [
            Section(
                    id: "caution",
                    headerState: .margin(height: .margin12),
                    rows: [
                        StaticRow(
                                cell: cautionCell,
                                id: "caution",
                                dynamicHeight: { [weak self] containerWidth in
                                    self?.cautionCell.cellHeight(containerWidth: containerWidth) ?? 0
                                }
                        )
                    ]
            )
        ]

        return feeSections + gasDataSections + cautionsSections
    }

}
