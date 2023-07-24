import Foundation
import UIKit
import ThemeKit
import SnapKit
import SectionsTableView
import RxSwift
import RxCocoa
import ComponentKit
import UIExtensions

class AddEvmSyncSourceViewController: KeyboardAwareViewController {
    private let viewModel: AddEvmSyncSourceViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)

    private let urlCell = AddressInputCell()
    private let urlCautionCell = FormCautionCell()

    private let basicAuthCell = AddressInputCell()

    private let gradientWrapperView = BottomGradientHolder()
    private let addButton = PrimaryButton()

    init(viewModel: AddEvmSyncSourceViewModel) {
        self.viewModel = viewModel

        super.init(scrollViews: [tableView], accessoryView: gradientWrapperView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "add_evm_sync_source.title".localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onTapCancel))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.sectionDataSource = self

        gradientWrapperView.add(to: self)
        gradientWrapperView.addSubview(addButton)

        addButton.set(style: .yellow)
        addButton.setTitle("button.add".localized, for: .normal)
        addButton.addTarget(self, action: #selector(onTapAdd), for: .touchUpInside)

        urlCell.onChangeHeight = { [weak self] in self?.reloadHeights() }
        urlCell.onChangeText = { [weak self] in self?.viewModel.onChange(url: $0) }
        urlCell.onFetchText = { [weak self] in
            self?.viewModel.onChange(url: $0)
            self?.urlCell.inputText = $0
        }
        urlCell.onOpenViewController = { [weak self] in self?.present($0, animated: true) }

        urlCautionCell.onChangeHeight = { [weak self] in self?.reloadHeights() }

        basicAuthCell.onChangeHeight = { [weak self] in self?.reloadHeights() }
        basicAuthCell.onChangeText = { [weak self] in self?.viewModel.onChange(basicAuth: $0) }
        basicAuthCell.onFetchText = { [weak self] in
            self?.viewModel.onChange(basicAuth: $0)
            self?.basicAuthCell.inputText = $0
        }
        basicAuthCell.onOpenViewController = { [weak self] in self?.present($0, animated: true) }

        subscribe(disposeBag, viewModel.urlCautionDriver) { [weak self] caution in
            self?.urlCell.set(cautionType: caution?.type)
            self?.urlCautionCell.set(caution: caution)
        }
        subscribe(disposeBag, viewModel.finishSignal) { [weak self] in
            self?.dismiss(animated: true)
        }

        tableView.buildSections()
    }

    @objc private func onTapAdd() {
        viewModel.onTapAdd()
    }

    @objc private func onTapCancel() {
        dismiss(animated: true)
    }

    private func reloadHeights() {
        UIView.animate(withDuration: 0.2) {
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        }
    }

}

extension AddEvmSyncSourceViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "margin",
                    headerState: .margin(height: .margin12)
            ),
            Section(
                    id: "url",
                    headerState: tableView.sectionHeader(text: "add_evm_sync_source.rpc_url".localized),
                    footerState: .margin(height: .margin24),
                    rows: [
                        StaticRow(
                                cell: urlCell,
                                id: "url",
                                dynamicHeight: { [weak self] width in
                                    self?.urlCell.height(containerWidth: width) ?? 0
                                }
                        ),
                        StaticRow(
                                cell: urlCautionCell,
                                id: "url-caution",
                                dynamicHeight: { [weak self] width in
                                    self?.urlCautionCell.height(containerWidth: width) ?? 0
                                }
                        )
                    ]
            ),
            Section(
                    id: "basic-auth",
                    headerState: tableView.sectionHeader(text: "add_evm_sync_source.basic_auth".localized),
                    footerState: .margin(height: .margin32),
                    rows: [
                        StaticRow(
                                cell: basicAuthCell,
                                id: "basic-auth",
                                dynamicHeight: { [weak self] width in
                                    self?.basicAuthCell.height(containerWidth: width) ?? 0
                                }
                        )
                    ]
            )
        ]
    }

}
