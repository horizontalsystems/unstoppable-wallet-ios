import RxSwift

class GuidesInteractor {
    weak var delegate: IGuidesInteractorDelegate?

    private let appConfigProvider: IAppConfigProvider
    private let guidesManager: IGuidesManager

    private let disposeBag = DisposeBag()

    init(appConfigProvider: IAppConfigProvider, guidesManager: IGuidesManager) {
        self.appConfigProvider = appConfigProvider
        self.guidesManager = guidesManager
    }

}

extension GuidesInteractor: IGuidesInteractor {

    var guidesIndexUrl: URL {
        appConfigProvider.guidesIndexUrl
    }

    func fetchGuideCategories(url: URL) {
        guidesManager.guideCategoriesSingle(url: url)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] categories in
                    self?.delegate?.didFetch(guideCategories: categories)
                })
                .disposed(by: disposeBag)
    }

}
