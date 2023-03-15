class AlertPresenter {
    weak var view: IAlertView?

    private let viewItems: [AlertViewItem]
    private let onSelect: (Int) -> ()

    let afterClose: Bool

    private let router: IAlertRouter

    init(viewItems: [AlertViewItem], onSelect: @escaping (Int) -> (), router: IAlertRouter, afterClose: Bool) {
        self.viewItems = viewItems
        self.onSelect = onSelect
        self.router = router
        self.afterClose = afterClose
    }

}

extension AlertPresenter: IAlertViewDelegate {

    func onLoad() {
        view?.set(viewItems: viewItems)
    }

    func onTapViewItem(index: Int) {

        if afterClose {
            router.close { [weak self] in
                self?.onSelect(index)
            }
        } else {
            onSelect(index)
            router.close(completion: nil)
        }
    }

}
