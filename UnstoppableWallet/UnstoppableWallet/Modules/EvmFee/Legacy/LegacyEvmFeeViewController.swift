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

    private let maxFeeCell: FeeCell
    private var gasLimitCell = BaseSelectableThemeCell()
    private var gasPriceCell = BaseSelectableThemeCell()
    private let gasPriceSliderCell: FeeSliderCell
    private let cautionCell = TitledHighlightedDescriptionCell()
    private let doneButton = PrimaryButton()

    private var loaded = false

    init(viewModel: LegacyEvmFeeViewModel) {
        self.viewModel = viewModel

        maxFeeCell = FeeCell(viewModel: viewModel)
        gasPriceSliderCell = FeeSliderCell(sliderDriver: viewModel.gasPriceSliderDriver)

        super.init()

        gasPriceSliderCell.onFinishTracking = { [weak self] value in self?.viewModel.set(value: value) }
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
        }

        doneButton.set(style: .yellow)
        doneButton.setTitle("button.done".localized, for: .normal)
        doneButton.addTarget(self, action: #selector(onTapDone), for: .touchUpInside)

        gasLimitCell.set(backgroundStyle: .lawrence, isFirst: true, isLast: false)
        CellBuilder.build(cell: gasLimitCell, elements: [.image20, .text, .text])
        gasLimitCell.bind(index: 0, block: { (component: ImageComponent) in
            component.imageView.image = UIImage(named: "circle_information_20")
        })
        gasLimitCell.bind(index: 1, block: { (component: TextComponent) in
            component.font = .subhead2
            component.textColor = .themeGray
            component.text = "fee_settings.gas_limit".localized
        })
        gasLimitCell.bind(index: 2, block: { (component: TextComponent) in
            component.font = .subhead1
            component.textColor = .themeLeah
        })

        gasPriceCell.set(backgroundStyle: .lawrence, isFirst: false, isLast: false)
        CellBuilder.build(cell: gasPriceCell, elements: [.image20, .text, .text])
        gasPriceCell.bind(index: 0, block: { (component: ImageComponent) in
            component.imageView.image = UIImage(named: "circle_information_20")
        })
        gasPriceCell.bind(index: 1, block: { (component: TextComponent) in
            component.font = .subhead2
            component.textColor = .themeGray
            component.text = "fee_settings.gas_price".localized
        })
        gasPriceCell.bind(index: 2, block: { (component: TextComponent) in
            component.font = .subhead1
            component.textColor = .themeLeah
        })

        gasPriceSliderCell.set(backgroundStyle: .lawrence, isFirst: false, isLast: true)

        subscribe(disposeBag, viewModel.cautionDriver) { [weak self] in self?.handle(caution: $0) }
        subscribe(disposeBag, viewModel.gasLimitDriver) { [weak self] value in
            self?.gasLimitCell.bind(index: 2, block: { (component: TextComponent) in
                component.text = value
            })
        }
        subscribe(disposeBag, viewModel.gasPriceDriver) { [weak self] value in
            self?.gasPriceCell.bind(index: 2, block: { (component: TextComponent) in
                component.text = value
            })
        }
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
        let viewController = InformationModule.description(title: title, text: description)
        present(viewController, animated: true)
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
                                height: .heightCell48,
                                autoDeselect: true,
                                action: { [weak self] in
                                    self?.openInfo(title: "fee_settings.max_fee".localized, description: "fee_settings.max_fee.info".localized)
                                }
                        )
                    ]
            )
        ]

        let gasDataSections: [SectionProtocol] = [
            Section(
                id: "gas-data",
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
                            cell: gasPriceCell,
                            id: "gas-price",
                            height: .heightCell48,
                            autoDeselect: true,
                            action: { [weak self] in
                                self?.openInfo(title: "fee_settings.gas_price".localized, description: "fee_settings.gas_price.info".localized)
                            }
                    ),
                    StaticRow(
                            cell: gasPriceSliderCell,
                            id: "gas-price-slider",
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
