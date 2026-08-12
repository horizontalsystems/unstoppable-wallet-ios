public protocol ISendHandlerRefCapturing {
    /// Broadcasts exactly as `ISendHandler.send(data:)` does, but returns the broadcast reference
    /// (tx hash, userOp hash, transfer id — whatever the mechanism yields) so a decorating handler
    /// can attach it to its own record without knowing the mechanism.
    func sendCapturingRef(data: ISendData) async throws -> String
}
