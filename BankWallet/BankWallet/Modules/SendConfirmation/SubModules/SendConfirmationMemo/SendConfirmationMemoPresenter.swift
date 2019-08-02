class SendConfirmationMemoPresenter {
    weak var view: ISendConfirmationMemoView?

    private let maximumSymbols: Int

    init(maximumSymbols: Int) {
        self.maximumSymbols = maximumSymbols
    }

}

extension SendConfirmationMemoPresenter: ISendConfirmationMemoViewDelegate {

    func validateInputText(text: String) -> Bool {
        return text.count <= maximumSymbols
    }

}

extension SendConfirmationMemoPresenter: ISendConfirmationMemoModule {

    var memo: String? {
        return view?.memo
    }

}