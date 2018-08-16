import UIKit
import GrouviExtensions
import RxSwift
import SnapKit

public protocol SectionsDataSource: class {
    func buildSections() -> [SectionProtocol]
    func unbind(cell: UITableViewCell)
    func onBottomReached()
    func userDidScroll()
    func didScroll()
    func userWillDragging()
}

extension SectionsDataSource {
    public func unbind(cell: UITableViewCell) {}
    public func onBottomReached() {}
    public func userDidScroll() {}
    public func didScroll() {}
    public func userWillDragging() {}
}

open class SectionsTableView: UITableView, UITableViewDelegate, UITableViewDataSource {

    public var sections = [SectionProtocol]()
    public weak var sectionDataSource: SectionsDataSource?

    public init(style: UITableViewStyle) {
        super.init(frame: .zero, style: style)

        delegate = self
        dataSource = self

        cellLayoutMarginsFollowReadableWidth = false

        tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.ulpOfOne))
        tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.ulpOfOne))

        rowHeight = 0
        sectionHeaderHeight = 0
        sectionFooterHeight = 0
        estimatedSectionHeaderHeight = 0
        estimatedSectionFooterHeight = 0
        estimatedRowHeight = 0

        registerCell(forClass: SectionEmptyCell.self)
        registerHeaderFooter(forNib: SectionLabelView.self)
        registerHeaderFooter(forClass: SectionColorHeader.self)
        registerHeaderFooter(forNib: SectionSpinnerView.self)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func reload(animated: Bool = false) {
        if animated {
            reloadAnimated()
        } else {
            buildSections()
            reloadData()
        }
    }

    public func buildSections() {
        sections = sectionDataSource?.buildSections() ?? []
    }

    private func reloadAnimated() {
        let oldSections = sections
        buildSections()

        var insertSectionsIndexSet = IndexSet()
        var deleteSectionsIndexSet = IndexSet()
        var reloadSectionsIndexSet = IndexSet()

        var moveRowsIndexPaths = [(IndexPath, IndexPath)]()
        var insertRowsIndexPaths = [IndexPath]()
        var deleteRowsIndexPaths = [IndexPath]()

        var reloadRowTuples = [(RowProtocol, IndexPath)]()

        for (oldSectionIndex, oldSection) in oldSections.enumerated() {
            if let sectionIndex = sections.index(where: { $0.id == oldSection.id }) {
                let section = sections[sectionIndex]
                var usedIndexes = [Int]()
                for (oldRowIndex, oldRow) in oldSection.rows.enumerated() {
                    var rowIndex: Int?
                    for (index, row) in section.rows.enumerated() {
                        if row.id == oldRow.id && usedIndexes.index(of: index) == nil {
                            rowIndex = index
                            usedIndexes.append(index)
                            break
                        }
                    }
                    if let rowIndex = rowIndex {
                        let row = section.rows[rowIndex]
                        if row.hash != oldRow.hash {
                            reloadRowTuples.append((row, IndexPath(row: oldRowIndex, section: oldSectionIndex)))
                        }
                        if rowIndex != oldRowIndex {
                            moveRowsIndexPaths.append((IndexPath(row: oldRowIndex, section: oldSectionIndex), IndexPath(row: rowIndex, section: sectionIndex)))
                        }
                    } else {
                        deleteRowsIndexPaths.append(IndexPath(row: oldRowIndex, section: oldSectionIndex))
                    }
                }

                for (rowIndex, row) in section.rows.enumerated() {
                    if !oldSection.rows.contains(where: { $0.id == row.id }) {
                        insertRowsIndexPaths.append(IndexPath(row: rowIndex, section: sectionIndex))
                    }
                }

                if !section.isSameState(with: oldSection) {
                    reloadSectionsIndexSet.insert(oldSectionIndex)
                }
            } else {
                deleteSectionsIndexSet.insert(oldSectionIndex)
            }
        }

        for (sectionIndex, section) in sections.enumerated() {
            if !oldSections.contains(where: { $0.id == section.id }) {
                insertSectionsIndexSet.insert(sectionIndex)
            }
        }

        if !reloadRowTuples.isEmpty {
//            LogHelper.instance.log(self, "Reload Rows: \(reloadRowTuples.map { "\($1.section):\($1.row)" }.joined(separator: ", "))")

            for reloadRowTuple in reloadRowTuples {
                if let cell = cellForRow(at: reloadRowTuple.1) {
                    sectionDataSource?.unbind(cell: cell)
                    reloadRowTuple.0.bindCell(cell: cell, animated: true)
                }
            }
        }

        if !insertSectionsIndexSet.isEmpty || !deleteSectionsIndexSet.isEmpty || !reloadSectionsIndexSet.isEmpty || !moveRowsIndexPaths.isEmpty || !insertRowsIndexPaths.isEmpty || !deleteRowsIndexPaths.isEmpty {
            beginUpdates()
            if !insertSectionsIndexSet.isEmpty {
//                LogHelper.instance.log(self, "Insert Sections: \(insertSectionsIndexSet.map { "\($0)" }.joined(separator: ", "))")
                insertSections(insertSectionsIndexSet, with: .top)
            }
            if !deleteSectionsIndexSet.isEmpty {
//                LogHelper.instance.log(self, "Delete Sections: \(deleteSectionsIndexSet.map { "\($0)" }.joined(separator: ", "))")
                deleteSections(deleteSectionsIndexSet, with: .none)
            }
            if !reloadSectionsIndexSet.isEmpty {
//                LogHelper.instance.log(self, "Reload Sections: \(reloadSectionsIndexSet.map { "\($0)" }.joined(separator: ", "))")
                reloadSections(reloadSectionsIndexSet, with: .automatic)
            }

            if !moveRowsIndexPaths.isEmpty {
//                LogHelper.instance.log(self, "Move Rows: \(moveRowsIndexPaths.map { "\($0.section):\($0.row)---\($1.section):\($1.row)" }.joined(separator: ", "))")
                for (at, to) in moveRowsIndexPaths {
                    moveRow(at: at, to: to)
                }
            }
            if !insertRowsIndexPaths.isEmpty {
//                LogHelper.instance.log(self, "Insert Rows: \(insertRowsIndexPaths.map { "\($0.section):\($0.row)" }.joined(separator: ", "))")
                insertRows(at: insertRowsIndexPaths, with: .top)
            }
            if !deleteRowsIndexPaths.isEmpty {
//                LogHelper.instance.log(self, "Delete Rows: \(deleteRowsIndexPaths.map { "\($0.section):\($0.row)" }.joined(separator: ", "))")
                deleteRows(at: deleteRowsIndexPaths, with: .top)
                deleteRowsIndexPaths.forEach { triggerBottomReachedIfRequired(indexPath: $0) }
            }
            endUpdates()
        }

    }

    open func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }

    open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = sections[indexPath.section].rows[indexPath.row]
        return (row.dynamicHeight?(width)).map { $0 + 1 / UIScreen.main.scale } ?? row.height // adding separator height
    }

    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        triggerBottomReachedIfRequired(indexPath: indexPath)
        let section = sections[indexPath.section]
        return tableView.dequeueReusableCell(withIdentifier: section.rows[indexPath.row].reuseIdentifier) ?? {
                print("Can't dequeue cell, did you forget to register cell?")
                return UITableViewCell(style: .default, reuseIdentifier: "")
            }()
    }

    open func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//        LogHelper.instance.log("CoreCells", "will Display cell:  \(AppSession.address(of: cell)) - at \(indexPath.row)")
        sections[indexPath.section].rows[indexPath.row].bindCell(cell: cell, animated: false)
    }

    open func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//        LogHelper.instance.log("CoreCells", "did End Displaying cell:  \(AppSession.address(of: cell)) - at \(indexPath.row)")
        sectionDataSource?.unbind(cell: cell)
    }

    open func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let row = sections[indexPath.section].rows[indexPath.row]
        return !row.rowActions.isEmpty || row.deleteRowAction != nil
    }

    open func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let row = sections[indexPath.section].rows[indexPath.row]
        let cell = tableView.cellForRow(at: indexPath)

        if !row.rowActions.isEmpty {
            return row.rowActions.map { rowAction in
                let action = UITableViewRowAction(style: .normal, title: "          ") { [weak self] _, _ in
                    self?.setEditing(false, animated: true)
                    rowAction.action(cell)
                }
                action.backgroundColor = UIColor(patternImage: patternImage(rowAction: rowAction, rowHeight: row.height))
                return action
            }
        }

        if let deleteRowAction = row.deleteRowAction {
            return [
                UITableViewRowAction(style: .destructive, title: deleteRowAction.title) { _, _ in
                    deleteRowAction.action()
                }
            ]
        }

        return nil
    }

    @available(iOS 11, *)
    public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let row = sections[indexPath.section].rows[indexPath.row]
        let cell = cellForRow(at: indexPath)

        if !row.rowActions.isEmpty {
            let config = UISwipeActionsConfiguration(actions: row.rowActions.map { rowAction in
                let action = UIContextualAction(style: .normal, title: nil) { _, _, handler in
                    rowAction.action(cell)
                    handler(true)
                }
                action.backgroundColor = UIColor(patternImage: patternImage(rowAction: rowAction, rowHeight: row.height))
                return action
            })
            config.performsFirstActionWithFullSwipe = false
            return config
        }

        if let deleteRowAction = row.deleteRowAction {
            return UISwipeActionsConfiguration(actions: [
                UIContextualAction(style: .destructive, title: deleteRowAction.title) { _, _, handler in
                    deleteRowAction.action()
                    handler(true)
                }
            ])
        }

        return nil
    }

    open func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return sections[section].getHeaderHeight(containerWidth: width)
    }

    open func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return sections[section].getFooterHeight(containerWidth: width)
    }

    open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return sections[section].getHeaderView(tableView: tableView)
    }

    open func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return sections[section].getFooterView(tableView: tableView)
    }

    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if sections[indexPath.section].rows[indexPath.row].autoDeselect {
            tableView.deselectRow(at: indexPath, animated: true)
        }

        if let cell = cellForRow(at: indexPath) {
            sections[indexPath.section].rows[indexPath.row].onSelect(cell: cell)
        }
    }

    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        sectionDataSource?.didScroll()
        if isDragging && !isDecelerating {
            sectionDataSource?.userDidScroll()
        }
    }

    open func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        sectionDataSource?.userWillDragging()
    }

    open func triggerBottomReachedIfRequired() {
        indexPathsForVisibleRows?.forEach { indexPath in
            triggerBottomReachedIfRequired(indexPath: indexPath)
        }
    }

    private func triggerBottomReachedIfRequired(indexPath: IndexPath) {
        let section = sections[indexPath.section]

        if section.paginating && indexPath.row > section.rows.count - 5 {
            sectionDataSource?.onBottomReached()
        }
    }

    private func patternImage(rowAction: RowAction, rowHeight: CGFloat) -> UIImage {
        let containerSize = CGSize(width: 75, height: 74)
        let iconOffset: CGFloat = 14
        let iconSize = CGSize(width: 24, height: 24)
        let textHorizontalMargin: CGFloat = 3
        let textContainerSize = CGSize(width: containerSize.width - textHorizontalMargin * 2, height: containerSize.height - iconOffset - iconSize.height)

        let offsetY = max(0, (rowHeight - containerSize.height) / 2)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let attributedText = NSAttributedString(string: rowAction.title, attributes: [NSAttributedStringKey.paragraphStyle: paragraphStyle, NSAttributedStringKey.foregroundColor: UIColor.white, NSAttributedStringKey.font: UIFont.systemFont(ofSize: 13)])
        let textSize = attributedText.boundingRect(with: CGSize(width: textContainerSize.width, height: .greatestFiniteMagnitude), options: [.usesFontLeading, .usesLineFragmentOrigin], context: nil).size

        var patternImage: UIImage?

        UIGraphicsBeginImageContextWithOptions(CGSize(width: containerSize.width * 2, height: rowHeight), false, UIScreen.main.scale)
        if let context = UIGraphicsGetCurrentContext() {
            context.setFillColor(rowAction.color.cgColor)
            context.fill(CGRect(x: 0, y: 0, width: containerSize.width * 2, height: rowHeight))

            if let icon = rowAction.icon {
                icon.draw(in: CGRect(x: (containerSize.width - icon.size.width) / 2, y: offsetY + iconOffset + (iconSize.height - icon.size.height) / 2, width: icon.size.width, height: icon.size.height))
            }

            let textPosition = CGPoint(x: (containerSize.width - textSize.width) / 2, y: offsetY + iconOffset + iconSize.height + max(0, textContainerSize.height - textSize.height) / 2)
            attributedText.draw(in: CGRect(origin: textPosition, size: textSize))

            patternImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        }
        return patternImage ?? UIImage()
    }

}

