public protocol ICustomNodeHandler: AnyObject {
    func presentAddNode()
    func removeNode(id: String) throws
}
