import UIKit
import SectionsTableView
import ThemeKit
import ComponentKit

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
                        CellBuilder.row(
                                elements: [.text, .switch],
                                tableView: tableView,
                                id: "lock_time",
                                height: .heightCell48,
                                bind: { [weak self] cell in
                                    cell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)

                                    cell.bind(index: 0) { (component: TextComponent) in
                                        component.set(style: .b2)
                                        component.text = "settings.bitcoin_hodling.lock_time".localized
                                    }
                                    cell.bind(index: 1) { (component: SwitchComponent) in
                                        component.switchView.isOn = self?.lockTimeIsOn ?? false
                                        component.onSwitch = { [weak self] isOn in
                                            self?.delegate.onSwitchLockTime(isOn: isOn)
                                        }
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
