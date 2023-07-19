import UIKit
import ThemeKit
import SectionsTableView
import SnapKit
import ComponentKit

class CoinAnalyticsRatingScaleViewController: ThemeViewController {
    private let tableView = SectionsTableView(style: .grouped)

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
                        MarkdownViewController.header1Row(
                                id: "header",
                                attributedString: NSAttributedString(string: "coin_analytics.rating_scale".localized, attributes: [.font: UIFont.title2, .foregroundColor: UIColor.themeLeah])
                        ),
                        MarkdownViewController.textRow(
                                id: "description",
                                attributedString: NSAttributedString(string: "coin_analytics.rating_scale.description".localized, attributes: [.font: UIFont.body, .foregroundColor: UIColor.themeBran])
                        )
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
                                    .textElement(text: .subhead1(rating.percents.uppercased(), color: rating.color)),
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
