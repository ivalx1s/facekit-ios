import Foundation
import UIKit

/// This fhecker verifies face with laplacian blur detection
public class LaplacianFaceChecker: FaceChecker {
    private static let imageHeight = 256
    private static let imageWidth = 256
    private let laplaceThreshold: Int
    
    /// Create checker
    /// - Parameter laplaceThreshold: minimum required threshold
    public init(laplaceThreshold: Int = 50) {
        self.laplaceThreshold = laplaceThreshold
    }
    
    public func check(_ image: UIImage) -> FaceCheckResult {
        let size = CGSize(
            width: LaplacianFaceChecker.imageWidth,
            height: LaplacianFaceChecker.imageHeight
        )
        let scaled = image.scale(toRect: size)
        guard self.laplacian(scaled) >= self.laplaceThreshold else {
            return .photoLowQuality
        }
        return .success
    }
    
    private func laplacian(_ scaled: UIImage) -> Int {
        let data = scaled.convertToBitmapGray()!
        let dat = [UInt8](data)
        let laplace = [[0, 1, 0], [1, -4, 1], [0, 1, 0]]
        var score = 0
        for x in 0..<LaplacianFaceChecker.imageHeight - 2 {
            for y in 0..<LaplacianFaceChecker.imageWidth - 2 {
                var result = 0
                for i in 0..<3 {
                    for j in 0..<3 {
                        result += (Int(dat[(x+i)*LaplacianFaceChecker.imageWidth+y+j]) & 0xFF) * laplace[i][j]
                    }
                }
                if (result > self.laplaceThreshold) {
                    score += 1
                }
            }
        }
        return score
    }
    
    public func deallocateResources() {
        
    }
}
