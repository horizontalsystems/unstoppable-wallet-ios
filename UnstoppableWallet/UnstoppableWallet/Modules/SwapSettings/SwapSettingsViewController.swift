import UIKit
import ThemeKit
import UniswapKit
import HUD
import RxSwift
import RxCocoa
import SectionsTableView
import ComponentKit
import UIExtensions

class SwapSettingsViewController: KeyboardAwareViewController {
    private let wrapperViewHeight: CGFloat = .heightButton + .margin16 + .margin16
    private let animationDuration: TimeInterval = 0.2
    private let disposeBag = DisposeBag()

    private let dataSourceManager: ISwapDataSourceManager
    private let tableView = SectionsTableView(style: .grouped)

    private var dataSource: ISwapSettingsDataSource?

    private let gradientWrapperView = GradientView(gradientHeight: .margin16, fromColor: UIColor.themeTyler.withAlphaComponent(0), toColor: UIColor.themeTyler)
    private let applyButton = PrimaryButton()

    private var isLoaded: Bool = false
    override var accessoryViewHeight: CGFloat {
        super.accessoryViewHeight
    }

    init(dataSourceManager: ISwapDataSourceManager) {
        self.dataSourceManager = dataSourceManager

        super.init(scrollViews: [tableView], accessoryView: gradientWrapperView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "swap.advanced_settings".localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(didTapCancel))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
//        tableView.allowsSelection = false
        tableView.sectionDataSource = self

        view.addSubview(gradientWrapperView)
        gradientWrapperView.snp.makeConstraints { maker in
            maker.height.equalTo(wrapperViewHeight).priority(.high)
            maker.leading.trailing.bottom.equalToSuperview()
        }

        gradientWrapperView.addSubview(applyButton)
        applyButton.snp.makeConstraints { maker in
            maker.top.equalToSuperview().inset(CGFloat.margin16)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide)
        }
        applyButton.set(style: .yellow)
        applyButton.setTitle("button.apply".localized, for: .normal)
        applyButton.addTarget(self, action: #selector(onTapDoneButton), for: .touchUpInside)

        subscribe(disposeBag, dataSourceManager.dataSourceUpdated) { [weak self] _ in self?.updateDataSource() }
        updateDataSource()

        setInitialState(bottomPadding: wrapperViewHeight)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        isLoaded = true
    }

    @objc private func didTapCancel() {
        dismiss(animated: true)
    }

    @objc private func onTapDoneButton() {
        dataSource?.didTapApply()
    }

    private func updateDataSource() {
        dataSource = dataSourceManager.settingsDataSource

        dataSource?.onReload = { [weak self] in self?.reloadTable() }
        dataSource?.onClose = { [weak self] in self?.didTapCancel() }
        dataSource?.onOpen = { [weak self] viewController in self?.present(viewController, animated: true) }
        dataSource?.onChangeButtonState = { [weak self] in self?.syncButton(enabled: $0, title: $1) }

        dataSource?.viewDidLoad()

        if isLoaded {
            tableView.reload()
        } else {
            tableView.buildSections()
        }
    }

    private func syncButton(enabled: Bool, title: String) {
        applyButton.isEnabled = enabled
        applyButton.setTitle(title, for: .normal)
    }

    private func reloadTable() {
        UIView.animate(withDuration: animationDuration) {
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        }
    }

}

extension SwapSettingsViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        if let dataSource = dataSource {
            sections.append(contentsOf: dataSource.buildSections(tableView: tableView))
        }

        return sections
    }

}
