import Combine
import ComponentKit
import SectionsTableView
import SnapKit
import ThemeKit
import UIKit
import UniformTypeIdentifiers

class RestoreTypeViewController: ThemeViewController {
    private let viewModel: RestoreTypeViewModel
    private var cancellables = Set<AnyCancellable>()

    private let tableView = SectionsTableView(style: .grouped)
    private weak var returnViewController: UIViewController?

    init(viewModel: RestoreTypeViewModel, returnViewController: UIViewController?) {
        self.viewModel = viewModel
        self.returnViewController = returnViewController

        super.init()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = viewModel.title

        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(didTapCancel))
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        tableView.sectionDataSource = self

        viewModel.showModulePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.show(type: $0)
            }
            .store(in: &cancellables)

        viewModel.showCloudNotAvailablePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.showNotCloudAvailable()
            }
            .store(in: &cancellables)

        viewModel.showWrongFilePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.showWrongFile()
            }
            .store(in: &cancellables)

        viewModel.showRestoreBackupPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] namedSource in
                self?.show(source: namedSource)
            }
            .store(in: &cancellables)

        tableView.buildSections()
    }

    @objc private func didTapCancel() {
        dismiss(animated: true)
    }

    private func row(_ type: RestoreTypeModule.RestoreType) -> RowProtocol {
        let backgroundStyle: BaseThemeCell.BackgroundStyle = .lawrence
        let titleFont: UIFont = .headline2
        let valueFont: UIFont = .subhead2

        let icon = viewModel.icon(type: type)
        let title = viewModel.title(type: type)
        let description = viewModel.description(type: type)

        return CellBuilderNew.row(
            rootElement: .hStack([
                .image24 { (component: ImageComponent) in
                    component.imageView.image = UIImage(named: icon)
                },
                .vStackCentered([
                    .text { (component: TextComponent) in
                        component.font = titleFont
                        component.textColor = .themeLeah
                        component.text = title
                        component.numberOfLines = 0
                    },
                    .margin4,
                    .text { (component: TextComponent) in
                        component.font = valueFont
                        component.textColor = .themeGray
                        component.text = description
                        component.numberOfLines = 0
                    },
                ]),
            ]),
            tableView: tableView,
            id: description,
            autoDeselect: true,
            dynamicHeight: { containerWidth in
                let size = CellBuilderNew.height(
                    containerWidth: containerWidth,
                    backgroundStyle: backgroundStyle,
                    text: title,
                    font: titleFont,
                    verticalPadding: .margin24,
                    elements: [.fixed(width: .iconSize24), .multiline]
                ) + .margin4 +
                    CellBuilderNew.height(
                        containerWidth: containerWidth,
                        backgroundStyle: backgroundStyle,
                        text: description,
                        font: valueFont,
                        verticalPadding: 0,
                        elements: [.fixed(width: .iconSize24), .multiline]
                    )

                return max(106, size) // usually cells will have 3 lines
            },
            bind: { cell in
                cell.set(backgroundStyle: backgroundStyle, isFirst: true, isLast: true)
            },
            action: { [weak self] in
                self?.viewModel.onTap(type: type)
            }
        )
    }

    private func show(type: RestoreTypeModule.RestoreType) {
        let viewController: UIViewController
        var viaPush = true
        switch type {
        case .recoveryOrPrivateKey: viewController = RestoreModule.viewController(sourceViewController: self, returnViewController: returnViewController)
        case .cloudRestore: viewController = RestoreCloudModule.viewController(returnViewController: returnViewController)
        case .fileRestore:
            let documentPicker: UIDocumentPickerViewController
            if #available(iOS 14.0, *) {
                let types = UTType.types(tag: "json", tagClass: UTTagClass.filenameExtension, conformingTo: nil)
                documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: types)
            } else {
                documentPicker = UIDocumentPickerViewController(documentTypes: ["*.json"], in: .import)
            }

            documentPicker.delegate = self
            documentPicker.allowsMultipleSelection = false

            viaPush = false
            viewController = documentPicker
        case .cex: viewController = RestoreCexViewController(returnViewController: returnViewController)
        }

        if viaPush {
            navigationController?.pushViewController(viewController, animated: true)
        } else {
            present(viewController, animated: true)
        }
    }

    private func show(source: BackupModule.NamedSource) {
        let viewController = RestorePassphraseModule.viewController(item: source, returnViewController: returnViewController)
        navigationController?.pushViewController(viewController, animated: true)
    }

    private func showNotCloudAvailable() {
        let viewController = BottomSheetModule.cloudNotAvailableController()
        present(viewController, animated: true)
    }

    private func showWrongFile() {
        HudHelper.instance.show(banner: .error(string: "alert.cant_recognize".localized))
    }
}

extension RestoreTypeViewController: SectionsDataSource {
    func buildSections() -> [SectionProtocol] {
        viewModel.items.enumerated().map { index, item in
            Section(
                id: "restore_type",
                headerState: index == 0 ? .margin(height: .margin12) : .margin(height: 0),
                footerState: index == viewModel.items.count - 1 ? .margin(height: .margin32) : .margin(height: .margin12),
                rows: [row(item)]
            )
        }
    }
}

extension RestoreTypeViewController: UIDocumentPickerDelegate {
    func documentPicker(_: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let jsonUrl = urls.first {
            viewModel.didPick(url: jsonUrl)
        }
    }
}
