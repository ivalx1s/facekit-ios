import Foundation
import UIKit
@_implementationOnly import TensorFlowLite

/// This checker verifies face using neural networks
public class NeuralFaceChecker: FaceChecker {
    private static let imageHeight = 256 //max img size 256
    private static let imageWidth = 256 //max img size 256
    private var interpreter: Interpreter?
    private let scoreThreshold: Float
    
    /// Create checker
    /// - Parameter scoreThreshold: neural network trigger threshold
    public init(scoreThreshold: Float = 0.2) throws {
        self.scoreThreshold = scoreThreshold
        self.interpreter = try Self.initializeInterpreter()
    }
    
    public func check(_ image: UIImage) -> FaceCheckResult {
        do {
            if interpreter == nil {
                self.interpreter = try Self.initializeInterpreter()
            }
            guard let interpreter = interpreter else {
                throw InterpreterError.allocateTensorsRequired
            }

            let size = CGSize(width: NeuralFaceChecker.imageWidth, height: NeuralFaceChecker.imageHeight)
            let scaled = image.scale(toRect: size)
            let data = self.convertToData(scaled)
            try interpreter.copy(data, toInputAt: 0)
            try interpreter.invoke()
            let classPredTensor = try interpreter.output(at: 0).data
            let leafNodeMaskTensor = try interpreter.output(at: 1).data
            var score: Float = 0.0
            classPredTensor.withUnsafeBytes { (aPtr: UnsafePointer<Float>) in
                leafNodeMaskTensor.withUnsafeBytes { (bPtr: UnsafePointer<Float>) in
                    for i in 0..<8 {
                        score += abs(aPtr[i]) * bPtr[i]
                    }
                }
            }

            print("neural check score: \(1.0 - score)")
            guard (1.0 - score) > self.scoreThreshold else {
                return .photoLowQuality
            }
            return .success
        } catch {
            return .errorHappened
        }
    }
    
    public func deallocateResources() {
        self.interpreter = nil
    }
    
    private func convertToData(_ image: UIImage) -> Data {
        let imageData = image.convertToBitmapRGBA8()!
        let imageArray = [UInt8](imageData)
        var floats = Array(repeating: Float(0.0), count: NeuralFaceChecker.imageWidth * NeuralFaceChecker.imageHeight * 3)
        let inputStd: Float = 255.0
        var k = 0
        let size = NeuralFaceChecker.imageWidth * NeuralFaceChecker.imageHeight * 4
        for j in 0..<size {
            if (j % 4 == 3) { // skip alpha channel
                continue;
            }
            floats[k] = Float(imageArray[j]) / inputStd;
            k += 1;
        }
        return floats.withUnsafeBufferPointer { ptr in
            Data(buffer: ptr)
        }
    }
    
    private static func initializeInterpreter() throws -> Interpreter {
        let model = Bundle(for: NeuralFaceChecker.self).path(forResource: "FaceAntiSpoofing", ofType: "tflite")!

        let interpreter = try Interpreter(
            modelPath: model,
            options: nil,
            delegates: .processingDelegates
        )
        
        try interpreter.allocateTensors()
        
        print("Init neural checker interpreter")

        return interpreter
    }
}
