import UIKit
import SnapKit
import ThemeKit
import SectionsTableView

class GuidesViewController: ThemeViewController {
    private let delegate: IGuidesViewDelegate

    private let tableView = SectionsTableView(style: .grouped)

    private var viewItems = [GuideViewItem]()

    init(delegate: IGuidesViewDelegate) {
        self.delegate = delegate

        super.init()

        tabBarItem = UITabBarItem(title: "guides.tab_bar_item".localized, image: UIImage(named: "Guides Tab Bar"), tag: 0)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "guides.title".localized

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.registerCell(forClass: GuideCell.self)
        tableView.sectionDataSource = self

        delegate.onLoad()

        tableView.buildSections()
    }

    private func guideRow(index: Int, viewItem: GuideViewItem) -> RowProtocol {
        Row<GuideCell>(
                id: viewItem.title,
                dynamicHeight: { containerWidth in
                    GuideCell.height(containerWidth: containerWidth, viewItem: viewItem)
                },
                bind: { cell, _ in
                    cell.bind(viewItem: viewItem)
                },
                action: { [weak self] _ in
                    self?.delegate.onTapGuide(index: index)
                }
        )
    }

}

extension GuidesViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "guides",
                    headerState: .margin(height: .margin3x),
                    footerState: .margin(height: .margin8x),
                    rows: viewItems.enumerated().map { guideRow(index: $0, viewItem: $1) }
            )
        ]
    }

}

extension GuidesViewController: IGuidesView {

    func set(viewItems: [GuideViewItem]) {
        self.viewItems = viewItems
    }

}
