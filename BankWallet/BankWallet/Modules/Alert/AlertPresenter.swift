class AlertPresenter {
    weak var view: IAlertView?

    private let viewItems: [AlertViewItem]
    private let onSelect: (Int) -> ()

    private let router: IAlertRouter

    init(viewItems: [AlertViewItem], onSelect: @escaping (Int) -> (), router: IAlertRouter) {
        self.viewItems = viewItems
        self.onSelect = onSelect
        self.router = router
    }

}

extension AlertPresenter: IAlertViewDelegate {

    func onLoad() {
        view?.set(viewItems: viewItems)
    }

    func onTapViewItem(index: Int) {
        onSelect(index)
        router.close()
    }

}
