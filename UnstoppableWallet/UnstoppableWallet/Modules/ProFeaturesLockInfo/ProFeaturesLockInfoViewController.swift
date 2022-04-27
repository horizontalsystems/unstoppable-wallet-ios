import UIKit
import ActionSheet
import ThemeKit
import SectionsTableView
import ComponentKit

protocol IProFeaturesLockDelegate: AnyObject {
    func onGoToMint(viewController: UIViewController)
}

class ProFeaturesLockInfoViewController: ThemeActionSheetController {
    private let config: Config
    private weak var delegate: IProFeaturesLockDelegate?

    private let titleView = BottomSheetTitleView()
    private let tableView = SelfSizedSectionsTableView(style: .grouped)
    private let highlightedDescriptionCell = HighlightedDescriptionCell()
    private let goToMintButton = ThemeButton()
    private let cancelButton = ThemeButton()

    init(config: Config, delegate: IProFeaturesLockDelegate) {
        self.config = config
        self.delegate = delegate

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

        titleView.bind(title: config.title, subtitle: config.subtitle)
        titleView.bind(image: config.icon, tintColor: .themeJacob)

        titleView.onTapClose = { [weak self] in
            self?.dismiss(animated: true)
        }

        var lastView: UIView = titleView

        if let description = config.description {
            highlightedDescriptionCell.descriptionText = description

//            let separatorView = UIView()
//
//            view.addSubview(separatorView)
//            separatorView.snp.makeConstraints { maker in
//                maker.leading.trailing.equalToSuperview()
//                maker.top.equalTo(descriptionView.snp.bottom).offset(CGFloat.margin12)
//                maker.height.equalTo(CGFloat.heightOneDp)
//            }
//
//            separatorView.backgroundColor = .themeSteel10

//            lastView = separatorView
        }

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(lastView.snp.bottom)
        }

        tableView.sectionDataSource = self

        view.addSubview(goToMintButton)
        goToMintButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalTo(tableView.snp.bottom).offset(CGFloat.margin16)
            maker.height.equalTo(CGFloat.heightButton)
        }

        goToMintButton.apply(style: .primaryYellow)
        goToMintButton.setTitle("pro_features.lock_info.go_to_mint".localized, for: .normal)
        goToMintButton.addTarget(self, action: #selector(onTapGoToMint), for: .touchUpInside)

        view.addSubview(cancelButton)
        cancelButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalTo(goToMintButton.snp.bottom).offset(CGFloat.margin12)
            maker.bottom.equalToSuperview().inset(CGFloat.margin16)
            maker.height.equalTo(CGFloat.heightButton)
        }

        cancelButton.apply(style: .primaryGray)
        cancelButton.setTitle("button.cancel".localized, for: .normal)
        cancelButton.addTarget(self, action: #selector(onTapCancel), for: .touchUpInside)

        tableView.buildSections()
    }

    @objc private func onTapGoToMint() {
        delegate?.onGoToMint(viewController: self)
    }

    @objc private func onTapCancel() {
        dismiss(animated: true)
    }

    private var descriptionRow: RowProtocol? {
        guard let description = config.description else {
            return nil
        }

        return StaticRow(
                cell: highlightedDescriptionCell,
                id: "description",
                dynamicHeight: { width in
                    HighlightedDescriptionCell.height(containerWidth: width, text: description)
                }
        )
    }

}

extension ProFeaturesLockInfoViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        let isFirst = config.description == nil
        return [
            Section(
                    id: "description",
                    rows: [descriptionRow].flatMap { $0 }
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
                                        component.imageView.image = UIImage(named: "check_1_20")
                                    }
                                }
                        )
                    }
            )
        ]
    }

}

extension ProFeaturesLockInfoViewController {

    struct Config {
        let icon: UIImage?
        let title: String
        let subtitle: String
        let description: String?
        let viewItems: [String]

        static var coinDetails: Config {
            Config(
                    icon: UIImage(named: "lock_24"),
                    title: "pro_features.lock_info.title".localized,
                    subtitle: "pro_features.lock_info.subtitle".localized,
                    description: "pro_features.lock_info.coin_details.description".localized,
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
