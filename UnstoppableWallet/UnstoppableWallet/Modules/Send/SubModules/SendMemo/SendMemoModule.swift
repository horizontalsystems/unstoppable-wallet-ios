protocol ISendMemoView: AnyObject {
    var memo: String? { get }
}

protocol ISendMemoViewDelegate {
    func validate(memo: String) -> Bool
}

protocol ISendMemoModule: AnyObject {
    var delegate: ISendMemoDelegate? { get set }

    var memo: String? { get }
}

protocol ISendMemoDelegate: AnyObject {
}
