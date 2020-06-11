import UIKit
import SnapKit
import ThemeKit
import SectionsTableView

class GuideViewController: ThemeViewController {
    private let delegate: IGuideViewDelegate

    private let tableView = SectionsTableView(style: .grouped)

    private var imageUrl: String?
    private var viewItems = [GuideBlockViewItem]()

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

        tableView.registerCell(forClass: GuideHeader1Cell.self)
        tableView.registerCell(forClass: GuideHeader3Cell.self)
        tableView.registerCell(forClass: GuideTextCell.self)
        tableView.registerCell(forClass: GuideListItemCell.self)
        tableView.registerCell(forClass: GuideBlockQuoteCell.self)
        tableView.registerCell(forClass: GuideImageCell.self)
        tableView.registerCell(forClass: GuideImageTitleCell.self)
        tableView.registerCell(forClass: GuideFooterCell.self)
        tableView.sectionDataSource = self

        delegate.onLoad()

        tableView.buildSections()
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()

        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: view.safeAreaInsets.bottom, right: 0)
    }

    private func footerRow(text: String) -> RowProtocol {
        Row<GuideFooterCell>(
                id: "footer",
                dynamicHeight: { containerWidth in
                    GuideFooterCell.height(containerWidth: containerWidth, text: text)
                },
                bind: { cell, _ in
                    cell.bind(text: text)
                }
        )
    }

    private func header1Row(id: String, attributedString: NSAttributedString) -> RowProtocol {
        Row<GuideHeader1Cell>(
                id: id,
                dynamicHeight: { containerWidth in
                    GuideHeader1Cell.height(containerWidth: containerWidth, attributedString: attributedString)
                },
                bind: { cell, _ in
                    cell.bind(attributedString: attributedString)
                }
        )
    }

    private func header3Row(id: String, attributedString: NSAttributedString) -> RowProtocol {
        Row<GuideHeader3Cell>(
                id: id,
                dynamicHeight: { containerWidth in
                    GuideHeader3Cell.height(containerWidth: containerWidth, attributedString: attributedString)
                },
                bind: { cell, _ in
                    cell.bind(attributedString: attributedString)
                }
        )
    }

    private func textRow(id: String, attributedString: NSAttributedString) -> RowProtocol {
        Row<GuideTextCell>(
                id: id,
                dynamicHeight: { containerWidth in
                    GuideTextCell.height(containerWidth: containerWidth, attributedString: attributedString)
                },
                bind: { cell, _ in
                    cell.bind(attributedString: attributedString)
                }
        )
    }

    private func listItemRow(id: String, attributedString: NSAttributedString, prefix: String?, tightTop: Bool, tightBottom: Bool) -> RowProtocol {
        Row<GuideListItemCell>(
                id: id,
                dynamicHeight: { containerWidth in
                    GuideListItemCell.height(containerWidth: containerWidth, attributedString: attributedString, tightTop: tightTop, tightBottom: tightBottom)
                },
                bind: { cell, _ in
                    cell.bind(attributedString: attributedString, prefix: prefix, tightTop: tightTop, tightBottom: tightBottom)
                }
        )
    }

    private func blockQuoteRow(id: String, attributedString: NSAttributedString) -> RowProtocol {
        Row<GuideBlockQuoteCell>(
                id: id,
                dynamicHeight: { containerWidth in
                    GuideBlockQuoteCell.height(containerWidth: containerWidth, attributedString: attributedString)
                },
                bind: { cell, _ in
                    cell.bind(attributedString: attributedString)
                }
        )
    }

    private func imageRow(id: String, url: String) -> RowProtocol {
        Row<GuideImageCell>(
                id: id,
                dynamicHeight: { containerWidth in
                    GuideImageCell.height(containerWidth: containerWidth)
                },
                bind: { cell, _ in
                    cell.bind(imageUrl: url)
                }
        )
    }

    private func imageTitleRow(id: String, text: String) -> RowProtocol {
        Row<GuideImageTitleCell>(
                id: id,
                dynamicHeight: { containerWidth in
                    GuideImageTitleCell.height(containerWidth: containerWidth, text: text)
                },
                bind: { cell, _ in
                    cell.bind(text: text)
                }
        )
    }

    private func row(index: Int, viewItem: GuideBlockViewItem) -> RowProtocol {
        switch viewItem {
        case let .h1(attributedString):
            return header1Row(
                    id: "header1_\(index)",
                    attributedString: attributedString
            )
        case let .h2(attributedString):
            return header1Row(
                    id: "header2_\(index)",
                    attributedString: attributedString
            )
        case let .h3(attributedString):
            return header3Row(
                    id: "header3_\(index)",
                    attributedString: attributedString
            )
        case let .text(attributedString):
            return textRow(
                    id: "text_\(index)",
                    attributedString: attributedString
            )
        case let .listItem(attributedString, prefix, tightTop, tightBottom):
            return listItemRow(
                    id: "listItem_\(index)",
                    attributedString: attributedString,
                    prefix: prefix,
                    tightTop: tightTop,
                    tightBottom: tightBottom
            )
        case let .blockQuote(attributedString):
            return blockQuoteRow(
                    id: "blockQuote_\(index)",
                    attributedString: attributedString
            )
        case let .image(url):
            return imageRow(
                    id: "image_\(index)",
                    url: url
            )
        case let .imageTitle(text):
            return imageTitleRow(
                    id: "imageTitle_\(index)",
                    text: text
            )
        }
    }

}

extension GuideViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "blocks",
                    rows: viewItems.enumerated().map { row(index: $0, viewItem: $1) }
            ),
            Section(
                    id: "footer",
                    rows: [
                        footerRow(text: "© Horizontal Systems 2020")
                    ]
            )
        ]
    }

}


extension GuideViewController: IGuideView {

    func set(imageUrl: String, viewItems: [GuideBlockViewItem]) {
        self.imageUrl = imageUrl
        self.viewItems = viewItems
    }

}
