import Combine
import UIKit
import Chart
import ComponentKit
import HUD
import SectionsTableView
import ThemeKit
import UIExtensions
import UniswapKit

class ChartIndicatorSettingsViewController: KeyboardAwareViewController {
    private let animationDuration: TimeInterval = 0.2

    private var cancellables = Set<AnyCancellable>()

    private let viewModel: ChartIndicatorSettingsViewModel
    private let tableView = SectionsTableView(style: .grouped)

    private let gradientWrapperView = BottomGradientHolder()
    private let applyButton = PrimaryButton()

    private var isLoaded: Bool = false
    override var accessoryViewHeight: CGFloat {
        super.accessoryViewHeight
    }

    private var items = [ChartIndicatorSettingsModule.ValueItem]()
    private var inputSections = [InputIntegerSection]()

    private var onComplete: ((ChartIndicator) -> ())?

    init(viewModel: ChartIndicatorSettingsViewModel, onComplete: @escaping (ChartIndicator) -> ()) {
        self.viewModel = viewModel
        self.onComplete = onComplete

        super.init(scrollViews: [tableView], accessoryView: gradientWrapperView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = viewModel.title
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.reset".localized, style: .plain, target: self, action: #selector(didTapReset))
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.sectionDataSource = self

        gradientWrapperView.add(to: self)

        gradientWrapperView.addSubview(applyButton)
        applyButton.set(style: .yellow)
        applyButton.setTitle("button.apply".localized, for: .normal)
        applyButton.addTarget(self, action: #selector(onTapDoneButton), for: .touchUpInside)

        viewModel.itemsUpdatedPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] items in
                    self?.items = items
                    self?.tableView.reload(animated: true)
                }
                .store(in: &cancellables)

        viewModel.buttonEnabledPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] enabled in
                    self?.applyButton.isEnabled = enabled
                }
                .store(in: &cancellables)

        viewModel.resetToInitialPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] items in
                    self?.resetToInitial(items: items)
                }
                .store(in: &cancellables)

        viewModel.resetEnabledPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] enabled in
                    self?.navigationItem.rightBarButtonItem?.isEnabled = enabled
                }
                .store(in: &cancellables)

        viewModel.cautionPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] cautions in
                    self?.sync(cautions: cautions)
                }
                .store(in: &cancellables)

        viewModel.updateIndicatorPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] indicator in
                    self?.onApply(indicator: indicator)
                }
                .store(in: &cancellables)

        viewModel.showSubscribeInfoPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in
                    self?.showSubscribeInfo()
                }
                .store(in: &cancellables)

        tableView.buildSections()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        isLoaded = true
    }

    @objc private func didTapReset() {
        viewModel.reset()

        tableView.reload()
    }

    @objc private func onTapDoneButton() {
        viewModel.didTapApply()
    }

    private func onApply(indicator: ChartIndicator) {
        onComplete?(indicator)
        navigationController?.popViewController(animated: true)
    }

    private func showSubscribeInfo() {
        let viewController = SubscriptionInfoViewController()
        present(ThemeNavigationController(rootViewController: viewController), animated: true)
    }

    private func sync(cautions: [IndicatorDataSource.Caution]) {
        inputSections.forEach { section in
            if let caution = cautions.first(where: { $0.id == section.id }) {
                section.set(caution: Caution(text: caution.error, type: .error))
            } else {
                section.set(caution: nil)
            }
        }
    }

    private func resetToInitial(items: [ChartIndicatorSettingsModule.ValueItem]) {
        inputSections.forEach { section in
            if let item = items.first(where: { $0.id == section.id }) {
                section.text = (item.value as? CustomStringConvertible)?.description
                section.set(caution: nil)
            }
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

extension ChartIndicatorSettingsViewController {

    private func sectionDescription(id: String, description: String, rowInfo: RowInfo) ->  SectionProtocol {
        Section(
                id: rowInfo.description,
                headerState: rowInfo.isFirst ? .margin(height: .margin12) : .margin(height: 0),
                footerState: .margin(height: .margin24),
                rows: [
                    tableView.descriptionRow(id: id, text: description, font: .subhead2, textColor: .gray, ignoreBottomMargin: true)
                ]
        )
    }

    private func sectionList(id: String, hash: String, header: String?, title: String, elements: [ChartIndicatorSettingsModule.ListElement], selected: ChartIndicatorSettingsModule.ListElement) -> SectionProtocol {
        Section(
                id: id,
                headerState: header.map { tableView.sectionHeader(text: $0) } ?? .margin(height: 0),
                footerState: .margin(height: .margin24),
                rows: [
                    tableView.universalRow48(
                            id: id,
                            title: .body(title),
                            value: .subhead2(selected.title),
                            accessoryType: .dropdown,
                            hash: hash,
                            autoDeselect: true,
                            isFirst: true,
                            isLast: true
                    ) { [weak self] in
                        self?.onSelectList(id: id, title: title, elements: elements, selected: selected)
                    }
                ]
        )
    }

    private func onSelectList(id: String, title: String, elements: [ChartIndicatorSettingsModule.ListElement], selected: ChartIndicatorSettingsModule.ListElement) {
        let alertController = AlertRouter.module(
                title: title,
                viewItems: elements.map { element in
                    AlertViewItem(text: element.title, selected: element.id == selected.id)
                }
        ) { [weak self] index in
            self?.viewModel.onSelectList(id: id, selected: elements[index])
        }

        present(alertController, animated: true)
    }

    private func onChangeText(id: String, value: String?) {
        viewModel.onChangeText(id: id, value: value)
    }

}

extension ChartIndicatorSettingsViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        viewModel.fields.enumerated().forEach { index, field in
            let rowInfo = RowInfo(index: index, count: viewModel.fields.count)
            switch field {
            case let field as ChartIndicatorSettingsModule.TextField:
                sections.append(sectionDescription(id: field.id, description: field.text, rowInfo: rowInfo))
            case let field as ChartIndicatorSettingsModule.ListField:
                var selected = field.initial
                if let item = items.first(where: { $0.id == field.id }),
                   let value = item.value as? ChartIndicatorSettingsModule.ListElement {
                    selected = value
                }
                sections.append(
                        sectionList(
                                id: field.id,
                                hash: [field.id, selected.title].joined(separator: "_"),
                                header: field.header,
                                title: field.title,
                                elements: field.elements,
                                selected: selected
                        )
                )
            case let field as ChartIndicatorSettingsModule.InputIntegerField: ()
                var section: InputIntegerSection
                if let index = inputSections.firstIndex(where: { $0.id == field.id }) {
                    section = inputSections[index]
                } else {
                    section = InputIntegerSection(id: field.id, placeholder: field.placeholder, initialValue: field.initial)
                    section.onChangeText = { [weak self] text in
                        self?.onChangeText(id: field.id, value: text)
                    }
                    section.onReload = { [weak self] in self?.reloadTable() }
                    inputSections.append(section)
                }
                sections.append(section
                        .section(tableView: tableView, header: field.header)
                )
            default: ()
            }
        }

        return sections
    }

}
