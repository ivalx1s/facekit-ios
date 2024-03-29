// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "facekit-ios",
    platforms: [
        .iOS(.v14),
    ],
    products: [
        .library(
            name: "FaceKit",
            type: .dynamic,
            targets: ["FaceKit"]
        ),
    ],
    dependencies: Package.remoteDeps,
    targets: [
        .target(
            name: "FaceKit",
            dependencies: Package.facekitDeps,
            path: "Sources",
            resources: [
                .copy("Resources/MLModels/FaceAntiSpoofing.tflite"),
                .copy("Resources/MLModels/MobileFaceNet.tflite"),
            ]
        ),
    ]
)


// MARK: -- Dependencies
extension Package {
    static var remoteDeps: [Package.Dependency] {
        [
            .package(url: "git@github.com:darwell-inc/swift-tensorflowlite.git", from: "2.7.0"),
        ]
    }
    
    static var facekitDeps: [Target.Dependency] {
        [
            .product(name: "TensorFlowLite", package: "swift-tensorflowlite"),
        ]
    }
}
