import Foundation
import UIKit

/// Used to check faces for deception
public protocol FaceChecker {
    /// Check face for deception
    ///
    /// - Parameter image: face to check
    /// - Returns: true if image is passed checks
    func check(_ image: UIImage) -> FaceCheckResult
    
    func deallocateResources()
}
