import UIKit
import SectionsTableView
import ThemeKit

class BitcoinHodlingViewController: ThemeViewController {
    private let delegate: IBitcoinHodlingViewDelegate

    private let tableView = SectionsTableView(style: .grouped)
    private var lockTimeIsOn = false

    init(delegate: IBitcoinHodlingViewDelegate) {
        self.delegate = delegate

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "settings.bitcoin_hodling.title".localized

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.registerCell(forClass: ToggleCell.self)
        tableView.registerHeaderFooter(forClass: BottomDescriptionHeaderFooterView.self)
        tableView.sectionDataSource = self

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        delegate.onLoad()

        tableView.buildSections()
    }

}

extension BitcoinHodlingViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        let descriptionText = "settings.bitcoin_hodling.description".localized

        let footerState: ViewState<BottomDescriptionHeaderFooterView> = .cellType(hash: "bottom_description", binder: { view in
            view.bind(text: descriptionText)
        }, dynamicHeight: { [unowned self] _ in
            BottomDescriptionHeaderFooterView.height(containerWidth: self.tableView.bounds.width, text: descriptionText)
        })

        return [
            Section(
                    id: "lock_time_section",
                    headerState: .margin(height: .margin3x),
                    footerState: footerState,
                    rows: [
                        Row<ToggleCell>(
                                id: "lock_time",
                                height: .heightSingleLineCell,
                                bind: { [unowned self] cell, _ in
                                    cell.bind(
                                            title: "settings.bitcoin_hodling.lock_time".localized,
                                            isOn: self.lockTimeIsOn,
                                            last: true
                                    ) { [weak self] isOn in
                                        self?.delegate.onSwitchLockTime(isOn: isOn)
                                    }
                                }
                        )
                    ]
            )
        ]
    }

}

extension BitcoinHodlingViewController: IBitcoinHodlingView {

    func setLockTime(isOn: Bool) {
        lockTimeIsOn = isOn
    }

}
