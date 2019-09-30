class ThemeManager {
    private let localStorage: ILocalStorage

    private(set) var currentTheme: ITheme

    init(localStorage: ILocalStorage) {
        self.localStorage = localStorage

        currentTheme = localStorage.lightMode ? LightTheme() : DarkTheme()
    }

}

extension ThemeManager: IThemeManager {

    var lightMode: Bool {
        get {
            localStorage.lightMode
        }
        set {
            localStorage.lightMode = newValue
            currentTheme = newValue ? LightTheme() : DarkTheme()
            AppTheme.updateNavigationBarTheme()
        }
    }

}
