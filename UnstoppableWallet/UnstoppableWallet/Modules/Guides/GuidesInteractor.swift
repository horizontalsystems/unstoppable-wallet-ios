import RxSwift

class GuidesInteractor {
    weak var delegate: IGuidesInteractorDelegate?

    private let guidesManager: IGuidesManager

    private let disposeBag = DisposeBag()

    init(guidesManager: IGuidesManager) {
        self.guidesManager = guidesManager
    }

}

extension GuidesInteractor: IGuidesInteractor {

    func fetchGuideCategories() {
        guidesManager.guideCategoriesSingle
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] categories in
                    self?.delegate?.didFetch(guideCategories: categories)
                })
                .disposed(by: disposeBag)
    }

}
