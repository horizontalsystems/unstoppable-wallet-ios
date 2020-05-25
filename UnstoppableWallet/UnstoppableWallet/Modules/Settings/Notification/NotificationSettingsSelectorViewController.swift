import UIKit
import SectionsTableView
import ThemeKit

class NotificationSettingsSelectorViewController: ThemeViewController {
    private let onSelect: (AlertState) -> ()

    private let selectedState: AlertState
    private let tableView = SectionsTableView(style: .grouped)

    init(selectedState: AlertState, onSelect: @escaping (AlertState) -> ()) {
        self.selectedState = selectedState
        self.onSelect = onSelect

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.registerCell(forClass: SingleLineCheckmarkCell.self)
        tableView.sectionDataSource = self

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.buildSections()
    }

}

extension NotificationSettingsSelectorViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        let allCases = AlertState.allCases

        return [
            Section(
                    id: "values",
                    headerState: .margin(height: .margin3x),
                    footerState: .margin(height: .margin8x),
                    rows: allCases.enumerated().map { (index, state) in
                        Row<SingleLineCheckmarkCell>(
                                id: "\(state)",
                                height: CGFloat.heightSingleLineCell,
                                bind: { [unowned self] cell, _ in
                                    cell.bind(
                                            text: "\(state)",
                                            checkmarkVisible: self.selectedState == state,
                                            last: index == allCases.count - 1
                                    )
                                },
                                action: { [weak self] _ in
                                    self?.onSelect(state)
                                    self?.navigationController?.popViewController(animated: true)
                                }
                        )
                    }
            )
        ]
    }

}
