import UIKit

class GuideRouter {
    weak var viewController: UIViewController?
}

extension GuideRouter: IGuideRouter {

    func showFontSize(selected: Int, onSelect: @escaping (Int) -> ()) {
        let fontSizes = [10, 14, 17, 22, 28]

        let alertController = AlertRouter.module(
                title: "Font Size",
                viewItems: fontSizes.map { fontSize in
                    AlertViewItem(text: "\(fontSize)", selected: fontSize == selected)
                }
        ) { index in
            onSelect(fontSizes[index])
        }

        viewController?.present(alertController, animated: true)
    }

}

extension GuideRouter {

    static func module(guide: Guide) -> UIViewController {
        let router = GuideRouter()
        let interactor = GuideInteractor()
        let presenter = GuidePresenter(guide: guide, parser: GuideParser(), router: router, interactor: interactor)
        let view = GuideViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = view
        router.viewController = view

        return view
    }

}
