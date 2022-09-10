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
            path: "Sources"
        ),
    ]
)


// MARK: -- Dependencies
extension Package {
    static var remoteDeps: [Package.Dependency] {
        [
            .package(url: "git@github.com:ivalx1s/swift-tensorflowlite-spm.git", from: "2.7.0"),
        ]
    }
    
    static var facekitDeps: [Target.Dependency] {
        [
            .product(name: "TensorFlowLite", package: "swift-tensorflowlite-spm"),
        ]
    }
}
