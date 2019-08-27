import RxSwift

class SendInteractor {
    weak var delegate: ISendInteractorDelegate?

    private let disposeBag = DisposeBag()
}

extension SendInteractor: ISendInteractor {

    func send(single: Single<Void>) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.delegate?.didSend()
        }

//        single.subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
//                .observeOn(MainScheduler.instance)
//                .subscribe(onSuccess: { [weak self] in
//                    self?.delegate?.didSend()
//                }, onError: { [weak self] error in
//                    self?.delegate?.didFailToSend(error: error)
//                })
//                .disposed(by: disposeBag)
    }

}
