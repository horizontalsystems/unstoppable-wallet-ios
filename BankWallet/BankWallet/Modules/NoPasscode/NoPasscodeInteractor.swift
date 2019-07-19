class NoPasscodeInteractor {
    weak var delegate: INoPasscodeInteractorDelegate?

    init() {
    }

}

extension NoPasscodeInteractor: INoPasscodeInteractor {
}
