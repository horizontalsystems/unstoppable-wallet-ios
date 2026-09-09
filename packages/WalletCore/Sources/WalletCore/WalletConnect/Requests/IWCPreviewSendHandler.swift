// A WC send handler that can produce the request rows synchronously, with the fee still pending, so the
// request sheet opens full (rows visible) like Android instead of blocking the whole screen on a loader
// while the gas estimate is fetched. The rows come from the dApp transaction already in the payload.
protocol IWCPreviewSendHandler {
    func previewSendData() -> ISendData?
}
