import UIKit
import ActionSheet
import ThemeKit
import SectionsTableView
import ComponentKit

class ItemSelectorViewController: ThemeActionSheetController {
    private var titleView: UIView?
    private let tableView = SelfSizedSectionsTableView(style: .grouped)

    private var titleItem: BottomSheetItem.Title
    private var items = [ItemSelectorModule.Item]()

    private var onTap: ((ItemSelectorViewController, Int) -> ())?

    init(title: BottomSheetItem.Title, onTap: ((ItemSelectorViewController, Int) -> ())?) {
        titleItem = title
        self.onTap = onTap

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        switch titleItem {
        case .simple(let viewItem):
            titleView = SimpleSheetTitleView()

            updateSimpleTitle(viewItem: viewItem)
        case .complex(let viewItem):
            titleView = BottomSheetTitleView()

            updateComplexTitle(viewItem: viewItem)
        }

        if let titleView = titleView {
            view.addSubview(titleView)
            titleView.snp.makeConstraints { maker in
                maker.leading.top.trailing.equalToSuperview()
            }
        }

        titleView?.backgroundColor = .themeLawrence

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            if let titleView = titleView {
                maker.top.equalTo(titleView.snp.bottom)
            } else {
                maker.top.equalToSuperview()
            }
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalTo(view.safeAreaLayoutGuide).inset(CGFloat.margin24)
        }

//        tableView.allowsSelection = false

        tableView.sectionDataSource = self

        tableView.reload()
    }

    private func onTapClose() {
        dismiss(animated: true)
    }

    private func onTap(at index: Int) {
        onTap?(self, index)
    }

    private func row(viewItem: ItemSelectorModule.Item, rowIndex: Int, isLast: Bool) -> RowProtocol {
        switch viewItem {
        case .description(let text):
            return tableView.highlightedDescriptionRow(id: "description_\(text)", text: text)
        case .simple(let viewItem):
            return BottomSheetItem.simpleRow(tableView: tableView, viewItem: viewItem, rowIndex: rowIndex, isLast: isLast) { [weak self] in
                self?.onTap(at: rowIndex)
            }
        case .complex(let viewItem):
            return BottomSheetItem.complexRow(tableView: tableView, viewItem: viewItem, rowIndex: rowIndex, isLast: isLast) { [weak self] in
                self?.onTap(at: rowIndex)
            }
        }
    }

    private func updateSimpleTitle(viewItem: BottomSheetItem.SimpleTitleViewItem) {
        guard let titleView = titleView as? SimpleSheetTitleView else {
            return
        }

        titleView.text = viewItem.title
        titleView.textColor = viewItem.titleColor
    }

    private func updateComplexTitle(viewItem: BottomSheetItem.ComplexTitleViewItem) {
        guard let titleView = titleView as? BottomSheetTitleView else {
            return
        }

        titleView.title = viewItem.title
        titleView.image = viewItem.image
        titleView.onTapClose = { [weak self] in
            self?.onTapClose()
        }
    }

}

extension ItemSelectorViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "item_section",
                    footerState: .margin(height: .margin16),
                    rows: items.enumerated().map { index, viewItem in
                        row(viewItem: viewItem, rowIndex: index, isLast: index == items.count - 1)
                    }
            )
        ]
    }

}

extension ItemSelectorViewController {

    func set(items: [ItemSelectorModule.Item]) {
        self.items = items

        tableView.reload()
    }

    func set(title: BottomSheetItem.Title) {
        switch (titleItem, title) {
        case (.simple, .simple(let viewItem)): updateSimpleTitle(viewItem: viewItem)
        case (.complex, .complex(let viewItem)): updateComplexTitle(viewItem: viewItem)
        default: ()
        }
    }

}
