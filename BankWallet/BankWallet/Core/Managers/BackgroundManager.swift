import RxSwift

class BackgroundManager {
    let resignActiveSubject = PublishSubject<()>()
    let didBecomeActiveSubject = PublishSubject<()>()
    let didEnterBackgroundSubject = PublishSubject<()>()
}
