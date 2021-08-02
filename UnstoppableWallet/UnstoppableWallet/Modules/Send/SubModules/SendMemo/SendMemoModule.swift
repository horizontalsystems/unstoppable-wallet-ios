protocol ISendMemoView: AnyObject {
    var memo: String? { get }
    func set(hidden: Bool)
}

protocol ISendMemoViewDelegate {
    func validate(memo: String) -> Bool
}

protocol ISendMemoModule: AnyObject {
    var delegate: ISendMemoDelegate? { get set }

    var memo: String? { get }
    func set(hidden: Bool)
}

protocol ISendMemoDelegate: AnyObject {
}