public protocol RowProtocol {
    var id: String { get }
    var hash: String? { get }
    var height: CGFloat { get }
    var separatorInset: UIEdgeInsets? { get }
    var autoDeselect: Bool { get }
    var rowActions: [RowAction] { get }
    var deleteRowAction: DeleteRowAction? { get }
    var reuseIdentifier: String { get }
    var dynamicHeight: ((CGFloat) -> CGFloat)? { get }
    func bindCell(cell: UITableViewCell, animated: Bool)
    func onSelect(cell: UITableViewCell)
}

public protocol SectionProtocol {
    var id: String { get }
    var paginating: Bool { get }
    var rows: [RowProtocol] { get }
    func getHeaderHeight(containerWidth: CGFloat) -> CGFloat
    func getFooterHeight(containerWidth: CGFloat) -> CGFloat
    func getHeaderView(tableView: UITableView) -> UIView?
    func getFooterView(tableView: UITableView) -> UIView?
    func isSameState(with section: SectionProtocol) -> Bool
}

public enum ViewState<T: UITableViewHeaderFooterView>: Equatable {
    case margin(height: CGFloat)
    case marginColor(height: CGFloat, color: UIColor?)
    case cellType(hash: String, binder: ((T) -> ())?, dynamicHeight: (CGFloat) -> CGFloat)
    case text(text: String, topMargin: CGFloat, bottomMargin: CGFloat)
    case spinner

