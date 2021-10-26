import RxSwift

class TwitterUsernameService {
    private var usernameSubject = PublishSubject<String>()

    var usernameObservable: Observable<String> {
        usernameSubject.asObservable()
    }

    func set(username: String) {
        usernameSubject.onNext(username)
    }

}
