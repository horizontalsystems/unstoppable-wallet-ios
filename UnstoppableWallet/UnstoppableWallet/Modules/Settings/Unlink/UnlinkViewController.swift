import UIKit
import ActionSheet
import ThemeKit
import SectionsTableView
import RxSwift
import RxCocoa
import ComponentKit

class UnlinkViewController: ThemeActionSheetController {
    private let viewModel: UnlinkViewModel
    private let disposeBag = DisposeBag()

    private let titleView = BottomSheetTitleView()
    private let tableView = SelfSizedSectionsTableView(style: .grouped)
    private let deleteButton = ThemeButton()

    private var viewItems = [UnlinkViewModel.ViewItem]()
    private var isLoaded = false

    init(viewModel: UnlinkViewModel) {
        self.viewModel = viewModel

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

        titleView.bind(
                title: "settings_manage_keys.delete.title".localized,
                subtitle: viewModel.accountName,
                image: UIImage(named: "warning_2_24"),
                tintColor: .themeLucian
        )

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(titleView.snp.bottom)
        }

        tableView.registerCell(forClass: CheckboxCell.self)
        tableView.sectionDataSource = self

        view.addSubview(deleteButton)
        deleteButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalTo(tableView.snp.bottom).offset(CGFloat.margin24)
            maker.bottom.equalToSuperview().inset(CGFloat.margin16)
            maker.height.equalTo(CGFloat.heightButton)
        }

        deleteButton.apply(style: .primaryRed)
        deleteButton.setTitle("security_settings.delete_alert_button".localized, for: .normal)
        deleteButton.addTarget(self, action: #selector(onTapDeleteButton), for: .touchUpInside)

        subscribe(disposeBag, viewModel.viewItemsDriver) { [weak self] in
            self?.viewItems = $0
            self?.reloadTable()
        }
        subscribe(disposeBag, viewModel.deleteEnabledDriver) { [weak self] in self?.deleteButton.isEnabled = $0 }
        subscribe(disposeBag, viewModel.successSignal) { [weak self] in
            HudHelper.instance.showSuccess(title: "alert.success_action".localized)
            self?.dismiss(animated: true)
        }

        tableView.buildSections()

        isLoaded = true
    }

    @objc private func onTapDeleteButton() {
        viewModel.onTapDelete()
    }

    private func reloadTable() {
        guard isLoaded else {
            return
        }

        tableView.reload(animated: true)
    }
}

extension UnlinkViewController: SectionsDataSource {

    private func checkboxRow(viewItem: UnlinkViewModel.ViewItem, index: Int) -> RowProtocol {
        Row<CheckboxCell>(
                id: "checkbox_\(index)",
                hash: "\(viewItem.checked)",
                dynamicHeight: { width in
                    CheckboxCell.height(containerWidth: width, text: viewItem.text)
                },
                bind: { cell, _ in
                    cell.bind(
                            text: viewItem.text,
                            checked: viewItem.checked,
                            backgroundStyle: .transparent
                    )
                },
                action: { [weak self] _ in
                    self?.viewModel.onTap(index: index)
                }
        )
    }

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "main",
                    rows: viewItems.enumerated().map {
                        checkboxRow(viewItem: $1, index: $0)
                    }
            )
        ]
    }

}
