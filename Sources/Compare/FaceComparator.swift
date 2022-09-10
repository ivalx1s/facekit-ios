import Foundation
import UIKit

/// Used to compare faces
public protocol FaceComparator {
    /// Compare faces
    ///
    /// - Parameter image1: first face
    /// - Parameter image2: second face
    /// - Returns: FaceComparisonResult
    func compare(_ image1: UIImage, with image2: UIImage) -> FaceComparisonResult

    func deallocateResources()
}
