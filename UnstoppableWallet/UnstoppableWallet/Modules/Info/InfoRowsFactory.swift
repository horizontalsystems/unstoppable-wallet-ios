import ThemeKit
import SectionsTableView

class InfoRowsFactory {
    public var linkAction: (() -> ())?

    public var separatorHeaderState: ViewState<InfoSeparatorHeaderView> {
        .cellType(
                hash: "separator",
                binder: nil,
                dynamicHeight: { _ in
                    InfoSeparatorHeaderView.height
                }
        )
    }

    public func header(text: String) -> ViewState<InfoHeaderView> {
        .cellType(
                hash: text,
                binder: { view in
                    view.bind(text: text)
                },
                dynamicHeight: { width in
                    InfoHeaderView.height(containerWidth: width, text: text)
                }
        )
    }

    public func header3Row(id: String, string: String) -> RowProtocol {
        Row<InfoHeader3Cell>(
                id: id,
                dynamicHeight: { containerWidth in
                    InfoHeader3Cell.height(containerWidth: containerWidth, string: string)
                },
                bind: { cell, _ in
                    cell.bind(string: string)
                }
        )
    }

    public func row(text: String) -> RowProtocol {
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

    public func linkButtonRow(title: String) -> RowProtocol {
        Row<ButtonCell>(
                id: title,
                height: ThemeButton.height(style: .secondaryDefault),
                bind: { [weak self] cell, _ in
                    cell.bind(style: .secondaryDefault, title: title, compact: true) { [weak self] in
                        self?.linkAction?()
                    }
                }
        )
    }

}
