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

    private func listItemRow(attributedString: NSAttributedString, prefix: String?, tightTop: Bool, tightBottom: Bool) -> RowProtocol {
        Row<GuideListItemCell>(
                id: attributedString.string, // todo: check performance
                dynamicHeight: { containerWidth in
                    GuideListItemCell.height(containerWidth: containerWidth, attributedString: attributedString, tightTop: tightTop, tightBottom: tightBottom)
                },
                bind: { cell, _ in
                    cell.bind(attributedString: attributedString, prefix: prefix, tightTop: tightTop, tightBottom: tightBottom)
                }
        )
    }

    private func blockQuoteRow(attributedString: NSAttributedString) -> RowProtocol {
        Row<GuideBlockQuoteCell>(
                id: attributedString.string, // todo: check performance
                dynamicHeight: { containerWidth in
                    GuideBlockQuoteCell.height(containerWidth: containerWidth, attributedString: attributedString)
                },
                bind: { cell, _ in
                    cell.bind(attributedString: attributedString)
                }
        )
    }

    private func imageRow(url: String) -> RowProtocol {
        Row<GuideImageCell>(
                id: url,
                dynamicHeight: { containerWidth in
                    GuideImageCell.height(containerWidth: containerWidth)
                },
                bind: { cell, _ in
                    cell.bind(imageUrl: url)
                }
        )
    }

    private func imageTitleRow(text: String) -> RowProtocol {
        Row<GuideImageTitleCell>(
                id: text,
                dynamicHeight: { containerWidth in
                    GuideImageTitleCell.height(containerWidth: containerWidth, text: text)
                },
                bind: { cell, _ in
                    cell.bind(text: text)
                }
        )
    }

    private func row(viewItem: GuideBlockViewItem) -> RowProtocol {
        switch viewItem {
        case let .h1(attributedString): return header1Row(attributedString: attributedString)
        case let .h2(attributedString): return header1Row(attributedString: attributedString)
        case let .h3(attributedString): return header3Row(attributedString: attributedString)
        case let .text(attributedString): return textRow(attributedString: attributedString)
        case let .listItem(attributedString, prefix, tightTop, tightBottom): return listItemRow(attributedString: attributedString, prefix: prefix, tightTop: tightTop, tightBottom: tightBottom)
        case let .blockQuote(attributedString): return blockQuoteRow(attributedString: attributedString)
        case let .image(url): return imageRow(url: url)
        case let .imageTitle(text): return imageTitleRow(text: text)
        }
    }

}

extension GuideViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "blocks",
                    rows: viewItems.map { row(viewItem: $0) }
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
