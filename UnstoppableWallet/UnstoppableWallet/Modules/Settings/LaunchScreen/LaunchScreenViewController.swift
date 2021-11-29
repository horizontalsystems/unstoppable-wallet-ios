import UIKit
import SectionsTableView
import ThemeKit
import ComponentKit
import RxSwift

class LaunchScreenViewController: ThemeViewController {
    private let viewModel: LaunchScreenViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)

    init(viewModel: LaunchScreenViewModel) {
        self.viewModel = viewModel

        super.init()

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "settings.launch_screen.title".localized

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        tableView.registerCell(forClass: A4Cell.self)
        tableView.registerHeaderFooter(forClass: SubtitleHeaderFooterView.self)
        tableView.sectionDataSource = self

        subscribe(disposeBag, viewModel.finishSignal) { [weak self] in self?.navigationController?.popViewController(animated: true) }

        tableView.buildSections()
    }

}

extension LaunchScreenViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        let viewItems = viewModel.viewItems

        return [
            Section(
                id: "launch-screen",
                headerState: .margin(height: .margin12),
                footerState: .margin(height: .margin32),
                rows: viewItems.enumerated().map { index, viewItem in
                    let isFirst = index == 0
                    let isLast = index == viewItems.count - 1

                    return Row<A4Cell>(
                            id: "item-\(index)",
                            height: .heightCell48,
                            bind: { cell, _ in
                                cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
                                cell.title = viewItem.title
                                cell.titleImage = UIImage(named: viewItem.iconName)
                                cell.titleImageTintColor = .themeGray
                                cell.valueImage = viewItem.selected ? UIImage(named: "check_1_20")?.withTintColor(.themeJacob) : nil
                            },
                            action: { [weak self] _ in
                                self?.viewModel.onSelect(index: index)
                            }
                    )
                }
            )
        ]
    }

}

