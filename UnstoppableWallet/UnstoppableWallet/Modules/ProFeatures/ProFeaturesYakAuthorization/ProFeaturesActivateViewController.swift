import UIKit
import ActionSheet
import ThemeKit
import SectionsTableView
import ComponentKit

class ProFeaturesActivateViewController: ThemeViewController {
    private let config: Config

    private let tableView = SectionsTableView(style: .grouped)

    private let backupButtonHolder = BottomGradientHolder()
    private let activateButton = PrimaryButton()

    private let onSuccess: (() -> ())?
    private let onCancel: (() -> ())?

    init(config: Config, onSuccess: (() -> ())?, onCancel: (() -> ())?) {
        self.config = config
        self.onSuccess = onSuccess
        self.onCancel = onCancel

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
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false

        tableView.registerCell(forClass: ImageCell.self)
        tableView.registerCell(forClass: MarkdownHeader1Cell.self)
        tableView.registerCell(forClass: MarkdownHeader3Cell.self)
        tableView.registerCell(forClass: MarkdownTextCell.self)
        tableView.registerCell(forClass: MarkdownListItemCell.self)

        view.addSubview(backupButtonHolder)
        backupButtonHolder.snp.makeConstraints { maker in
            maker.top.equalTo(tableView.snp.bottom).offset(-CGFloat.margin16)
            maker.leading.trailing.bottom.equalToSuperview()
        }

        backupButtonHolder.addSubview(activateButton)
        activateButton.snp.makeConstraints { maker in
            maker.leading.top.trailing.bottom.equalToSuperview().inset(CGFloat.margin24)
        }

        activateButton.set(style: .yellow)
        activateButton.setTitle("pro_features.activate".localized, for: .normal)
        activateButton.addTarget(self, action: #selector(onActivate), for: .touchUpInside)

        tableView.buildSections()
    }

    @objc private func onActivate() {
        onSuccess?()
    }

    @objc private func onTapCancel() {
        dismiss(animated: true)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        onCancel?()
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

        var infoRows = [RowProtocol]()

        let subtitleString = NSAttributedString(string: config.subtitle, attributes: [.font: UIFont.title3, .foregroundColor: UIColor.themeJacob])
        infoRows.append(MarkdownViewController.header1Row(id: "subtitle-cell", attributedString: subtitleString))

        if let description = config.description {
            let descriptionString = NSAttributedString(string: description, attributes: [.font: UIFont.body, .foregroundColor: UIColor.themeBran])
            infoRows.append(MarkdownViewController.textRow(id: "description-cell", attributedString: descriptionString, delegate: nil))
        }

        if let features = config.features {
            let featuresString = NSAttributedString(string: features, attributes: [.font: UIFont.headline2, .foregroundColor: UIColor.themeJacob])
            infoRows.append(MarkdownViewController.header3Row(id: "features-cell", attributedString: featuresString))
        }

        for viewItem in config.viewItems {
            let viewItemString = NSAttributedString(string: viewItem, attributes: [.font: UIFont.body, .foregroundColor: UIColor.themeBran])
            infoRows.append(MarkdownViewController.listItemRow(id: "\(viewItem)-cell", attributedString: viewItemString, prefix: "•", tightTop: false, tightBottom: false))
        }
        
        sections.append(
                Section(
                        id: "info-section",
                        footerState: .margin(height: .margin32),
                        rows: infoRows
                )
        )

        return sections
    }

}

extension ProFeaturesActivateViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        topSections
    }

}
extension ProFeaturesActivateViewController {

    struct Config {
        let image: UIImage?
        let title: String
        let subtitle: String
        let description: String?
        let features: String?
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
