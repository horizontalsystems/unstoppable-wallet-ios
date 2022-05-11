import UIKit
import SectionsTableView
import ThemeKit
import ComponentKit

class InfoViewController: ThemeViewController {
    private let viewItems: [InfoModule.ViewItem]
    private var urlManager: UrlManager

    private let tableView = SectionsTableView(style: .grouped)

    init(viewItems: [InfoModule.ViewItem], urlManager: UrlManager) {
        self.viewItems = viewItems
        self.urlManager = urlManager

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

        tableView.registerCell(forClass: InfoSeparatorHeaderCell.self)
        tableView.registerCell(forClass: InfoHeaderCell.self)
        tableView.registerCell(forClass: ButtonCell.self)
        tableView.registerCell(forClass: DescriptionCell.self)
        tableView.registerCell(forClass: InfoHeader2Cell.self)

        tableView.sectionDataSource = self
        tableView.allowsSelection = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        tableView.buildSections()
    }

    @objc private func onClose() {
        dismiss(animated: true)
    }

    private func onTapLink(url: String) {
        urlManager.open(url: url, from: self)
    }

    private func separatorRow(index: Int) -> RowProtocol {
        Row<InfoSeparatorHeaderCell>(
                id: "\(index)",
                height: InfoSeparatorHeaderCell.height
        )
    }

    private func headerRow(text: String) -> RowProtocol {
        Row<InfoHeaderCell>(
                id: text,
                dynamicHeight: { containerWidth in
                    InfoHeaderCell.height(containerWidth: containerWidth, text: text)
                },
                bind: { cell, _ in
                    cell.bind(string: text)
                }
        )
    }

    private func header2Row(text: String) -> RowProtocol {
        Row<InfoHeader2Cell>(
                id: text,
                dynamicHeight: { containerWidth in
                    InfoHeader2Cell.height(containerWidth: containerWidth, string: text)
                },
                bind: { cell, _ in
                    cell.bind(string: text)
                }
        )
    }

    private func textRow(text: String) -> RowProtocol {
        Row<DescriptionCell>(
                id: text,
                dynamicHeight: { width in
                    DescriptionCell.height(containerWidth: width, text: text)
                },
                bind: { cell, _ in
                    cell.bind(text: text)
                }
        )
    }

    private func linkButtonRow(text: String, url: String) -> RowProtocol {
        Row<ButtonCell>(
                id: text,
                height: ButtonCell.height(style: .secondaryDefault),
                bind: { [weak self] cell, _ in
                    cell.bind(style: .secondaryDefault, title: text, compact: true) { [weak self] in
                        self?.onTapLink(url: url)
                    }
                }
        )
    }

    private func marginRow(index: Int, height: CGFloat) -> RowProtocol {
        Row<UITableViewCell>(
                id: "\(index)",
                height: height,
                bind: { cell, _ in
                    cell.backgroundColor = .clear
                }
        )
    }

}

extension InfoViewController: SectionsDataSource {

    public func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "section",
                    footerState: .margin(height: .margin32),
                    rows: rows()
            )
        ]
    }

    private func rows() -> [RowProtocol] {
        viewItems.enumerated().map { index, viewItem in
            switch viewItem {
            case .separator: return separatorRow(index: index)
            case .margin(let height): return marginRow(index: index, height: height)
            case .header(let text): return headerRow(text: text)
            case .text(let text): return textRow(text: text)
            case .header2(let text): return header2Row(text: text)
            case .button(let text, let url): return linkButtonRow(text: text, url: url)
            }
        }
    }

}
