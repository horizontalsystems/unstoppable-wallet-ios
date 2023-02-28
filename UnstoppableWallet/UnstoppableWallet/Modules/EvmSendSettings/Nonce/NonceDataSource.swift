import UIKit
import ThemeKit
import SnapKit
import SectionsTableView
import RxSwift
import RxCocoa
import ComponentKit

class NonceDataSource {
    private let viewModel: NonceViewModel
    private let disposeBag = DisposeBag()

    private let nonceCell = StepperAmountInputCell(allowFractionalNumbers: false)

    weak var tableView: SectionsTableView?
    var onOpenInfo: ((String, String) -> ())? = nil
    var onUpdateAlteredState: (() -> ())? = nil

    init(viewModel: NonceViewModel) {
        self.viewModel = viewModel
    }

    func viewDidLoad() {
        nonceCell.onChangeValue = { [weak self] value in self?.viewModel.set(value: value) }

        subscribe(disposeBag, viewModel.alteredStateSignal) { [weak self] in self?.onUpdateAlteredState?() }
        subscribe(disposeBag, viewModel.valueDriver) { [weak self] in self?.nonceCell.value = $0 }
        subscribe(disposeBag, viewModel.cautionTypeDriver) { [weak self] in self?.nonceCell.set(cautionType: $0) }
    }

}

extension NonceDataSource: IEvmSendSettingsDataSource {

    var altered: Bool {
        viewModel.altered
    }

    var buildSections: [SectionProtocol] {
        guard let tableView = tableView, !viewModel.frozen else {
            return []
        }

        return [
            Section(
                    id: "nonce",
                    headerState: .margin(height: .margin24),
                    rows: [
                        tableView.subtitleWithInfoButtonRow(text: "evm_send_settings.nonce".localized, uppercase: false) { [weak self] in
                            self?.onOpenInfo?("evm_send_settings.nonce".localized, "evm_send_settings.nonce.info".localized)
                        },
                        StaticRow(
                                cell: nonceCell,
                                id: "nonce-input",
                                height: nonceCell.cellHeight
                        )
                    ]
            )
        ]
    }

    func onTapReset() {
        viewModel.reset()
    }

}
