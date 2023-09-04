import Foundation
import UIKit
import ComponentKit
import SectionsTableView
import ThemeKit

class RestoreCexViewController: ThemeViewController {
    private weak var returnViewController: UIViewController?

    private let tableView = SectionsTableView(style: .grouped)

    init(returnViewController: UIViewController?) {
        self.returnViewController = returnViewController

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "restore.cex.title".localized

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onTapCancel))
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.sectionDataSource = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        tableView.buildSections()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.deselectCell(withCoordinator: transitionCoordinator, animated: animated)
    }

    @objc private func onTapCancel() {
        (returnViewController ?? self)?.dismiss(animated: true)
    }

    private func openRestore(cex: Cex) {
        let viewController = cex.restoreViewController(returnViewController: returnViewController)
        navigationController?.pushViewController(viewController, animated: true)
    }

}

extension RestoreCexViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "description",
                    headerState: .margin(height: .margin12),
                    footerState: .margin(height: .margin32),
                    rows: [
                        tableView.descriptionRow(
                                id: "description",
                                text: "restore.cex.description".localized,
                                font: .subhead2,
                                textColor: .themeGray,
                                ignoreBottomMargin: true
                        )
                    ]
            ),
            Section(
                    id: "list",
                    footerState: .margin(height: .margin32),
                    rows: Cex.allCases.enumerated().map { index, cex in
                        let rowInfo = RowInfo(index: index, count: Cex.allCases.count)

                        return tableView.universalRow62(
                                id: cex.rawValue,
                                image: .url(cex.imageUrl),
                                title: .body(cex.title),
                                description: .subhead2(cex.url),
                                accessoryType: .disclosure,
                                isFirst: rowInfo.isFirst,
                                isLast: rowInfo.isLast
                        ) { [weak self] in
                            self?.openRestore(cex: cex)
                        }
                    }
            )
        ]
    }

}
