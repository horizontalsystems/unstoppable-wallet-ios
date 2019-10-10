protocol IAppStatusInteractor {
    var status: [(String, Any)] { get }

    func copyToClipboard(string: String)
}
