import UIKit
import SectionsTableView
import ThemeKit

protocol InfoDataSource: SectionsDataSource {
    var rowsFactory: InfoRowsFactory { get set }
}

class InfoViewController: ThemeViewController {
    private let delegate: IInfoViewDelegate

    private let tableView = SectionsTableView(style: .grouped)
    private let sectionDataSource: InfoDataSource //used to retain data source, it's weak in SectionsTableView

    init(title: String, delegate: IInfoViewDelegate, sectionDataSource: InfoDataSource) {
        self.delegate = delegate
        self.sectionDataSource = sectionDataSource

        super.init()

        self.title = title
        tableView.sectionDataSource = sectionDataSource
        sectionDataSource.rowsFactory.linkAction = { [weak self] in self?.onTapLink()}
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onClose))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.registerHeaderFooter(forClass: InfoSeparatorHeaderView.self)
        tableView.registerHeaderFooter(forClass: InfoHeaderView.self)
        tableView.registerCell(forClass: ButtonCell.self)
        tableView.registerCell(forClass: DescriptionCell.self)
        tableView.registerCell(forClass: InfoHeader3Cell.self)

        tableView.allowsSelection = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        tableView.buildSections()
    }

    @objc private func onClose() {
        delegate.onTapClose()
    }

    private func onTapLink() {
        delegate.onTapLink()
    }

}
