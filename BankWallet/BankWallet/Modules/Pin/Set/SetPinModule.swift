protocol ISetPinRouter {
    func notifyCancelled()
    func close()
}

protocol ISetPinDelegate {
    func didCancelSetPin()
}
