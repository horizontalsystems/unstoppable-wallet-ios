import Foundation
import UIKit
import MarketKit
import SectionsTableView
import ThemeKit

class ReceiveSelectorViewController<ViewModel: IReceiveSelectorViewModel>: ThemeViewController {
    private let viewModel: ViewModel

    var onSelect: ((ViewModel.Item) -> ())?

    private let tableView = SectionsTableView(style: .grouped)

    init(viewModel: ViewModel) {
        self.viewModel = viewModel

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = viewModel.title
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onTapClose))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.sectionDataSource = self

        tableView.buildSections()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.deselectCell(withCoordinator: transitionCoordinator, animated: animated)
    }

    @objc private func onTapClose() {
        dismiss(animated: true)
    }

    private func onSelect(uid: String) {
        guard let item = viewModel.item(uid: uid) else {
            return
        }

        onSelect?(item)
    }

}

extension ReceiveSelectorViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        let viewItems = viewModel.viewItems
        var sections: [SectionProtocol] = [
            Section(
                    id: "description",
                    headerState: .margin(height: .margin12),
                    footerState: .margin(height: .margin32),
                    rows: [
                        tableView.descriptionRow(
                                id: "description",
                                text: viewModel.topDescription,
                                font: .subhead2,
                                textColor: .themeGray,
                                ignoreBottomMargin: true
                        )
                    ]
            ),
            Section(
                    id: "main",
                    footerState: .margin(height: .margin32),
                    rows: viewItems.enumerated().map { index, viewItem in
                        tableView.universalRow62(
                                id: viewItem.uid,
                                image: .url(viewItem.imageUrl, placeholder: "placeholder_rectangle_32"),
                                title: .body(viewItem.title),
                                description: .subhead2(viewItem.subtitle),
                                accessoryType: .disclosure,
                                isFirst: index == 0,
                                isLast: index == viewItems.count - 1)
                        { [weak self] in
                            self?.onSelect(uid: viewItem.uid)
                        }
                    }
            )
        ]

        if let bottomDescription = viewModel.highlightedBottomDescription {
            sections.append(
                    Section(
                            id: "description",
                            footerState: .margin(height: .margin32),
                            rows: [
                                tableView.highlightedDescriptionRow(
                                        id: "description",
                                        text: bottomDescription,
                                        ignoreBottomMargin: true
                                )
                            ]
                    )
            )
        }

        return sections
    }

}
