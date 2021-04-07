import RxSwift
import RxRelay
import ThemeKit

class ThemeSettingsService {
    private let themeManager: ThemeManager
    private let itemsRelay = PublishRelay<[Item]>()
    private(set) var items = [Item]() {
        didSet {
            itemsRelay.accept(items)
        }
    }

    init(themeManager: ThemeManager) {
        self.themeManager = themeManager

        syncItems()
    }

    private func syncItems() {
        var items = [Item]()

        for themeMode in [ThemeMode.dark, ThemeMode.light, ThemeMode.system] {
            items.append(Item(themeMode: themeMode, selected: themeManager.themeMode == themeMode))
        }

        self.items = items
    }

}

extension ThemeSettingsService {

    var itemsObservable: Observable<[Item]> {
        itemsRelay.asObservable()
    }

    func set(themeMode: ThemeMode) {
        themeManager.themeMode = themeMode

        syncItems()
    }

}

extension ThemeSettingsService {

    struct Item {
        let themeMode: ThemeMode
        let selected: Bool
    }

}
