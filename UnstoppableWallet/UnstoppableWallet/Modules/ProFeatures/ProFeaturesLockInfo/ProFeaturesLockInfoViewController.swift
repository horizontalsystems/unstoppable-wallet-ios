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

    private let tableView = SelfSizedSectionsTableView(style: .grouped)

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

        let titleView = BottomSheetTitleView()

        view.addSubview(titleView)
        titleView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        titleView.title = config.title
        titleView.image = config.icon?.withTintColor(.themeJacob)
        titleView.onTapClose = { [weak self] in
            self?.dismiss(animated: true)
        }

        let descriptionView = HighlightedDescriptionView()

        view.addSubview(descriptionView)
        descriptionView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalTo(titleView.snp.bottom)
        }

        descriptionView.text = config.description

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(descriptionView.snp.bottom).offset(CGFloat.margin12)
        }

        tableView.sectionDataSource = self

        let goToMintButton = ThemeButton()

        view.addSubview(goToMintButton)
        goToMintButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.top.equalTo(tableView.snp.bottom).offset(CGFloat.margin24)
            maker.bottom.equalTo(view.safeAreaLayoutGuide).inset(CGFloat.margin24)
            maker.height.equalTo(CGFloat.heightButton)
        }

        goToMintButton.apply(style: .primaryYellow)
        goToMintButton.setTitle("pro_features.lock_info.go_to_mint".localized, for: .normal)
        goToMintButton.isEnabled = false
        goToMintButton.addTarget(self, action: #selector(onTapGoToMint), for: .touchUpInside)

        tableView.buildSections()
    }

    @objc private func onTapGoToMint() {
        delegate?.onGoToMint(viewController: self)
    }

}

extension ProFeaturesLockInfoViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "main",
                    rows: config.viewItems.enumerated().map { index, viewItem in
                        let isFirst = index == 0
                        let isLast = index == config.viewItems.count - 1

                        return CellBuilder.row(
                                elements: [.text, .image20],
                                tableView: tableView,
                                id: "item_\(index)",
                                height: .heightCell48,
                                bind: { cell in
                                    cell.set(backgroundStyle: .bordered, isFirst: isFirst, isLast: isLast)

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

extension ProFeaturesLockInfoViewController {

    struct Config {
        let icon: UIImage?
        let title: String
        let description: String?
        let viewItems: [String]

        static var mountainYak: Config {
            Config(
                    icon: UIImage(named: "lock_24"),
                    title: "pro_features.lock_info.title".localized,
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
