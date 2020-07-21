import Foundation
import RxSwift

class GuideInteractor {
    weak var delegate: IGuideInteractorDelegate?

    private let guidesManager: IGuidesManager

    private let disposeBag = DisposeBag()

    init(guidesManager: IGuidesManager) {
        self.guidesManager = guidesManager
    }

}

extension GuideInteractor: IGuideInteractor {

    func fetchGuideContent(url: URL) {
        guidesManager.guideContentSingle(url: url)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] content in
                    self?.delegate?.didFetch(guideContent: content)
                })
                .disposed(by: disposeBag)

    }

}
