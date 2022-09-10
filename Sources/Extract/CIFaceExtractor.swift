import Foundation
import CoreImage
import UIKit

/// This class extracts faces using CoreImage CIDetector
public class CIFaceExtractor: FaceExtractor {
    public init() {
        
    }
    
    public func extract(_ image: UIImage) -> FaceExtractResult {
        let context = CIContext()
        let detector = CIDetector(
            ofType: CIDetectorTypeFace,
            context: context,
            options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        )!
        let features = detector
                .features(in: CIImage(cgImage: image.cgImage!))
                .compactMap { $0 as? CIFaceFeature }

        guard !features.isEmpty else {
            return .faceNotDetected
        }
        guard
                features.count == 1,
                let feature = features.first
                else {
            return .moreThanOneFace
        }
        var bounds = feature.bounds
        bounds.origin.y = image.size.height - bounds.height - bounds.origin.y

        guard let extractionResult = image.crop(toRect: bounds) else {
            return .errorHappened
        }

        return .success(extractionResult, feature)
    }
}
