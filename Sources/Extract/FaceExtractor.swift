import Foundation
import UIKit

/// Used to extract face from image
public protocol FaceExtractor {
    /// Extract face from image
    ///
    /// - Parameter image: from where extract a face
    /// - Returns: first found and extracted face or nil if no faces found
    func extract(_ image: UIImage) -> FaceExtractResult
}
