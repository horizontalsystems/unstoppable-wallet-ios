import UIKit
import ActionSheet
import ThemeKit
import SectionsTableView
import ComponentKit

class BottomSingleSelectorViewController: ThemeActionSheetController {
    private let config: Config
    private let onSelectIndex: (Int) -> ()

    private let titleView = BottomSheetTitleView()
    private let tableView = SelfSizedSectionsTableView(style: .grouped)

    init(config: Config, onSelectIndex: @escaping (Int) -> ()) {
        self.config = config
        self.onSelectIndex = onSelectIndex

        super.init()
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

        titleView.title = config.title

        switch config.icon {
        case .local(let name):
            titleView.image = UIImage(named: name)?.withTintColor(.themeJacob)
        case .remote(let url, let placeholder):
            titleView.set(imageUrl: url, placeholder: placeholder.flatMap { UIImage(named: $0) })
        }

        titleView.onTapClose = { [weak self] in
            self?.dismiss(animated: true)
        }

        var lastView: UIView = titleView
        var lastMargin: CGFloat = .margin12

        if let description = config.description {
            let descriptionView = HighlightedDescriptionView()

            view.addSubview(descriptionView)
            descriptionView.snp.makeConstraints { maker in
                maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
                maker.top.equalTo(titleView.snp.bottom).offset(CGFloat.margin12)
            }

            descriptionView.text = description

            lastView = descriptionView
            lastMargin = .margin12
        }

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(lastView.snp.bottom).offset(lastMargin)
            maker.bottom.equalTo(view.safeAreaLayoutGuide).inset(CGFloat.margin24)
        }

        tableView.sectionDataSource = self

        tableView.buildSections()
    }

    private func onSelect(index: Int) {
        onSelectIndex(index)
        dismiss(animated: true)
    }

}

extension BottomSingleSelectorViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "main",
                    rows: config.viewItems.enumerated().map { index, viewItem in
                        let isFirst = index == 0
                        let isLast = index == config.viewItems.count - 1

                        return CellBuilderNew.row(
                                rootElement: .hStack([
                                    .image24 { component in
                                        if let icon = viewItem.icon {
                                            switch icon {
                                            case .local(let name):
                                                component.imageView.image = UIImage(named: name)
                                            case .remote(let url, let placeholder):
                                                component.setImage(urlString: url, placeholder: placeholder.flatMap { UIImage(named: $0) })
                                            }
                                            component.isHidden = false
                                        } else {
                                            component.isHidden = true
                                        }
                                    },
                                    .vStackCentered([
                                        .hStack([
                                            .text { component in
                                                component.font = .body
                                                component.textColor = .themeLeah
                                                component.text = viewItem.title
                                                component.setContentHuggingPriority(.required, for: .horizontal)
                                            },
                                            .margin8,
                                            .badge { component in
                                                component.isHidden = viewItem.badge == nil
                                                component.badgeView.set(style: .small)
                                                component.badgeView.text = viewItem.badge
                                            },
                                            .margin0,
                                            .text { _ in }
                                        ]),
                                        .margin(1),
                                        .text { component in
                                            component.font = .subhead2
                                            component.textColor = .themeGray
                                            component.lineBreakMode = .byTruncatingMiddle
                                            component.text = viewItem.subtitle
                                        }
                                    ]),
                                    .image20 { component in
                                        component.imageView.isHidden = !viewItem.selected
                                        component.imageView.image = UIImage(named: "check_1_20")?.withTintColor(.themeJacob)
                                    }
                                ]),
                                tableView: tableView,
                                id: "item_\(index)",
                                hash: "\(viewItem.selected)",
                                height: .heightDoubleLineCell,
                                bind: { cell in
                                    cell.set(backgroundStyle: .bordered, isFirst: isFirst, isLast: isLast)
                                },
                                action: { [weak self] in
                                    self?.onSelect(index: index)
                                }
                        )
                    }
            )
        ]
    }

}

extension BottomSingleSelectorViewController {

    struct Config {
        let icon: IconStyle
        let title: String
        let description: String?
        let viewItems: [ViewItem]
    }

    struct ViewItem {
        let icon: IconStyle?
        let title: String
        let subtitle: String
        let badge: String?
        let selected: Bool

        init(icon: IconStyle? = nil, title: String, subtitle: String, badge: String? = nil, selected: Bool) {
            self.icon = icon
            self.title  = title
            self.subtitle = subtitle
            self.badge = badge
            self.selected = selected
        }
    }

    enum IconStyle {
        case local(name: String)
        case remote(url: String, placeholder: String?)
    }

}
