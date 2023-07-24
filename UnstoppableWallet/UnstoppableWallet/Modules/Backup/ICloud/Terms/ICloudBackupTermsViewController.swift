import UIKit
import SnapKit
import Combine
import ThemeKit
import ComponentKit
import UIExtensions
import SectionsTableView

class ICloudBackupTermsViewController: ThemeViewController {
    private let viewModel: ICloudBackupTermsViewModel
    private var cancellables = Set<AnyCancellable>()

    private let tableView = SectionsTableView(style: .grouped)
    private let continueButton = PrimaryButton()

    private var viewItems = [ICloudBackupTermsViewModel.ViewItem]()
    private var loaded = false

    init(viewModel: ICloudBackupTermsViewModel) {
        self.viewModel = viewModel

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "backup.cloud.title".localized
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onTapClose))
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.sectionDataSource = self

        let gradientWrapperView = BottomGradientHolder()

        gradientWrapperView.add(to: self, under: tableView)
        gradientWrapperView.addSubview(continueButton)

        continueButton.isEnabled = false
        continueButton.set(style: .yellow)
        continueButton.setTitle("button.continue".localized, for: .normal)
        continueButton.addTarget(self, action: #selector(onTapContinue), for: .touchUpInside)

        viewItems = viewModel.viewItems
        viewModel.$viewItems
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in
                    self?.viewItems = $0
                    self?.reloadTable()
                }
                .store(in: &cancellables)

        continueButton.isEnabled = viewModel.buttonEnabled
        viewModel.$buttonEnabled
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in
                    self?.continueButton.isEnabled = $0
                }
                .store(in: &cancellables)

        viewModel.showModulePublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in
                    self?.showModule()
                }
                .store(in: &cancellables)

        viewModel.showCloudNotAvailablePublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in
                    self?.showNotCloudAvailable()
                }
                .store(in: &cancellables)


        loaded = true
        reloadTable()
    }

    @objc func onTapClose() {
        dismiss(animated: true)
    }

    @objc private func onTapContinue() {
        viewModel.onContinue()
    }

    private func showNotCloudAvailable() {
        let viewController = BottomSheetModule.cloudNotAvailableController()
        present(viewController, animated: true)
    }

    private func showModule() {
        let controller = BackupCloudModule.backupName(account: viewModel.account)
        navigationController?.pushViewController(controller, animated: true)
    }

    private func reloadTable() {
        if loaded {
            tableView.reload(animated: true)
        }
    }

}

extension ICloudBackupTermsViewController: SectionsDataSource {

    private func row(viewItem: ICloudBackupTermsViewModel.ViewItem, index: Int, isFirst: Bool, isLast: Bool) -> RowProtocol {
        let backgroundStyle: BaseThemeCell.BackgroundStyle = .lawrence
        let textFont: UIFont = .subhead2
        let text = viewItem.text

        return CellBuilderNew.row(
                rootElement: .hStack([
                    .image24 { component in
                        component.imageView.image = UIImage(named: viewItem.checked ? "checkbox_active_24" : "checkbox_diactive_24")
                    },
                    .text { component in
                        component.font = textFont
                        component.textColor = .themeLeah
                        component.text = text
                        component.numberOfLines = 0
                    }
                ]),
                tableView: tableView,
                id: "row-\(index)",
                hash: "\(viewItem.checked)",
                autoDeselect: true,
                dynamicHeight: { width in
                    CellBuilderNew.height(
                            containerWidth: width,
                            backgroundStyle: backgroundStyle,
                            text: text,
                            font: textFont,
                            verticalPadding: .margin16,
                            elements: [.fixed(width: .iconSize24), .multiline]
                    )
                },
                bind: { cell in
                    cell.set(backgroundStyle: backgroundStyle, isFirst: isFirst, isLast: isLast)
                },
                action: { [weak self] in
                    self?.viewModel.onToggle(index: index)
                }
        )
    }

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                id: "description",
                headerState: .margin(height: .margin12),
                footerState: .margin(height: .margin32),
                rows: [
                    tableView.highlightedDescriptionRow(
                            id: "description",
                            text: "backup.cloud.description".localized,
                            ignoreBottomMargin: true
                    )
                ]
            ),
            Section(
                id: "terms",
                footerState: .margin(height: .margin32),
                rows: viewItems.enumerated().map { index, viewItem in
                    row(viewItem: viewItem, index: index, isFirst: index == 0, isLast: index == viewItems.count - 1)
                }
            )
        ]
    }

}
