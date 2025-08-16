import Foundation
import RxCocoa
import RxSwift
import SectionsTableView
import SnapKit

import UIExtensions
import UIKit

class AddMoneroNodeViewController: KeyboardAwareViewController {
    private let viewModel: AddMoneroNodeViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)

    private let urlCell = AddressInputCell()
    private let urlCautionCell = FormCautionCell()

    private let loginCell = AddressInputCell()
    private let passwordCell = AddressInputCell()

    private let gradientWrapperView = BottomGradientHolder()
    private let addButton = PrimaryButton()

    init(viewModel: AddMoneroNodeViewModel) {
        self.viewModel = viewModel

        super.init(scrollViews: [tableView], accessoryView: gradientWrapperView)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "add_monero_node.title".localized
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

        loginCell.onChangeHeight = { [weak self] in self?.reloadHeights() }
        loginCell.onChangeText = { [weak self] in self?.viewModel.onChange(login: $0) }
        loginCell.onFetchText = { [weak self] in
            self?.viewModel.onChange(login: $0)
            self?.loginCell.inputText = $0
        }
        loginCell.onOpenViewController = { [weak self] in self?.present($0, animated: true) }

        passwordCell.onChangeHeight = { [weak self] in self?.reloadHeights() }
        passwordCell.onChangeText = { [weak self] in self?.viewModel.onChange(password: $0) }
        passwordCell.onFetchText = { [weak self] in
            self?.viewModel.onChange(password: $0)
            self?.passwordCell.inputText = $0
        }
        passwordCell.onOpenViewController = { [weak self] in self?.present($0, animated: true) }

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

extension AddMoneroNodeViewController: SectionsDataSource {
    func buildSections() -> [SectionProtocol] {
        [
            Section(
                id: "margin",
                headerState: .margin(height: .margin12)
            ),
            Section(
                id: "url",
                headerState: tableView.sectionHeader(text: "add_monero_node.node_url".localized),
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
                    ),
                ]
            ),
            Section(
                id: "login",
                headerState: tableView.sectionHeader(text: "add_monero_node.login".localized),
                footerState: .margin(height: .margin32),
                rows: [
                    StaticRow(
                        cell: loginCell,
                        id: "login",
                        dynamicHeight: { [weak self] width in
                            self?.loginCell.height(containerWidth: width) ?? 0
                        }
                    ),
                ]
            ),
            Section(
                id: "password",
                headerState: tableView.sectionHeader(text: "add_monero_node.password".localized),
                footerState: .margin(height: .margin32),
                rows: [
                    StaticRow(
                        cell: passwordCell,
                        id: "password",
                        dynamicHeight: { [weak self] width in
                            self?.passwordCell.height(containerWidth: width) ?? 0
                        }
                    ),
                ]
            ),
        ]
    }
}
