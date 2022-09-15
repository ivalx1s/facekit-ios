import Foundation
import UIKit
import TensorFlowLite

/// Compare faces using neural network
public class NeuralFaceComparator: FaceComparator {
    private static let imageWidth = 112
    private static let imageHeight = 112
    private static let embeddingsSize = 192
    private let similarityThreshold: Double
    private var interpreter: Interpreter?
    
    public init(similarityThreshold: Double) throws {
        self.similarityThreshold = similarityThreshold
        self.interpreter = try Self.initializeInterpreter()
    }
    
    public func compare(_ image1: UIImage, with image2: UIImage) -> FaceComparisonResult {
        do {
            if interpreter == nil {
                self.interpreter = try Self.initializeInterpreter()
            }
            guard let interpreter = interpreter else {
                throw InterpreterError.allocateTensorsRequired
            }

            let size = CGSize(width: NeuralFaceComparator.imageWidth, height: NeuralFaceComparator.imageHeight)
            let scaled1 = image1.scale(toRect: size)
            let scaled2 = image2.scale(toRect: size)
            let data = self.convertToData(imageA: scaled1, imageB: scaled2)
            try interpreter.copy(data, toInputAt: 0)
            try interpreter.invoke()
            let output = try interpreter.output(at: 0).data
            var outputData = Array(repeating: Float(0), count: NeuralFaceComparator.embeddingsSize * 2)
            output.withUnsafeBytes { (ptr: UnsafePointer<Float>) in
                for i in 0..<NeuralFaceComparator.embeddingsSize * 2 {
                    outputData[i] = ptr[i]
                }
            }
            self.l2normalize(embeddings: &outputData, epsilon: 1e-10)
            let evalResult = self.evaluate(embeddings: outputData)

            print("similarity: \(evalResult)")

            guard evalResult > similarityThreshold else {
                return .differentPersona
            }
            return .samePersona
        } catch {
            return .errorHappened
        }
    }
    
    public func deallocateResources() {
        self.interpreter = nil
    }
    
    private func convertToData(imageA: UIImage, imageB: UIImage) -> Data {
        let imageDataA = imageA.convertToBitmapRGBA8()!
        let imageArrayA = [UInt8](imageDataA)
        let imageDataB = imageB.convertToBitmapRGBA8()!
        let imageArrayB = [UInt8](imageDataB)
        var floats = Array(
            repeating: Float(0.0),
            count:
                2 // images count
                * NeuralFaceComparator.imageWidth // width
                * NeuralFaceComparator.imageHeight // height
                * 3 // actual channels count
        )
        
        let inputStd: Float = 128.0
        let inputMean: Float = 127.5
        var k = 0
        let size = NeuralFaceComparator.imageWidth * NeuralFaceComparator.imageHeight * 4
        for j in 0..<size {
            if (j % 4 == 3) { // skip alpha channel
                continue;
            }
            floats[k] = (Float(imageArrayA[j]) - inputMean) / inputStd;
            k += 1;
        }
        for j in 0..<size {
            if (j % 4 == 3) { // skip alpha channel
                continue;
            }
            floats[k] = (Float(imageArrayB[j]) - inputMean) / inputStd;
            k += 1;
        }
        return floats.withUnsafeBufferPointer { ptr in
            Data(buffer: ptr)
        }
    }

    private func l2normalize(embeddings: inout [Float], epsilon: Float) {
        for i in 0..<2 {
            var squareSum: Float = 0.0
            for j in 0..<NeuralFaceComparator.embeddingsSize {
                squareSum += pow(embeddings[i * NeuralFaceComparator.embeddingsSize + j], 2);
            }
            let xInvNorm = sqrt(max(squareSum, epsilon));
            for j in 0..<NeuralFaceComparator.embeddingsSize {
                embeddings[i * NeuralFaceComparator.embeddingsSize + j] = embeddings[i * NeuralFaceComparator.embeddingsSize + j] / xInvNorm
            }
        }
    }
    
    private func evaluate(embeddings: [Float]) -> Double {
        var dist: Double = 0.0
        for i in 0..<NeuralFaceComparator.embeddingsSize {
            dist += pow(Double(embeddings[i] - embeddings[i + NeuralFaceComparator.embeddingsSize]), 2.0)
        }
        var same: Double = 0.0
        for i in 0..<400 {
            let t: Double = 0.01 * (Double(i) + 1.0)
            if (dist < t) {
                same += 1.0 / 400
            }
        }
        return same
    }
    
    private static func initializeInterpreter() throws -> Interpreter {
        let model = Bundle.module.path(forResource: "MobileFaceNet", ofType: "tflite")!
        
        let interpreter = try Interpreter(
            modelPath: model,
            options: nil,
            delegates: .processingDelegates
        )
        try interpreter.allocateTensors()
        
        print("Init comporator interpreter")

        return interpreter
    }
}
