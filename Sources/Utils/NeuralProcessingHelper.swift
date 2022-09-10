import Foundation
@_implementationOnly import TensorFlowLite

extension Array where Element == Delegate {
    static var processingDelegates: [Delegate] {
        var result: [Delegate] = []
        
        // NewuralDelegate consumes RAM aroud 750mb and doesn't dealocate it after execution
        // problem investigation: https://github.com/tensorflow/tensorflow/issues/47640
        // workaround: we deallocate it every time with deallocating Interpreter
        // but it still twice as slow in comparison to GPU processing
        // the energy efficiency looks the same as GPU - Low
        
//        var coreMLdelegateOptions = CoreMLDelegate.Options()
//        coreMLdelegateOptions.enabledDevices = .neuralEngine
//
//        if let coreMLDelegate = CoreMLDelegate(options: coreMLdelegateOptions) {
//            result.append(coreMLDelegate)
//        }

        let metalDelegateOptions = MetalDelegate.Options()
        let metalDelegate = MetalDelegate(options: metalDelegateOptions)
        result.append(metalDelegate)
        
        return result
    }
}
