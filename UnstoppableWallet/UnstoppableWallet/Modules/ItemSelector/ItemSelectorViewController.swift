import UIKit
import ActionSheet
import ThemeKit
import SectionsTableView
import ComponentKit

class ItemSelectorViewController: ThemeActionSheetController {
    private var titleView: UIView?
    private let tableView = SelfSizedSectionsTableView(style: .grouped)

    private var titleItem: ItemSelectorModule.Title
    private var items = [ItemSelectorModule.Item]()

    private var onTap: ((ItemSelectorViewController, Int) -> ())?

    init(title: ItemSelectorModule.Title, onTap: ((ItemSelectorViewController, Int) -> ())?) {
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
            return CellBuilderNew.row(
                    rootElement: .hStack([
                        .image24 { component in
                            if let imageUrl = viewItem.imageUrl {
                                component.isHidden = false
                                component.setImage(urlString: imageUrl, placeholder: nil)
                            } else {
                                component.isHidden = true
                            }
                        },
                        .text { component in
                            component.font = .body
                            component.textColor = viewItem.titleColor
                            component.text = viewItem.title
                        },
                        .image20 { component in
                            component.isHidden = !viewItem.selected
                            component.imageView.image = UIImage(named: "check_1_20")?.withTintColor(.themeJacob)
                        }
                    ]),
                    tableView: tableView,
                    id: "row_\(rowIndex)",
                    hash: "\(viewItem.selected)",
                    height: .heightCell48,
                    autoDeselect: true,
                    bind: { cell in
                        cell.set(backgroundStyle: .bordered, isFirst: rowIndex == 0, isLast: isLast)
                    },
                    action: { [weak self] in
                        self?.onTap(at: rowIndex)
                    }
            )
        case .complex(let viewItem):
            if let subtitle = viewItem.subtitle {
                return CellBuilder.selectableRow(
                        elements: [.multiText, .image20],
                        tableView: tableView,
                        id: "row_\(rowIndex)",
                        hash: "\(viewItem.selected)",
                        height: .heightDoubleLineCell,
                        autoDeselect: true,
                        bind: { cell in
                            cell.set(backgroundStyle: .lawrence, isFirst: rowIndex == 0, isLast: isLast)

                            cell.bind(index: 0, block: { (component: MultiTextComponent) in
                                component.set(style: .m1)

                                component.title.font = .body
                                component.title.textColor = viewItem.titleColor
                                component.title.text = viewItem.title

                                component.subtitle.font = .subhead2
                                component.subtitle.textColor = viewItem.subtitleColor
                                component.subtitle.text = subtitle
                            })

                            cell.bind(index: 1, block: { (component: ImageComponent) in
                                component.isHidden = !viewItem.selected
                                component.imageView.image = UIImage(named: "check_1_20")?.withTintColor(.themeJacob)
                            })
                        },
                        action: { [weak self] in
                            self?.onTap(at: rowIndex)
                        }
                )
            }

            return CellBuilder.selectableRow(
                    elements: [.text, .image20],
                    tableView: tableView,
                    id: "row_\(rowIndex)",
                    hash: "\(viewItem.selected)",
                    height: .heightCell48,
                    autoDeselect: true,
                    bind: { cell in
                        cell.set(backgroundStyle: .bordered, isFirst: rowIndex == 0, isLast: isLast)

                        cell.bind(index: 0, block: { (component: TextComponent) in
                            component.font = .body
                            component.textColor = viewItem.titleColor
                            component.text = viewItem.title
                        })

                        cell.bind(index: 1, block: { (component: ImageComponent) in
                            component.isHidden = !viewItem.selected
                            component.imageView.image = UIImage(named: "check_1_20")?.withTintColor(.themeJacob)
                        })
                    },
                    action: { [weak self] in
                        self?.onTap(at: rowIndex)
                    }
            )
        }
    }

    private func updateSimpleTitle(viewItem: ItemSelectorModule.SimpleTitleViewItem) {
        guard let titleView = titleView as? SimpleSheetTitleView else {
            return
        }

        titleView.text = viewItem.title
        titleView.textColor = viewItem.titleColor
    }

    private func updateComplexTitle(viewItem: ItemSelectorModule.ComplexTitleViewItem) {
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

    func set(title: ItemSelectorModule.Title) {
        switch (titleItem, title) {
        case (.simple, .simple(let viewItem)): updateSimpleTitle(viewItem: viewItem)
        case (.complex, .complex(let viewItem)): updateComplexTitle(viewItem: viewItem)
        default: ()
        }
    }

}
