import AVFoundation
import SwiftUI

public struct QrCameraPreviewNew: UIViewRepresentable {
    private let session: AVCaptureSession

    public init(session: AVCaptureSession) {
        self.session = session
    }

    public func makeUIView(context _: Context) -> QrCameraPreviewUIView {
        QrCameraPreviewUIView(session: session)
    }

    public func updateUIView(_: QrCameraPreviewUIView, context _: Context) {}
}

public class QrCameraPreviewUIView: UIView {
    private let previewLayer: AVCaptureVideoPreviewLayer

    public init(session: AVCaptureSession) {
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        super.init(frame: .zero)

        previewLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(previewLayer)
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
    }
}
