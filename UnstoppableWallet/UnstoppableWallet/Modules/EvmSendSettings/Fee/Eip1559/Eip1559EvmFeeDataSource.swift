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

    private let maxFeeCell: FeeCellNew
    private var gasLimitCell = BaseSelectableThemeCell()
    private var baseFeeCell = BaseSelectableThemeCell()
    private var maxGasPriceCell = StepperAmountInputCell(allowFractionalNumbers: true)
    private var tipsCell = StepperAmountInputCell(allowFractionalNumbers: true)

    weak var tableView: SectionsTableView?
    var onOpenInfo: ((String, String) -> ())? = nil
    var onUpdateAlteredState: (() -> ())? = nil

    init(viewModel: Eip1559EvmFeeViewModel) {
        self.viewModel = viewModel

        maxFeeCell = FeeCellNew(viewModel: viewModel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func viewDidLoad() {
        maxFeeCell.set(backgroundStyle: .lawrence, isFirst: true, isLast: false)
        gasLimitCell.set(backgroundStyle: .lawrence, isFirst: false, isLast: false)
        baseFeeCell.set(backgroundStyle: .lawrence, isFirst: false, isLast: true)

        subscribe(disposeBag, viewModel.gasLimitDriver) { [weak self] value in self?.syncGasLimitCell(value: value) }
        subscribe(disposeBag, viewModel.currentBaseFeeDriver) { [weak self] value in self?.syncBaseFeeCell(value: value) }
        subscribe(disposeBag, viewModel.maxGasPriceDriver) { [weak self] value in self?.maxGasPriceCell.value = value }
        subscribe(disposeBag, viewModel.tipsDriver) { [weak self] value in self?.tipsCell.value = value }
        subscribe(disposeBag, viewModel.alteredStateSignal) { [weak self] in self?.onUpdateAlteredState?() }

        maxGasPriceCell.onChangeValue = { [weak self] value in self?.viewModel.set(maxGasPrice: value) }
        tipsCell.onChangeValue = { [weak self] value in self?.viewModel.set(tips: value) }

        syncGasLimitCell()
        syncBaseFeeCell()
    }

    private func syncGasLimitCell(value: String? = nil) {
        CellBuilderNew.buildStatic(
                cell: gasLimitCell,
                rootElement: .hStack([
                    .textElement(text: .subhead2("fee_settings.gas_limit".localized), parameters: [.highHugging]),
                    .margin8,
                    .imageElement(image: .local(UIImage(named: "circle_information_20")), size: .image20),
                    .margin0,
                    .text { _ in },
                    .textElement(text: .subhead1(value), parameters: [.allCompression, .rightAlignment])
                ])
        )
    }

    private func syncBaseFeeCell(value: String? = nil) {
        CellBuilderNew.buildStatic(
                cell: baseFeeCell,
                rootElement: .hStack([
                    .textElement(text: .subhead2("fee_settings.current_base_fee".localized), parameters: [.highHugging]),
                    .margin8,
                    .imageElement(image: .local(UIImage(named: "circle_information_20")), size: .image20),
                    .margin0,
                    .text { _ in },
                    .textElement(text: .subhead1(value), parameters: [.allCompression, .rightAlignment])
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
                                cell: maxFeeCell,
                                id: "fee",
                                height: .heightDoubleLineCell,
                                autoDeselect: true,
                                action: { [weak self] in
                                    self?.onOpenInfo?("fee_settings.max_fee".localized, "fee_settings.max_fee.info".localized)
                                }
                        ),
                        StaticRow(
                                cell: gasLimitCell,
                                id: "gas-limit",
                                height: .heightCell48,
                                autoDeselect: true,
                                action: { [weak self] in
                                    self?.onOpenInfo?("fee_settings.gas_limit".localized, "fee_settings.gas_limit.info".localized)
                                }
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
                        tableView.subtitleWithInfoButtonRow(text: "fee_settings.max_fee".localized + " (Gwei/Gas)") { [weak self] in
                            self?.onOpenInfo?("fee_settings.max_fee".localized + " (Gwei/Gas)", "fee_settings.max_fee.info".localized)
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
                        tableView.subtitleWithInfoButtonRow(text: "fee_settings.tips".localized + " (Gwei/Gas)") { [weak self] in
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
