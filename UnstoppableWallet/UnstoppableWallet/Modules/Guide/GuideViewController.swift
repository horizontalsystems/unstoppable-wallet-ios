import UIKit
import SnapKit
import ThemeKit
import SectionsTableView

class GuideViewController: ThemeViewController {
    private let delegate: IGuideViewDelegate

    private let tableView = SectionsTableView(style: .grouped)

    private var imageUrl: String?
    private var titleText: String?

    init(delegate: IGuideViewDelegate) {
        self.delegate = delegate

        super.init()

        hidesBottomBarWhenPushed = true
        navigationItem.largeTitleDisplayMode = .never
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.registerCell(forClass: GuideHeaderCell.self)
        tableView.sectionDataSource = self

        delegate.onLoad()

        tableView.buildSections()
    }

}

extension GuideViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "main",
                    rows: [
                        Row<GuideHeaderCell>(
                                id: "header",
                                dynamicHeight: { [weak self] containerWidth in
                                    GuideHeaderCell.height(containerWidth: containerWidth, text: self?.title)
                                },
                                bind: { [weak self] cell, _ in
                                    cell.bind(imageUrl: self?.imageUrl, text: self?.titleText)
                                }
                        )
                    ]
            )
        ]
    }

}


extension GuideViewController: IGuideView {

    func set(title: String, imageUrl: String) {
        titleText = title
        self.imageUrl = imageUrl
    }

}
