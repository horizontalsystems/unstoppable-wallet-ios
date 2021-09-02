import UIKit
import ActionSheet
import ThemeKit
import SectionsTableView
import MarketKit
import ComponentKit

class PrivacySyncModeViewController: ThemeActionSheetController {
    private let delegate: IPrivacySyncModeViewDelegate

    private let titleView = BottomSheetTitleView()
    private let descriptionView = HighlightedDescriptionView()
    private let tableView = SelfSizedSectionsTableView(style: .grouped)
    private let doneButton = ThemeButton()

    private var viewItems = [PrivacySyncModeModule.ViewItem]()

    init(delegate: IPrivacySyncModeViewDelegate) {
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

        titleView.onTapClose = { [weak self] in
            self?.dismiss(animated: true)
        }

        view.addSubview(descriptionView)
        descriptionView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalTo(titleView.snp.bottom).offset(CGFloat.margin3x)
        }

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(descriptionView.snp.bottom).offset(CGFloat.margin4x)
        }

        tableView.registerCell(forClass: F4Cell.self)
        tableView.sectionDataSource = self

        view.addSubview(doneButton)
        doneButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalTo(tableView.snp.bottom).offset(CGFloat.margin6x)
            maker.bottom.equalToSuperview().inset(CGFloat.margin4x)
            maker.height.equalTo(CGFloat.heightButton)
        }

        doneButton.apply(style: .primaryYellow)
        doneButton.setTitle("Done".localized, for: .normal)
        doneButton.addTarget(self, action: #selector(_onTapDone), for: .touchUpInside)

        delegate.onLoad()

        tableView.reload()
    }

    @objc private func _onTapDone() {
        delegate.onTapDone()
    }

}

extension PrivacySyncModeViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "main",
                    rows: viewItems.enumerated().map { index, viewItem in
                        let isLast = index == viewItems.count - 1

                        return Row<F4Cell>(
                                id: "item_\(index)",
                                hash: "\(viewItem.selected)",
                                height: .heightDoubleLineCell,
                                bind: { cell, _ in
                                    cell.set(backgroundStyle: .transparent, isLast: isLast)
                                    cell.title = viewItem.title
                                    cell.subtitle = viewItem.subtitle
                                    cell.valueImage = viewItem.selected ? UIImage(named: "check_1_20")?.withRenderingMode(.alwaysTemplate) : nil
                                    cell.valueImageTintColor = .themeJacob
                                },
                                action: { [weak self] _ in
                                    self?.delegate.onTapViewItem(index: index)
                                }
                        )
                    }
            )
        ]
    }

}

extension PrivacySyncModeViewController: IPrivacySyncModeView {

    func set(coinTitle: String, coinCode: String, coinType: CoinType) {
        titleView.bind(
                title: "settings_privacy.alert_sync.title".localized,
                subtitle: coinTitle,
                image: UIImage.image(coinType: coinType)
        )

        descriptionView.text = "settings_privacy.alert_sync.description".localized(coinTitle)
    }

    func set(viewItems: [PrivacySyncModeModule.ViewItem]) {
        self.viewItems = viewItems
        tableView.reload()
    }

}
