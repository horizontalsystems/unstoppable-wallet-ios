import AVFoundation
import SwiftUI

struct QrCameraPreviewNew: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context _: Context) -> QrCameraPreviewUIView {
        QrCameraPreviewUIView(session: session)
    }

    func updateUIView(_: QrCameraPreviewUIView, context _: Context) {}
}

class QrCameraPreviewUIView: UIView {
    private let previewLayer: AVCaptureVideoPreviewLayer

    init(session: AVCaptureSession) {
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        super.init(frame: .zero)

        previewLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(previewLayer)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
    }
}
