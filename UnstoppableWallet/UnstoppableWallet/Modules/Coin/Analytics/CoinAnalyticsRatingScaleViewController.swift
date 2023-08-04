import UIKit
import ThemeKit
import SectionsTableView
import SnapKit
import ComponentKit

class CoinAnalyticsRatingScaleViewController: ThemeViewController {
    private let _title: String
    private let _description: String
    private let scores: [CoinAnalyticsModule.Rating: String]

    private let tableView = SectionsTableView(style: .grouped)

    init(title: String, description: String, scores: [CoinAnalyticsModule.Rating: String]) {
        _title = title
        _description = description
        self.scores = scores

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onClose))
        navigationItem.largeTitleDisplayMode = .never

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.sectionDataSource = self

        tableView.registerCell(forClass: MarkdownHeader1Cell.self)
        tableView.registerCell(forClass: MarkdownHeader3Cell.self)
        tableView.registerCell(forClass: MarkdownTextCell.self)

        tableView.buildSections()
    }

    @objc private func onClose() {
        dismiss(animated: true)
    }

}

extension CoinAnalyticsRatingScaleViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "info",
                    footerState: .margin(height: .margin12),
                    rows: [
                        MarkdownViewController.header1Row(id: "header", string: "coin_analytics.overall_score".localized),
                        MarkdownViewController.header3Row(id: "sub-header", string: _title),
                        MarkdownViewController.textRow(id: "description", string: _description)
                    ]
            ),
            Section(
                    id: "items",
                    footerState: .margin(height: .margin32),
                    rows: CoinAnalyticsModule.Rating.allCases.enumerated().map { index, rating in
                        let isFirst = index == 0
                        let isLast = index == CoinAnalyticsModule.Rating.allCases.count - 1

                        return CellBuilderNew.row(
                                rootElement: .hStack([
                                    .imageElement(image: .local(rating.image), size: .image24),
                                    .margin8,
                                    .textElement(text: .subhead1(rating.title.uppercased(), color: rating.color)),
                                    .textElement(text: .subhead1(scores[rating], color: rating.color)),
                                ]),
                                tableView: tableView,
                                id: "rating-\(index)",
                                height: .heightCell48,
                                bind: { cell in
                                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
                                }
                        )
                    }
            )
        ]
    }

}
