import RxSwift

class AddErc20TokenInteractor {
    weak var delegate: IAddErc20TokenInteractorDelegate?

    private let disposeBag = DisposeBag()

    init() {
    }

}

extension AddErc20TokenInteractor: IAddErc20TokenInteractor {
}
