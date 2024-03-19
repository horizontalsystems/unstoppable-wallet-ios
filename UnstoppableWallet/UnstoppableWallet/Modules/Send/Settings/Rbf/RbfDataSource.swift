import ComponentKit
import RxCocoa
import RxSwift
import SectionsTableView
import SnapKit
import ThemeKit
import UIKit

class RbfDataSource {
    private let viewModel: RbfViewModel
    private let disposeBag = DisposeBag()

    weak var tableView: SectionsTableView?
    private let switchCell = BaseSelectableThemeCell()

    var onOpenInfo: ((String, String) -> Void)?
    var present: ((UIViewController) -> Void)?
    var onUpdateAlteredState: (() -> Void)?
    var onCaution: ((TitledCaution?) -> Void)?

    init(viewModel: RbfViewModel) {
        self.viewModel = viewModel
    }

    func viewDidLoad() {
        switchCell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
        subscribe(disposeBag, viewModel.alteredStateSignal) { [weak self] in
            self?.sync()
            self?.onUpdateAlteredState?()
        }

        sync()
    }

    private func sync() {
        guard let tableView else {
            return
        }

        let elements = tableView.universalImage32Elements(
            image: nil,
            title: .body("fee_settings.replace_by_fee".localized),
            value: nil,
            accessoryType: .switch(
                isOn: viewModel.enabled,
                onSwitch: { [weak self] _ in
                    self?.viewModel.onToggle()
                }
            )
        )

        CellBuilderNew.buildStatic(cell: switchCell, rootElement: .hStack(elements))
    }
}

extension RbfDataSource: ISendSettingsDataSource {
    var altered: Bool {
        viewModel.altered
    }

    var buildSections: [SectionProtocol] {
        guard let tableView else {
            return []
        }

        return [
            Section(
                id: "rbf",
                headerState: .margin(height: .margin24),
                rows: [
                    StaticRow(
                        cell: switchCell,
                        id: "rbf-cell",
                        height: .heightCell56
                    ),
                    tableView.descriptionRow(
                        id: "rbf-description-cell",
                        text: "fee_settings.replace_by_fee.description".localized,
                        font: .subhead2,
                        textColor: .themeGray,
                        ignoreBottomMargin: true
                    ),
                ]
            ),
        ]
    }

    func onTapReset() {
        viewModel.reset()
    }
}
