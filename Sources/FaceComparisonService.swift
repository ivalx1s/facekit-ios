import Foundation
import UIKit

public enum FaceExtractResult: Equatable {
    case errorHappened
    case faceNotDetected
    case moreThanOneFace
    case success(UIImage, CIFaceFeature)
}

public enum FaceCheckResult: Equatable {
    case errorHappened
    case photoLowQuality
    case faceNotDetected
    case moreThanOneFace
    case success
}

public enum FaceComparisonResult: Equatable {
    case originalFaceCheckFailed(FaceCheckResult)
    case candidateFaceCheckFailed(FaceCheckResult)
    case errorHappened
    case differentPersona
    case samePersona
}

public protocol IFaceComparisonService {
    func compare(candidate: UIImage, with original: UIImage) -> FaceComparisonResult
    func check(candidate: UIImage) -> FaceCheckResult
    func deallocateResources()
}

/// Face comparison facade
public class FaceComparisonService: IFaceComparisonService {
    private let faceExtractor: FaceExtractor
    private let faceCheckers: [FaceChecker]
    private let faceComparator: FaceComparator

    public init(
        extractor: FaceExtractor,
        checkers: [FaceChecker],
        comparator: FaceComparator
    ) {
        self.faceExtractor = extractor
        self.faceCheckers = checkers
        self.faceComparator = comparator
    }
    
    public convenience init?(
            laplaceThreshold: Int = 50,
            neuralCheckThreshold: Float = 0.2,
            similarityThreshold: Double = 0.75
    ) {
        let faceExtractor = CIFaceExtractor()
        let neuralFaceChecker = try? NeuralFaceChecker(scoreThreshold: neuralCheckThreshold)
        let laplaceChecker = LaplacianFaceChecker(laplaceThreshold: laplaceThreshold)
        let neuralFaceComparator = try? NeuralFaceComparator(similarityThreshold: similarityThreshold)
        
        guard
            let faceChecker = neuralFaceChecker,
            let faceComparator = neuralFaceComparator else {
            return nil
        }
        
        self.init(
            extractor: faceExtractor,
            checkers: [
                laplaceChecker,
                faceChecker
            ],
            comparator: faceComparator
        )
    }
    
    /// Compare faces
    ///
    /// - Parameter candidate: candidate face image
    /// - Parameter original: original face image
    /// - Returns: similarity from 0 to 1.
    ///    If any of given images do not contain face or failed in deception check - returns nil.
    public func compare(candidate: UIImage, with original: UIImage) -> FaceComparisonResult {

        
        let originalFaceExtractionResult = self.faceExtractor.extract(original)
        guard case let .success(original, features) = originalFaceExtractionResult else {
            switch originalFaceExtractionResult {
            case .moreThanOneFace:
                return .originalFaceCheckFailed(.moreThanOneFace)
            case .faceNotDetected:
                return .originalFaceCheckFailed(.faceNotDetected)
            case .errorHappened:
                return .originalFaceCheckFailed(.errorHappened)
            default: break
            }
            return .originalFaceCheckFailed(.errorHappened)
        }
        
        let candidateFaceExtractionResult = self.faceExtractor.extract(candidate)
        guard case let .success(candidate, features) = candidateFaceExtractionResult else {
            switch candidateFaceExtractionResult {
            case .moreThanOneFace:
                return .candidateFaceCheckFailed(.moreThanOneFace)
            case .faceNotDetected:
                return .candidateFaceCheckFailed(.faceNotDetected)
            case .errorHappened:
                return .candidateFaceCheckFailed(.errorHappened)
            default: break
            }
            return .candidateFaceCheckFailed(.errorHappened)
        }

        let checkResult = self.check(candidate)
        guard case .success = checkResult else {
            return .candidateFaceCheckFailed(checkResult)
        }

        return self.faceComparator.compare(original, with: candidate)
    }

    public func check(candidate: UIImage) -> FaceCheckResult {
        switch self.faceExtractor.extract(candidate) {
        case let .success(img, _):
            return check(img)
        case .faceNotDetected:
            return .faceNotDetected
        case .moreThanOneFace:
            return .moreThanOneFace
        case .errorHappened:
            return .errorHappened
        }
    }

    private func check(_ target: UIImage) -> FaceCheckResult {
        for checker in self.faceCheckers {
            let result = checker.check(target)
            switch result {
            case .success:
                continue
            default:
                print("failed check for \(type(of: checker))")
                return result
            }
        }
        return .success
    }
    
    public func deallocateResources() {
        faceCheckers
            .forEach { $0.deallocateResources() }
        
        faceComparator
            .deallocateResources()
    }
}
