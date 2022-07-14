import SectionsTableView
import ComponentKit
import ThemeKit

extension SectionsTableView {

    func subtitleRow(text: String) -> RowProtocol {
        CellBuilder.row(
                elements: [.text],
                tableView: self,
                id: "subtitle_\(text)",
                hash: text,
                height: .heightCell48,
                bind: { cell in
                    cell.set(backgroundStyle: .transparent)
                    cell.selectionStyle = .none

                    cell.bind(index: 0) { (component: TextComponent) in
                        component.set(style: .b2)
                        component.text = text
                    }
                }
        )
    }

    func titleArrowRow(id: String, title: String, autoDeselect: Bool = false, isFirst: Bool = false, isLast: Bool = false, action: @escaping () -> ()) -> RowProtocol {
        CellBuilder.selectableRow(
                elements: [.text, .image20],
                tableView: self,
                id: id,
                height: .heightCell48,
                autoDeselect: autoDeselect,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)

                    cell.bind(index: 0) { (component: TextComponent) in
                        component.set(style: .b2)
                        component.text = title
                    }
                    cell.bind(index: 1) { (component: ImageComponent) in
                        component.imageView.image = UIImage(named: "arrow_big_forward_20")?.withTintColor(.themeGray)
                    }
                },
                action: action
        )
    }

    func imageTitleArrowRow(id: String, image: String, title: String, autoDeselect: Bool = false, isFirst: Bool = false, isLast: Bool = false, action: @escaping () -> ()) -> RowProtocol {
        CellBuilder.selectableRow(
                elements: [.image20, .text, .image20],
                tableView: self,
                id: id,
                height: .heightCell48,
                autoDeselect: autoDeselect,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)

                    cell.bind(index: 0) { (component: ImageComponent) in
                        component.imageView.image = UIImage(named: image)
                    }
                    cell.bind(index: 1) { (component: TextComponent) in
                        component.set(style: .b2)
                        component.text = title
                    }
                    cell.bind(index: 2) { (component: ImageComponent) in
                        component.imageView.image = UIImage(named: "arrow_big_forward_20")?.withTintColor(.themeGray)
                    }
                },
                action: action
        )
    }

    func imageTitleCheckRow(id: String, backgroundStyle: BaseThemeCell.BackgroundStyle = .lawrence, image: String, title: String, selected: Bool, isFirst: Bool = false, isLast: Bool = false, action: @escaping () -> ()) -> RowProtocol {
        CellBuilder.selectableRow(
                elements: [.image20, .text, .image20],
                tableView: self,
                id: id,
                hash: "\(selected)",
                height: .heightCell48,
                autoDeselect: true,
                bind: { cell in
                    cell.set(backgroundStyle: backgroundStyle, isFirst: isFirst, isLast: isLast)

                    cell.bind(index: 0) { (component: ImageComponent) in
                        component.imageView.image = UIImage(named: image)
                    }
                    cell.bind(index: 1) { (component: TextComponent) in
                        component.set(style: .b2)
                        component.text = title
                    }
                    cell.bind(index: 2) { (component: ImageComponent) in
                        component.isHidden = !selected
                        component.imageView.image = UIImage(named: "check_1_20")?.withTintColor(.themeJacob)
                    }
                },
                action: action
        )
    }

    func subtitleWithInfoButtonRow(text: String, action: @escaping () -> ()) -> RowProtocol {
        CellBuilder.selectableRow(
                elements: [.text, .image20],
                layoutMargins: UIEdgeInsets(top: 0, left: .margin32, bottom: 0, right: .margin32),
                tableView: self,
                id: "subtitle-\(text)",
                height: .margin32,
                autoDeselect: true,
                bind: { cell in
                    cell.set(backgroundStyle: .transparent, isFirst: true)

                    cell.bind(index: 0, block: { (component: TextComponent) in
                        component.set(style: .c1)
                        component.text = text.uppercased()
                    })

                    cell.bind(index: 1, block: { (component: ImageComponent) in
                        component.imageView.image = UIImage(named: "circle_information_20")?.withTintColor(.themeGray)
                    })
                },
                action: action
        )
    }

}
