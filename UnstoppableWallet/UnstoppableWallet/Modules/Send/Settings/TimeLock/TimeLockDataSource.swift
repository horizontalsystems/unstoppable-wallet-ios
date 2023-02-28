import UIKit
import ThemeKit
import SnapKit
import SectionsTableView
import RxSwift
import RxCocoa
import ComponentKit

class TimeLockDataSource {
    private let viewModel: TimeLockViewModel
    private let disposeBag = DisposeBag()

    private let lockTimeCell: DropDownListCell

    weak var tableView: SectionsTableView?
    var onOpenInfo: ((String, String) -> ())? = nil
    var present: ((UIViewController) -> ())? = nil
    var onUpdateAlteredState: (() -> ())? = nil
    var onCaution: ((TitledCaution?) -> ())? = nil

    init(viewModel: TimeLockViewModel) {
        self.viewModel = viewModel

        lockTimeCell = DropDownListCell(viewModel: viewModel, title: "fee_settings.time_lock".localized)
    }

    func viewDidLoad() {
        lockTimeCell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
        lockTimeCell.showList = { [weak self] in self?.showList() }

        subscribe(disposeBag, viewModel.alteredStateSignal) { [weak self] in self?.onUpdateAlteredState?() }
    }

    private func showList() {
        let alertController: UIViewController = AlertRouter.module(
                title: "fee_settings.time_lock".localized,
                viewItems: viewModel.itemsList
        ) { [weak self] index in
            self?.viewModel.onSelect(index)
        }

        present?(alertController)
    }

}

extension TimeLockDataSource: ISendSettingsDataSource {

    var altered: Bool {
        viewModel.altered
    }

    var buildSections: [SectionProtocol] {
        guard let tableView = tableView else {
            return []
        }

        return [
            Section(
                    id: "time-lock",
                    headerState: .margin(height: .margin24),
                    rows: [
                        StaticRow(
                                cell: lockTimeCell,
                                id: "time-lock-cell",
                                height: .heightDoubleLineCell
                        ),
                        tableView.descriptionRow(
                                id: "time-lock-description-cell",
                                text: "fee_settings.time_lock.description".localized,
                                font: .subhead2,
                                textColor: .themeGray,
                                ignoreBottomMargin: true
                        )
                    ]
            )
        ]
    }

    func onTapReset() {
        viewModel.reset()
    }

}
