import UIKit
import SectionsTableView
import ThemeKit
import ComponentKit

class InfoViewController: ThemeViewController {
    private var urlManager: IUrlManager
    private let viewModel: InfoViewModel

    private let tableView = SectionsTableView(style: .grouped)


    init(viewModel: InfoViewModel, urlManager: IUrlManager) {
        self.viewModel = viewModel
        self.urlManager = urlManager

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = viewModel.dataSource.title

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onClose))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.registerCell(forClass: InfoSeparatorHeaderCell.self)
        tableView.registerCell(forClass: InfoHeaderCell.self)
        tableView.registerCell(forClass: ButtonCell.self)
        tableView.registerCell(forClass: DescriptionCell.self)
        tableView.registerCell(forClass: InfoHeader3Cell.self)

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

    private func headerSeparator(index: Int) -> RowProtocol {
        Row<InfoSeparatorHeaderCell>(
                id: "\(index)",
                height: InfoSeparatorHeaderCell.height
        )
    }

    private func header(string: String) -> RowProtocol {
        Row<InfoHeaderCell>(
                id: string,
                dynamicHeight: { containerWidth in
                    InfoHeaderCell.height(containerWidth: containerWidth, text: string)
                },
                bind: { cell, _ in
                    cell.bind(string: string)
                }
        )
    }

    private func header3Row(string: String) -> RowProtocol {
        Row<InfoHeader3Cell>(
                id: string,
                dynamicHeight: { containerWidth in
                    InfoHeader3Cell.height(containerWidth: containerWidth, string: string)
                },
                bind: { cell, _ in
                    cell.bind(string: string)
                }
        )
    }

    private func row(text: String) -> RowProtocol {
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

    private func linkButtonRow(title: String, url: String) -> RowProtocol {
        Row<ButtonCell>(
                id: title,
                height: ButtonCell.height(style: .secondaryDefault),
                bind: { [weak self] cell, _ in
                    cell.bind(style: .secondaryDefault, title: title, compact: true) { [weak self] in
                        self?.onTapLink(url: url)
                    }
                }
        )
    }

    private func margin(index: Int, height: CGFloat) -> RowProtocol {
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
                    rows: rows(rowItems: viewModel.dataSource.viewItems)
            )
        ]
    }

    private func rows(rowItems: [InfoViewModel.ViewItem]) -> [RowProtocol] {
        rowItems.enumerated().map { index, viewItem in
            switch viewItem {
            case .separator:
                return headerSeparator(index: index)
            case let .margin(height):
                return margin(index: index, height: height)
            case let .header(title):
                return header(string: title)
            case let .text(string):
                return row(text: string)
            case let .header3Cell(string: string):
                return header3Row(string: string)
            case let .button(title, url):
                return linkButtonRow(title: title, url: url)
            }
        }
    }

}
