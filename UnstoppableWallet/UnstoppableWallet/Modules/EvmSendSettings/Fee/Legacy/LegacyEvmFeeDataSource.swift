import UIKit
import ThemeKit
import SnapKit
import SectionsTableView
import RxSwift
import RxCocoa
import ComponentKit

class LegacyEvmFeeDataSource {
    private let viewModel: LegacyEvmFeeViewModel
    private let disposeBag = DisposeBag()

    private let feeCell: FeeCell
    private var gasLimitCell = BaseThemeCell()
    private var gasPriceCell = StepperAmountInputCell(allowFractionalNumbers: true)

    weak var tableView: SectionsTableView?
    var onOpenInfo: ((String, String) -> ())? = nil
    var onUpdateAlteredState: (() -> ())? = nil

    init(viewModel: LegacyEvmFeeViewModel) {
        self.viewModel = viewModel

        feeCell = FeeCell(viewModel: viewModel, title: "fee_settings.network_fee".localized)
    }

    func viewDidLoad() {
        feeCell.set(backgroundStyle: .lawrence, isFirst: true, isLast: false)
        gasLimitCell.set(backgroundStyle: .lawrence, isFirst: false, isLast: true)

        feeCell.onOpenInfo = { [weak self] in
            self?.onOpenInfo?("fee_settings.network_fee".localized, "fee_settings.network_fee.info".localized)
        }
        syncGasLimitCell()

        subscribe(disposeBag, viewModel.gasLimitDriver) { [weak self] in self?.syncGasLimitCell(value: $0) }
        subscribe(disposeBag, viewModel.gasPriceDriver) { [weak self] in self?.gasPriceCell.value = $0 }
        subscribe(disposeBag, viewModel.alteredStateSignal) { [weak self] in self?.onUpdateAlteredState?() }
        subscribe(disposeBag, viewModel.cautionTypeDriver) { [weak self] in self?.gasPriceCell.set(cautionType: $0) }

        gasPriceCell.onChangeValue = { [weak self] value in self?.viewModel.set(value: value) }
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

}

extension LegacyEvmFeeDataSource: IEvmSendSettingsDataSource {

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
                        )
                    ]
            )
        ]

        let gasDataSections: [SectionProtocol] = [
            Section(
                    id: "gas-price",
                    headerState: .margin(height: .margin24),
                    rows: [
                        tableView.subtitleWithInfoButtonRow(text: "fee_settings.gas_price".localized + " (Gwei)", uppercase: false) { [weak self] in
                            self?.onOpenInfo?("fee_settings.gas_price".localized, "fee_settings.gas_price.info".localized)
                        },
                        StaticRow(
                                cell: gasPriceCell,
                                id: "gas-price",
                                height: .heightCell48
                        )
                    ]
            )
        ]

        return feeSections + gasDataSections
    }

    func onTapReset() {
        viewModel.reset()
    }

}
