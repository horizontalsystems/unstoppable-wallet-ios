class SendMemoPresenter {
    weak var view: ISendMemoView?
    weak var delegate: ISendMemoDelegate?

    private let maxSymbols: Int

    init(maxSymbols: Int) {
        self.maxSymbols = maxSymbols
    }

}

extension SendMemoPresenter: ISendMemoViewDelegate {

    func validate(memo: String) -> Bool {
        return memo.count <= maxSymbols
    }

}

extension SendMemoPresenter: ISendMemoModule {

    var memo: String? {
        guard let memo = view?.memo, !memo.isEmpty else {
            return nil
        }

        return memo
    }

}
