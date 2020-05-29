import UIKit
import SnapKit
import ThemeKit
import SectionsTableView

class GuideViewController: ThemeViewController {
    private let delegate: IGuideViewDelegate

    private let tableView = SectionsTableView(style: .grouped)

    private var imageUrl: String?
    private var blocks = [GuideBlock]()

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

        tableView.contentInsetAdjustmentBehavior = .never
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.registerCell(forClass: GuideHeaderCell.self)
        tableView.registerCell(forClass: GuideHeader1Cell.self)
        tableView.registerCell(forClass: GuideHeader3Cell.self)
        tableView.registerCell(forClass: GuideTextCell.self)
        tableView.registerCell(forClass: GuideImageCell.self)
        tableView.sectionDataSource = self

        delegate.onLoad()

        tableView.buildSections()
    }

    private func header1Row(attributedString: NSAttributedString) -> RowProtocol {
        Row<GuideHeader1Cell>(
                id: attributedString.string, // todo: check performance
                dynamicHeight: { containerWidth in
                    GuideHeader1Cell.height(containerWidth: containerWidth, attributedString: attributedString)
                },
                bind: { cell, _ in
                    cell.bind(attributedString: attributedString)
                }
        )
    }

    private func header3Row(attributedString: NSAttributedString) -> RowProtocol {
        Row<GuideHeader3Cell>(
                id: attributedString.string, // todo: check performance
                dynamicHeight: { containerWidth in
                    GuideHeader3Cell.height(containerWidth: containerWidth, attributedString: attributedString)
                },
                bind: { cell, _ in
                    cell.bind(attributedString: attributedString)
                }
        )
    }

    private func textRow(attributedString: NSAttributedString) -> RowProtocol {
        Row<GuideTextCell>(
                id: attributedString.string, // todo: check performance
                dynamicHeight: { containerWidth in
                    GuideTextCell.height(containerWidth: containerWidth, attributedString: attributedString)
                },
                bind: { cell, _ in
                    cell.bind(attributedString: attributedString)
                }
        )
    }

    private func imageRow(url: String, altText: String?) -> RowProtocol {
        Row<GuideImageCell>(
                id: url,
                dynamicHeight: { containerWidth in
                    GuideImageCell.height(containerWidth: containerWidth, altText: altText)
                },
                bind: { cell, _ in
                    cell.bind(imageUrl: url, altText: altText)
                }
        )
    }

    private func row(block: GuideBlock) -> RowProtocol {
        switch block {
        case let .h1(attributedString): return header1Row(attributedString: attributedString)
        case let .h2(attributedString): return header1Row(attributedString: attributedString)
        case let .h3(attributedString): return header3Row(attributedString: attributedString)
        case let .text(attributedString): return textRow(attributedString: attributedString)
        case let .image(url, altText): return imageRow(url: url, altText: altText)
        }
    }

}

extension GuideViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "header",
                    rows: [
                        Row<GuideHeaderCell>(
                                id: "header",
                                height: GuideHeaderCell.height,
                                bind: { [weak self] cell, _ in
                                    cell.bind(imageUrl: self?.imageUrl)
                                }
                        )
                    ]
            ),
            Section(
                    id: "blocks",
                    rows: blocks.map { row(block: $0) }
            )
        ]
    }

}


extension GuideViewController: IGuideView {

    func set(imageUrl: String, blocks: [GuideBlock]) {
        self.imageUrl = imageUrl
        self.blocks = blocks
    }

}
