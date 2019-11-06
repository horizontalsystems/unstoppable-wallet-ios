import UIKit
import SectionsTableView

class ExperimentalFeaturesViewController: WalletViewController {
    private let delegate: IExperimentalFeaturesViewDelegate

    private let tableView = SectionsTableView(style: .grouped)

    init(delegate: IExperimentalFeaturesViewDelegate) {
        self.delegate = delegate

        super.init()

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "settings.experimental_features.title".localized

        tableView.registerCell(forClass: TitleCell.self)
        tableView.registerHeaderFooter(forClass: TopDescriptionHeaderFooterView.self)
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

extension ExperimentalFeaturesViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        let descriptionText = "settings.experimental_features.description".localized

        let headerState: ViewState<TopDescriptionHeaderFooterView> = .cellType(hash: "top_description", binder: { view in
            view.bind(text: descriptionText)
        }, dynamicHeight: { [unowned self] _ in
            TopDescriptionHeaderFooterView.height(containerWidth: self.tableView.bounds.width, text: descriptionText)
        })

        return [
            Section(
                    id: "bitcoin_hodling_section",
                    headerState: headerState,
                    rows: [
                        Row<TitleCell>(
                                id: "bitcoin_hodling",
                                height: SettingsTheme.cellHeight,
                                bind: { cell, _ in
                                    cell.bind(title: "settings.experimental_features.bitcoin_hodling".localized, showDisclosure: true, last: true)
                                },
                                action: { [weak self] _ in
                                    self?.delegate.didTapBitcoinHodling()
                                }
                        )
                    ]
            )
        ]
    }

}
