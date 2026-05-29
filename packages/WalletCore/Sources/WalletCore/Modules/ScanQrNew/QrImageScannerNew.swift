import CoreImage
import UIKit

enum QrImageScannerNew {
    static func scan(image: UIImage) -> String? {
        guard let ciImage = CIImage(image: image) else { return nil }

        let detector = CIDetector(
            ofType: CIDetectorTypeQRCode,
            context: nil,
            options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        )

        let features = detector?.features(in: ciImage) ?? []

        return features
            .compactMap { ($0 as? CIQRCodeFeature)?.messageString }
            .first
    }
}
