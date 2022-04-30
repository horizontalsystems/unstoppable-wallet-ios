import UIKit
import ActionSheet
import ThemeKit
import SectionsTableView
import ComponentKit

protocol IProFeaturesActivateDelegate: AnyObject {
    func onActivate()
    func onCancel()
}

class ProFeaturesActivateViewController: ThemeViewController {
    private let config: Config
    private weak var delegate: IProFeaturesActivateDelegate?

    private let tableView = SectionsTableView(style: .grouped)
    private let activateButton = ThemeButton()

    init(config: Config, delegate: IProFeaturesActivateDelegate) {
        self.config = config
        self.delegate = delegate

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = config.title
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onTapCancel))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        tableView.sectionDataSource = self
        tableView.registerCell(forClass: ImageCell.self)

        view.addSubview(activateButton)
        activateButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalTo(tableView.snp.bottom).offset(CGFloat.margin16)
            maker.bottom.equalToSuperview().inset(CGFloat.margin16)
            maker.height.equalTo(CGFloat.heightButton)
        }

        activateButton.apply(style: .primaryYellow)
        activateButton.setTitle("pro_features.activate".localized, for: .normal)
        activateButton.addTarget(self, action: #selector(onActivate), for: .touchUpInside)

        tableView.buildSections()
    }

    @objc private func onActivate() {
        delegate?.onActivate()
    }

    @objc private func onTapCancel() {
        dismiss(animated: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        delegate?.onCancel()
    }

    private var topSections: [SectionProtocol] {
        var sections = [SectionProtocol]()

        if let image = config.image {
            sections.append(
                    Section(
                            id: "image-section",
                            headerState: .margin(height: .margin12),
                            rows: [
                                Row<ImageCell>(
                                        id: "image-cell",
                                        dynamicHeight: { width in
                                            ImageCell.height(containerWidth: width)
                                        },
                                        bind: { cell, _ in
                                            cell.image = image
                                        }
                                )
                            ]
                    )
            )
        }

        

        return sections
    }

}

extension ProFeaturesActivateViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        let isFirst = config.description == nil
        return [
            Section(
                    id: "description",
                    rows: [descriptionRow].flatMap {
                        $0
                    }
            ),
            Section(
                    id: "main",
                    rows: config.viewItems.enumerated().map { index, viewItem in
                        let isLast = index == config.viewItems.count - 1

                        return CellBuilder.row(
                                elements: [.text, .image20],
                                tableView: tableView,
                                id: "item_\(index)",
                                height: .heightCell48,
                                bind: { cell in
                                    cell.set(backgroundStyle: .transparent, isFirst: isFirst, isLast: isLast)

                                    cell.bind(index: 0) { (component: TextComponent) in
                                        component.set(style: .d1)
                                        component.text = viewItem
                                    }

                                    cell.bind(index: 1) { (component: ImageComponent) in
                                        component.imageView.image = UIImage(named: "check_1_20")?.withRenderingMode(.alwaysTemplate)
                                        component.imageView.tintColor = .themeJacob
                                    }
                                }
                        )
                    }
            )
        ]
    }

}

extension ProFeaturesActivateViewController {

    struct Config {
        let image: UIImage?
        let title: String
        let subtitle: String
        let description: String?
        let features: String
        let viewItems: [String]

        static var mountainYak: Config {
            Config(
                    image: UIImage(named: "mountain_yak"),
                    title: "pro_features.mountain_yak.activate.title".localized,
                    subtitle: "pro_features.mountain_yak.activate.subtitle".localized,
                    description: "pro_features.mountain_yak.activate.description".localized,
                    features: "pro_features.mountain_yak.activate.features".localized,
                    viewItems: [
                        "pro_features.lock_info.coin_details.volume".localized,
                        "pro_features.lock_info.coin_details.liquidity".localized,
                        "pro_features.lock_info.coin_details.active_addresses".localized,
                        "pro_features.lock_info.coin_details.transaction_count".localized,
                        "pro_features.lock_info.coin_details.transaction_volume".localized,
                    ])
        }

    }

}
