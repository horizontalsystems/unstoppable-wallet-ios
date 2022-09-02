import UIKit
import ThemeKit
import ActionSheet
import ComponentKit
import SectionsTableView

class InformationViewController: ThemeActionSheetController {
    private static let buttonSpacing = CGFloat.margin12

    private var titleView: UIView?
    private let tableView = SelfSizedSectionsTableView(style: .grouped)
    private let buttonStackView = UIStackView()

    private var titleItem: BottomSheetItem.Title
    private var items = [InformationModule.Item]()
    private var buttons = [InformationModule.ButtonItem]()

    init(title: BottomSheetItem.Title) {
        titleItem = title

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
        }

        view.addSubview(buttonStackView)
        buttonStackView.snp.makeConstraints { maker in
            maker.top.equalTo(tableView.snp.bottom).offset(CGFloat.margin24)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.bottom.equalTo(view.safeAreaLayoutGuide).inset(0)
            maker.height.equalTo(0)
        }

        buttonStackView.axis = .vertical
        buttonStackView.distribution = .fillEqually
        buttonStackView.alignment = .fill
        buttonStackView.spacing = Self.buttonSpacing

        tableView.sectionDataSource = self

        updateButtonStackView()
        tableView.reload()
    }

    private func onTapClose() {
        dismiss(animated: true) { [weak self] in
            self?.onInteractiveDismiss?()
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

    private func descriptionSection(text: String, isHighlighted: Bool = true) -> SectionProtocol {
        Section(
                id: "description_section",
                rows: [
                    isHighlighted ?
                        tableView.highlightedDescriptionRow(id: "description_\(text)", text: text, ignoreBottomMargin: true) :
                        tableView.descriptionRow(id: "description_\(text)", text: text, ignoreBottomMargin: true)
                ]
        )
    }

    private func marginSection(height: CGFloat) -> SectionProtocol {
        Section(
                id: "description_section",
                headerState: .margin(height: height),
                rows: []
        )
    }

    private func itemSection(items: [InformationModule.SectionItem]) -> SectionProtocol {
        let rows: [RowProtocol] = items.enumerated().map { index, item in
            let isLast = index == items.count - 1
            switch item {
            case .simple(let viewItem):
                return BottomSheetItem.simpleRow(tableView: tableView, viewItem: viewItem, rowIndex: index, isLast: isLast)
            case .complex(let viewItem):
                return BottomSheetItem.complexRow(tableView: tableView, viewItem: viewItem, rowIndex: index, isLast: isLast)
            }
        }

        return Section(
                id: "item_section",
                headerState: .margin(height: .margin12),
                rows: rows
        )
    }

    private func updateButtonStackView() {
        let count = buttons.count
        guard count > 0 else {
            buttonStackView.arrangedSubviews.forEach { buttonStackView.removeArrangedSubview($0) }

            buttonStackView.snp.remakeConstraints { maker in
                maker.top.equalTo(tableView.snp.bottom).offset(CGFloat.margin24)
                maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
                maker.bottom.equalTo(view.safeAreaLayoutGuide).inset(0)
                maker.height.equalTo(0)
            }

            view.layoutSubviews()
            return
        }

        let stackHeight = Self.buttonSpacing * CGFloat(count - 1) + PrimaryButton.height * CGFloat(count)
        buttonStackView.snp.remakeConstraints { maker in
            maker.top.equalTo(tableView.snp.bottom).offset(CGFloat.margin24)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.bottom.equalTo(view.safeAreaLayoutGuide).inset(CGFloat.margin24)
            maker.height.equalTo(stackHeight)
        }
        view.layoutSubviews()

        buttons.forEach { item in
            let component = PrimaryButtonComponent()
            component.button.set(style: item.style)
            component.button.setTitle(item.title, for: .normal)
            component.onTap = { [weak self] in
                if let weakSelf = self {
                    item.action?(weakSelf)
                }
            }
            buttonStackView.addArrangedSubview(component)
        }
    }

}

extension InformationViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        items.enumerated().map { (index: Int, item: InformationModule.Item) in
            switch item {
            case let .description(text, isHighlighted): return descriptionSection(text: text, isHighlighted: isHighlighted)
            case .margin(let height): return marginSection(height: height)
            case .section(let items): return itemSection(items: items)
            }
        }
    }

}

extension InformationViewController {

    func set(items: [InformationModule.Item]) {
        self.items = items

        tableView.reload()
    }

    func set(buttons: [InformationModule.ButtonItem]) {
        self.buttons = buttons
    }

    func set(title: BottomSheetItem.Title) {
        switch (titleItem, title) {
        case (.simple, .simple(let viewItem)): updateSimpleTitle(viewItem: viewItem)
        case (.complex, .complex(let viewItem)): updateComplexTitle(viewItem: viewItem)
        default: ()
        }
    }

}