    public static func ==(lhs: ViewState, rhs: ViewState) -> Bool {
        switch (lhs, rhs) {
        case let (.margin(heightA), .margin(heightB)):
            return heightA == heightB
        case let (.cellType(hashA, _, _), .cellType(hashB, _, _)):
            return hashA == hashB
        case let (.text(textA, topMarginA, bottomMarginA), .text(textB, topMarginB, bottomMarginB)):
            return textA == textB && topMarginA == topMarginB && bottomMarginA == bottomMarginB
        case (.spinner, .spinner):
            return true
        default:
            return false
        }
    }
}

public struct Section<H: UITableViewHeaderFooterView, F: UITableViewHeaderFooterView>: SectionProtocol {
    public let id: String
    public let paginating: Bool
    let headerState: ViewState<H>
    let footerState: ViewState<F>
    public var rows: [RowProtocol]

    public func getHeaderHeight(containerWidth: CGFloat) -> CGFloat { return getHeight(viewState: headerState, containerWidth: containerWidth) }
    public func getFooterHeight(containerWidth: CGFloat) -> CGFloat { return getHeight(viewState: footerState, containerWidth: containerWidth) }

    public func isSameState(with section: SectionProtocol) -> Bool {
        guard let section = section as? Section else { return false }
        return footerState == section.footerState && headerState == section.headerState
    }

