import UIKit
import SectionsTableView
import ThemeKit

class NotificationSettingsSelectorViewController: ThemeViewController {
    private let onSelect: (PriceAlert.ChangeState) -> ()

    private let selectedState: PriceAlert.ChangeState
    private let tableView = SectionsTableView(style: .grouped)

    init(changeState: PriceAlert.ChangeState, onSelect: @escaping (PriceAlert.ChangeState) -> ()) {
        self.selectedState = changeState
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
        let allCases = PriceAlert.ChangeState.allCases

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
