import RxSwift
import RxRelay
import RxCocoa

class LaunchScreenViewModel {
    private let service: LaunchScreenService

    private let finishRelay = PublishRelay<Void>()

    init(service: LaunchScreenService) {
        self.service = service

    }

    private func viewItem(item: LaunchScreenService.Item) -> ViewItem {
        ViewItem(
                iconName: iconName(launchScreen: item.launchScreen),
                title: item.launchScreen.title,
                selected: item.current
        )
    }

    private func iconName(launchScreen: LaunchScreen) -> String {
        switch launchScreen {
        case .auto: return "settings_20"
        case .balance: return "wallet_20"
        case .marketOverview: return "chart_type_20"
        case .watchlist: return "star_20"
        }
    }

}

extension LaunchScreenViewModel {

    var finishSignal: Signal<Void> {
        finishRelay.asSignal()
    }

    var viewItems: [ViewItem] {
        service.items.map { viewItem(item: $0) }
    }

    func onSelect(index: Int) {
        service.setLaunchScreen(index: index)
        finishRelay.accept(())
    }

}

extension LaunchScreenViewModel {

    struct ViewItem {
        let iconName: String
        let title: String
        let selected: Bool
    }

}
