import UIKit
import SectionsTableViewKit

class SettingsLanguageController: UIViewController, SectionsDataSource {
    var availableLanguages = App.shared.localizationManager.availableLanguages

    let tableView = SectionsTableView(style: .grouped)

    init() {
        super.init(nibName: nil, bundle: nil)
        tableView.registerCell(forClass: LanguageCell.self)
        tableView.sectionDataSource = self
        tableView.separatorColor = SettingsTheme.cellSelectBackground

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundColor = .clear
        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        title = "settings_language.title".localized

        view.backgroundColor = AppTheme.controllerBackground

        tableView.reload()
    }

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        sections.append(Section(id: "languages", headerState: .margin(height: SettingsTheme.subSettingsHeaderHeight), footerState: .margin(height: SettingsTheme.subSettingsHeaderHeight), rows: availableLanguages.map { language in
            Row<LanguageCell>(id: language, height: SettingsTheme.languageCellHeight, bind: { cell, _ in
                cell.bind(title: App.shared.localizationManager.displayName(forLanguage: language, inLanguage: App.shared.languageManager.currentLanguage), subtitle: App.shared.localizationManager.displayName(forLanguage: language, inLanguage: language), selected: App.shared.languageManager.currentLanguage == language)
            }, action: { [weak self] _ in
                self?.applyLanguage(language: language)
            })
        }))

        return sections
    }

    func applyLanguage(language: String) {
        var languageManager = App.shared.languageManager
        languageManager.currentLanguage = language

        if let window = UIApplication.shared.keyWindow {
            UIView.transition(with: window, duration: 0.5, options: .transitionCrossDissolve, animations: {
                window.rootViewController = MainRouter.module()
            })
        }
    }
}
