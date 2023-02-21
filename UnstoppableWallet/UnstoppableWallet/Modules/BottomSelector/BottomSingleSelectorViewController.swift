import UIKit
import ThemeKit
import ComponentKit
import SectionsTableView

class BottomSingleSelectorViewController: ThemeActionSheetController {
    private let viewItems: [SelectorModule.ViewItem]
    private let onSelect: (Int) -> ()

    private let tableView = SelfSizedSectionsTableView(style: .grouped)
    private let titleView = BottomSheetTitleView()

    init(image: BottomSheetTitleView.Image?, title: String, subtitle: String?, viewItems: [SelectorModule.ViewItem], onSelect: @escaping (Int) -> ()) {
        self.viewItems = viewItems
        self.onSelect = onSelect

        super.init()

        titleView.bind(image: image, title: title, subtitle: subtitle, viewController: self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(titleView)
        titleView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(titleView.snp.bottom).offset(CGFloat.margin12)
            maker.bottom.equalTo(view.safeAreaLayoutGuide).inset(CGFloat.margin24)
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.sectionDataSource = self

        tableView.buildSections()
    }

    private func onSelect(index: Int) {
        onSelect(index)
        dismiss(animated: true)
    }

}

extension BottomSingleSelectorViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "main",
                    rows: viewItems.enumerated().map { index, viewItem in
                        SelectorModule.row(
                                viewItem: viewItem,
                                tableView: tableView,
                                selected: viewItem.selected,
                                backgroundStyle: .bordered,
                                index: index,
                                isFirst: index == 0,
                                isLast: index == viewItems.count - 1
                        ) { [weak self] in
                            self?.onSelect(index: index)
                        }
                    }
            )
        ]
    }

}
