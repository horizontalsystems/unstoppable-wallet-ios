import UIKit
import SnapKit
import RxSwift
import RxCocoa
import ThemeKit
import ComponentKit
import UIExtensions
import SectionsTableView

class TermsViewController: ThemeViewController {
    private let viewModel: TermsViewModel
    private var moduleToOpen: UIViewController?
    private let disposeBag = DisposeBag()

    weak var sourceViewController: UIViewController?

    private let tableView = SectionsTableView(style: .grouped)
    private let agreeButton = PrimaryButton()

    private var viewItems = [TermsViewModel.ViewItem]()
    private var loaded = false

    init(viewModel: TermsViewModel, sourceViewController: UIViewController?, moduleToOpen: UIViewController?) {
        self.viewModel = viewModel
        self.sourceViewController = sourceViewController
        self.moduleToOpen = moduleToOpen

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "terms.title".localized
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onTapClose))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
            if !viewModel.buttonVisible {
                maker.bottom.equalToSuperview()
            }
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.sectionDataSource = self

        if viewModel.buttonVisible {
            let gradientWrapperView = BottomGradientHolder()
            gradientWrapperView.add(to: self, under: tableView)

            gradientWrapperView.addSubview(agreeButton)

            agreeButton.set(style: .yellow)
            agreeButton.setTitle("terms.i_agree".localized, for: .normal)
            agreeButton.addTarget(self, action: #selector(onTapAgree), for: .touchUpInside)
        }

        subscribe(disposeBag, viewModel.viewItemsDriver) { [weak self] viewItems in
            self?.viewItems = viewItems
            self?.reloadTable()
        }
        subscribe(disposeBag, viewModel.buttonEnabledDriver) { [weak self] in self?.agreeButton.isEnabled = $0 }

        tableView.buildSections()
        loaded = true
    }

    @objc func onTapClose() {
        dismiss(animated: true)
    }

    @objc private func onTapAgree() {
        viewModel.onTapAgree()
        dismiss(animated: true) { [weak self] in
            self?.openModuleIfRequired()
        }
    }

    private func openModuleIfRequired() {
        if let module = moduleToOpen {
            sourceViewController?.present(module, animated: true)
        }
    }

    private func reloadTable() {
        if loaded {
            tableView.reload(animated: true)
        }
    }

}

extension TermsViewController: SectionsDataSource {

    private func row(viewItem: TermsViewModel.ViewItem, index: Int, isFirst: Bool, isLast: Bool) -> RowProtocol {
        let backgroundStyle: BaseThemeCell.BackgroundStyle = .lawrence
        let textFont: UIFont = .subhead2
        let text = viewItem.text

        var action: (() -> ())?

        if viewModel.buttonVisible {
            action = { [weak self] in
                self?.viewModel.onToggle(index: index)
            }
        }

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
                action: action
        )
    }

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "terms",
                    headerState: .margin(height: .margin12),
                    footerState: .margin(height: viewModel.buttonVisible ? .margin32 + .heightButton + .margin32 : .margin32),
                    rows: viewItems.enumerated().map { index, viewItem in
                        row(viewItem: viewItem, index: index, isFirst: index == 0, isLast: index == viewItems.count - 1)
                    }
            )
        ]
    }

}
