import RxSwift
import RxRelay

class WhatsNewService {
    private let appVersionManager: IAppVersionManager

    init(appVersionManager: IAppVersionManager) {
        self.appVersionManager = appVersionManager
    }

    var whatsNewObservable: Observable<AppVersion?> {
        appVersionManager.newVersionObservable
    }

}