    public init(id: String, paginating: Bool = false, headerState: ViewState<H> = .margin(height: 0), footerState: ViewState<F> = .margin(height: 0), rows: [RowProtocol] = []) {
        self.id = id
        self.paginating = paginating
        self.headerState = headerState
        self.footerState = footerState
        self.rows = rows
    }

    public func getHeaderView(tableView: UITableView) -> UIView? {
        return getView(tableView: tableView, viewState: headerState)
    }

    public func getFooterView(tableView: UITableView) -> UIView? {
        return getView(tableView: tableView, viewState: footerState)
    }

    private func getHeight<T>(viewState: ViewState<T>, containerWidth: CGFloat) -> CGFloat {
        if case let .margin(height) = viewState {
            return height
        }

        if case let .marginColor(height, _) = viewState {
            return height
        }

        if case let .cellType(_, _, dynamicHeight) = viewState {
            return dynamicHeight(containerWidth)
        }

        if case let .text(text, topMargin, bottomMargin) = viewState {
            return SectionLabelView.height(forContainerWidth: containerWidth, text: text, additionalMargins: topMargin + bottomMargin)
        }

        if case .spinner = viewState {
            return 50
        }

        return 44 // fallback
    }

    private func getView<T>(tableView: UITableView, viewState: ViewState<T>) -> UIView? {
        if case let .cellType(_, binder, _) = viewState, let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: String(describing: T.self)) as? T {
            binder?(view)
            return view
        }

