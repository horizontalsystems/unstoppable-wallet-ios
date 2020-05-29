import UIKit

class GuidesInteractor {
    weak var delegate: IGuidesInteractorDelegate?

    private let guidesManager: IGuidesManager

    init(guidesManager: IGuidesManager) {
        self.guidesManager = guidesManager
    }

}

extension GuidesInteractor: IGuidesInteractor {

    var guides: [Guide] {
        guidesManager.guides
    }

}
