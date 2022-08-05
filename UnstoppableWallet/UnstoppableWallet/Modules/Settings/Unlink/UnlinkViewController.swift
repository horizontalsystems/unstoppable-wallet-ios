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
    private let deleteButton = PrimaryButton()

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

        titleView.title = "settings_manage_keys.delete.title".localized
        titleView.image = UIImage(named: "trash_24")?.withTintColor(.themeLucian)
        titleView.onTapClose = { [weak self] in
            self?.dismiss(animated: true)
        }

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(titleView.snp.bottom)
        }

        tableView.registerCell(forClass: CheckboxCell.self)
        tableView.sectionDataSource = self

        view.addSubview(deleteButton)
        deleteButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.top.equalTo(tableView.snp.bottom).offset(CGFloat.margin24)
            maker.bottom.equalTo(view.safeAreaLayoutGuide).inset(CGFloat.margin24)
        }

        deleteButton.set(style: .red)
        deleteButton.setTitle("security_settings.delete_alert_button".localized, for: .normal)
        deleteButton.addTarget(self, action: #selector(onTapDeleteButton), for: .touchUpInside)

        subscribe(disposeBag, viewModel.viewItemsDriver) { [weak self] in
            self?.viewItems = $0
            self?.reloadTable()
        }
        subscribe(disposeBag, viewModel.deleteEnabledDriver) { [weak self] in self?.deleteButton.isEnabled = $0 }
        subscribe(disposeBag, viewModel.successSignal) { [weak self] in
            HudHelper.instance.show(banner: .deleted)
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

    private func checkboxRow(viewItem: UnlinkViewModel.ViewItem, index: Int, isFirst: Bool, isLast: Bool) -> RowProtocol {
        Row<CheckboxCell>(
                id: "checkbox_\(index)",
                hash: "\(viewItem.checked)",
                autoDeselect: true,
                dynamicHeight: { width in
                    CheckboxCell.height(containerWidth: width, text: viewItem.text, backgroundStyle: .lawrence)
                },
                bind: { cell, _ in
                    cell.bind(
                            text: viewItem.text,
                            checked: viewItem.checked,
                            backgroundStyle: .bordered,
                            isFirst: isFirst,
                            isLast: isLast
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
                    rows: viewItems.enumerated().map { index, viewItem in
                        checkboxRow(viewItem: viewItem, index: index, isFirst: index == 0, isLast: index == viewItems.count - 1)
                    }
            )
        ]
    }

}