        if case let .text(text, topMargin, _) = viewState, let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: String(describing: SectionLabelView.self)) as? SectionLabelView {
            view.bind(title: text, topMargin: topMargin)
            return view
        }

        if case .spinner = viewState, let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: String(describing: SectionSpinnerView.self)) as? SectionSpinnerView {
            view.bind()
            return view
        }

        if case let .marginColor(_, color) = viewState, let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: String(describing: SectionColorHeader.self)) as? SectionColorHeader {
            view.backgroundView?.backgroundColor = color
            return view
        }

        return nil
    }
}

public struct Row<T: UITableViewCell>: RowProtocol {
    public let id: String
    public var hash: String?
    public let height: CGFloat
    public let separatorInset: UIEdgeInsets?
    public var autoDeselect: Bool
    public var rowActions: [RowAction]
    public var deleteRowAction: DeleteRowAction?
    public let reuseIdentifier: String
    public var dynamicHeight: ((CGFloat) -> CGFloat)?
    var bind: ((T, Bool) -> ())?
    var action: ((T) -> ())?

    public init(id: String, hash: String? = nil, height: CGFloat? = nil, separatorInset: UIEdgeInsets? = nil, autoDeselect: Bool = false, rowActions: [RowAction] = [], deleteRowAction: DeleteRowAction? = nil, dynamicHeight: ((CGFloat) -> CGFloat)? = nil, bind: ((T, Bool) -> ())? = nil, action: ((T) -> ())? = nil) {
        self.id = id
        self.hash = hash
        self.height = height ?? 44
        self.separatorInset = separatorInset
        self.autoDeselect = autoDeselect
        self.rowActions = rowActions
        self.deleteRowAction = deleteRowAction
        self.reuseIdentifier = String(describing: T.self)
        self.dynamicHeight = dynamicHeight
        self.bind = bind
        self.action = action
    }

    public func bindCell(cell: UITableViewCell, animated: Bool) {
        if let cell = cell as? T {
            bind?(cell, animated)
        }

        if let separatorInset = separatorInset {
            cell.separatorInset = separatorInset
        }
    }

    public func onSelect(cell: UITableViewCell) {
        if let cell = cell as? T {
            action?(cell)
        }
    }

    static public func empty(id: String, height: CGFloat, backgroundColor: UIColor? = nil) -> RowProtocol {
        return Row<SectionEmptyCell>(id: id, height: height, bind: { cell, _ in
            if let backgroundColor = backgroundColor {
                cell.backgroundColor = backgroundColor
            }
        })
    }

}

public struct RowAction {
    let icon: UIImage?
    let title: String
    let color: UIColor
    var action: (UITableViewCell?) -> ()

    public init(icon: UIImage?, title: String, color: UIColor, action: @escaping (UITableViewCell?) -> ()) {
        self.icon = icon
        self.title = title
        self.color = color
        self.action = action
    }

}

public struct DeleteRowAction {
    let title: String
    var action: () -> ()

    public init(title: String, action: @escaping () -> ()) {
        self.title = title
        self.action = action
    }

}
