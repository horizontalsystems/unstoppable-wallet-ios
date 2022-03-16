import SectionsTableView
import ComponentKit
import ThemeKit

extension SectionsTableView {

    func subtitleWithInfoButtonRow(text: String, action: @escaping () -> ()) -> RowProtocol {
        CellBuilder.selectableRow(
                elements: [.text, .image20],
                tableView: self,
                id: "subtitle-\(text)",
                height: .heightCell48,
                autoDeselect: true,
                bind: { cell in
                    cell.set(backgroundStyle: .transparent, isFirst: true)

                    cell.bind(index: 0, block: { (component: TextComponent) in
                        component.set(style: .b1)
                        component.text = text
                    })

                    cell.bind(index: 1, block: { (component: ImageComponent) in
                        component.imageView.image = UIImage(named: "circle_information_20")?.withTintColor(.themeGray)
                    })
                },
                action: action
        )
    }

}
