import ComponentKit
import RxSwift
import SectionsTableView
import ThemeKit
import UIKit

class WCSignMessageRequestViewController: ThemeViewController {
    private let viewModel: WCSignMessageRequestViewModel

    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)
    private let bottomWrapper = BottomGradientHolder()

    private let signButton = PrimaryButton()
    private let rejectButton = PrimaryButton()

    init(viewModel: WCSignMessageRequestViewModel) {
        self.viewModel = viewModel

        super.init()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "wallet_connect.sign.request_title".localized

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.delaysContentTouches = false

        tableView.sectionDataSource = self

        bottomWrapper.add(to: self, under: tableView)
        bottomWrapper.addSubview(signButton)

        signButton.set(style: .yellow)
        signButton.setTitle("button.sign".localized, for: .normal)
        signButton.addTarget(self, action: #selector(onTapSign), for: .touchUpInside)

        bottomWrapper.addSubview(rejectButton)

        rejectButton.set(style: .gray)
        rejectButton.setTitle("button.reject".localized, for: .normal)
        rejectButton.addTarget(self, action: #selector(onTapReject), for: .touchUpInside)

        tableView.buildSections()

        subscribe(disposeBag, viewModel.errorSignal) { [weak self] in self?.show(error: $0) }
        subscribe(disposeBag, viewModel.dismissSignal) { [weak self] in self?.dismiss() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        tableView.deselectCell(withCoordinator: transitionCoordinator, animated: animated)
    }

    @objc private func onTapSign() {
        viewModel.onSign()
    }

    @objc private func onTapReject() {
        viewModel.onReject()
    }

    private func show(error: Error) {
        HudHelper.instance.show(banner: .error(string: error.localizedDescription))
    }

    private func dismiss() {
        dismiss(animated: true)
    }
}

extension WCSignMessageRequestViewController: SectionsDataSource {
    func buildSections() -> [SectionProtocol] {
        viewModel.sections.enumerated().map { index, section in
            Section(
                id: "section_\(index)",
                headerState: section.header == nil ?
                    .margin(height: index == 0 ? .margin12 : 0) : tableView.sectionHeader(text: section.header!),
                footerState: .margin(height: index == viewModel.sections.count - 1 ? .margin32 : .margin24),
                rows: section.items.enumerated().map { itemIndex, item in
                    switch item {
                    case let .value(title: title, value: value):
                        return tableView.universalRow48(
                            id: "value_\(index)_\(itemIndex)",
                            title: .subhead2(title),
                            value: .subhead1(value),
                            isFirst: itemIndex == 0,
                            isLast: itemIndex == section.items.count - 1
                        )
                    case let .message(text):
                        return tableView.messageRow(text: text)
                    }
                }
            )
        }
    }
}
