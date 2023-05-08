import UIKit
import ThemeKit
import SnapKit
import SectionsTableView
import RxSwift
import RxCocoa
import ComponentKit

class Eip1559EvmFeeDataSource {
    private let viewModel: Eip1559EvmFeeViewModel
    private let disposeBag = DisposeBag()

    private let feeCell: FeeCell
    private var gasLimitCell = BaseThemeCell()
    private var baseFeeCell = BaseThemeCell()
    private var maxGasPriceCell = StepperAmountInputCell(allowFractionalNumbers: true)
    private var tipsCell = StepperAmountInputCell(allowFractionalNumbers: true)

    weak var tableView: SectionsTableView?
    var onOpenInfo: ((String, String) -> ())? = nil
    var onUpdateAlteredState: (() -> ())? = nil

    init(viewModel: Eip1559EvmFeeViewModel) {
        self.viewModel = viewModel

        feeCell = FeeCell(viewModel: viewModel, title: "fee_settings.network_fee".localized)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func viewDidLoad() {
        feeCell.set(backgroundStyle: .lawrence, isFirst: true, isLast: false)
        gasLimitCell.set(backgroundStyle: .lawrence, isFirst: false, isLast: false)
        baseFeeCell.set(backgroundStyle: .lawrence, isFirst: false, isLast: true)

        feeCell.onOpenInfo = { [weak self] in
            self?.onOpenInfo?("fee_settings.network_fee".localized, "fee_settings.network_fee.info".localized)
        }
        syncGasLimitCell()
        syncBaseFeeCell()

        subscribe(disposeBag, viewModel.gasLimitDriver) { [weak self] value in self?.syncGasLimitCell(value: value) }
        subscribe(disposeBag, viewModel.currentBaseFeeDriver) { [weak self] value in self?.syncBaseFeeCell(value: value) }
        subscribe(disposeBag, viewModel.maxGasPriceDriver) { [weak self] value in self?.maxGasPriceCell.value = value }
        subscribe(disposeBag, viewModel.tipsDriver) { [weak self] value in self?.tipsCell.value = value }
        subscribe(disposeBag, viewModel.alteredStateSignal) { [weak self] in self?.onUpdateAlteredState?() }
        subscribe(disposeBag, viewModel.cautionTypeDriver) { [weak self] in
            self?.maxGasPriceCell.set(cautionType: $0)
            self?.tipsCell.set(cautionType: $0)
        }

        maxGasPriceCell.onChangeValue = { [weak self] value in self?.viewModel.set(maxGasPrice: value) }
        tipsCell.onChangeValue = { [weak self] value in self?.viewModel.set(tips: value) }
    }

    private func syncGasLimitCell(value: String? = nil) {
        CellBuilderNew.buildStatic(
                cell: gasLimitCell,
                rootElement: .hStack([
                    .secondaryButton { [weak self] component in
                        component.button.set(style: .transparent2, image: UIImage(named: "circle_information_20"))
                        component.button.setTitle("fee_settings.gas_limit".localized, for: .normal)
                        component.onTap = {
                            self?.onOpenInfo?("fee_settings.gas_limit".localized, "fee_settings.gas_limit.info".localized)
                        }
                    },
                    .textElement(text: .subhead1(value), parameters: [.rightAlignment])
                ])
        )
    }

    private func syncBaseFeeCell(value: String? = nil) {
        CellBuilderNew.buildStatic(
                cell: baseFeeCell,
                rootElement: .hStack([
                    .secondaryButton { [weak self] component in
                        component.button.set(style: .transparent2, image: UIImage(named: "circle_information_20"))
                        component.button.setTitle("fee_settings.base_fee".localized, for: .normal)
                        component.onTap = {
                            self?.onOpenInfo?("fee_settings.base_fee".localized, "fee_settings.base_fee.info".localized)
                        }
                    },
                    .textElement(text: .subhead1(value), parameters: [.rightAlignment])
                ])
        )
    }

}

extension Eip1559EvmFeeDataSource: IEvmSendSettingsDataSource {

    var altered: Bool {
        viewModel.altered
    }

    var buildSections: [SectionProtocol] {
        guard let tableView = tableView else {
            return []
        }

        let feeSections: [SectionProtocol] = [
            Section(
                    id: "fee",
                    headerState: .margin(height: .margin12),
                    rows: [
                        StaticRow(
                                cell: feeCell,
                                id: "fee",
                                height: .heightDoubleLineCell
                        ),
                        StaticRow(
                                cell: gasLimitCell,
                                id: "gas-limit",
                                height: .heightCell48
                        ),
                        StaticRow(
                                cell: baseFeeCell,
                                id: "base-fee",
                                height: .heightCell48

                        )
                    ]
            )
        ]

        let maxGasPriceSections: [SectionProtocol] = [
            Section(
                    id: "max-gas-price",
                    headerState: .margin(height: .margin24),
                    rows: [
                        tableView.subtitleWithInfoButtonRow(text: "fee_settings.max_fee_rate".localized + " (Gwei)", uppercase: false) { [weak self] in
                            self?.onOpenInfo?("fee_settings.max_fee_rate".localized, "fee_settings.max_fee_rate.info".localized)
                        },
                        StaticRow(
                                cell: maxGasPriceCell,
                                id: "max-gas-price",
                                height: .heightCell48
                        )
                    ]
            )
        ]

        let tipsSections: [SectionProtocol] = [
            Section(
                    id: "tips",
                    headerState: .margin(height: .margin24),
                    rows: [
                        tableView.subtitleWithInfoButtonRow(text: "fee_settings.tips".localized + " (Gwei)", uppercase: false) { [weak self] in
                            self?.onOpenInfo?("fee_settings.tips".localized, "fee_settings.tips.info".localized)
                        },
                        StaticRow(
                                cell: tipsCell,
                                id: "tips",
                                height: .heightCell48
                        )
                    ]
            )
        ]

        return feeSections + maxGasPriceSections + tipsSections
    }

    func onTapReset() {
        viewModel.reset()
    }

}
