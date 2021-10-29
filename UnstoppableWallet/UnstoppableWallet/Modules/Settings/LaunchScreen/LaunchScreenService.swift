class LaunchScreenService {
    private let launchScreenManager: LaunchScreenManager

    init(launchScreenManager: LaunchScreenManager) {
        self.launchScreenManager = launchScreenManager
    }

}

extension LaunchScreenService {

    var items: [Item] {
        let currentLaunchScreen = launchScreenManager.launchScreen

        return LaunchScreen.allCases.map { launchScreen in
            Item(
                    launchScreen: launchScreen,
                    current: launchScreen == currentLaunchScreen
            )
        }
    }

    func setLaunchScreen(index: Int) {
        launchScreenManager.launchScreen = LaunchScreen.allCases[index]
    }

}

extension LaunchScreenService {

    struct Item {
        let launchScreen: LaunchScreen
        let current: Bool
    }

}
