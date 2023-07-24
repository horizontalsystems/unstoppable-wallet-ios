import Combine
import SnapKit
import ThemeKit
import UIKit
import ComponentKit
import SectionsTableView
import UIExtensions

class ICloudBackupNameViewController: KeyboardAwareViewController {
    private let viewModel: ICloudBackupNameViewModel
    private var cancellables = Set<AnyCancellable>()

    private let tableView = SectionsTableView(style: .grouped)

    private let nameCell = InputCell(singleLine: true)
    private let nameCautionCell = FormCautionCell()

    private let bottomView = BottomGradientHolder()
    private let nextButton = PrimaryButton()

    private var keyboardShown = false
    private var isLoaded = false

    var onNext: ((String) -> ())?

    init(viewModel: ICloudBackupNameViewModel) {
        self.viewModel = viewModel

        super.init(scrollViews: [tableView], accessoryView: bottomView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "backup.cloud.name.title".localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.next".localized, style: .done, target: self, action: #selector(onTapNext))
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.largeTitleDisplayMode = .never

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.sectionDataSource = self

        bottomView.add(to: self)
        bottomView.addSubview(nextButton)

        nextButton.set(style: .yellow)
        nextButton.setTitle("button.next".localized, for: .normal)
        nextButton.addTarget(self, action: #selector(onTapNext), for: .touchUpInside)

        nameCell.inputPlaceholder = "backup.cloud.name.placeholder".localized
        nameCell.autocapitalizationType = .words
        nameCell.onChangeText = { [weak self] in self?.viewModel.onChange(name: $0) }
        nameCell.inputText = viewModel.initialName

        nameCautionCell.onChangeHeight = { [weak self] in self?.onChangeHeight() }


        viewModel.$nameError
                .receive(on: DispatchQueue.main)
                .sink { [weak self] nameError in
                    guard let nameError else {
                        self?.nameCell.set(cautionType: nil)
                        self?.nameCautionCell.set(caution: nil)
                        return
                    }

                    self?.nameCell.set(cautionType: .error)
                    self?.nameCautionCell.set(caution: Caution(text: nameError, type: .error))
                }
                .store(in: &cancellables)

       viewModel.$nextAvailable
                .receive(on: DispatchQueue.main)
                .sink { [weak self] available in
                    self?.navigationItem.rightBarButtonItem?.isEnabled = available
                    self?.nextButton.isEnabled = available
                }
                .store(in: &cancellables)


        tableView.buildSections()
        isLoaded = true
    }

    override func viewDidAppear(_ animated: Bool) {
        if !keyboardShown {
            keyboardShown = true
            _ = nameCell.becomeFirstResponder()
        }

        super.viewDidAppear(animated)
    }

    @objc private func onTapCancel() {
        dismiss(animated: true)
    }

    @objc private func onTapNext() {
        guard let name = viewModel.name else {
            return
        }

        let controller = BackupCloudModule.backupPassword(account: viewModel.account, name: name)
        navigationController?.pushViewController(controller, animated: true)
    }

}

extension ICloudBackupNameViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "description-section",
                    headerState: .margin(height: .margin12),
                    footerState: .margin(height: .margin32),
                    rows: [
                        tableView.descriptionRow(
                                id: "description",
                                text: "backup.cloud.name.description".localized,
                                font: .subhead2,
                                textColor: .gray,
                                ignoreBottomMargin: true
                        )
                    ]
            ),
            Section(
                    id: "name",
                    footerState: .margin(height: .margin32),
                    rows: [
                        StaticRow(
                                cell: nameCell,
                                id: "name",
                                height: .heightSingleLineCell
                        ),
                        StaticRow(
                                cell: nameCautionCell,
                                id: "name-caution",
                                dynamicHeight: { [weak self] width in
                                    self?.nameCautionCell.height(containerWidth: width) ?? 0
                                }
                        )
                    ]
            )
        ]
    }

}

extension ICloudBackupNameViewController: IDynamicHeightCellDelegate {

    func onChangeHeight() {
        guard isLoaded else {
            return
        }

        UIView.animate(withDuration: 0.2) { [weak self] in
            self?.tableView.beginUpdates()
            self?.tableView.endUpdates()
        }
    }

}
