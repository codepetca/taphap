// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "TapHapCore",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "TapHapCore", targets: ["TapHapLab"]),
        .library(name: "Phase1Core", targets: ["Phase1Core"])
    ],
    targets: [
        .target(name: "Phase1Core", path: "Phase1Lab/Core"),
        .testTarget(name: "Phase1CoreTests", dependencies: ["Phase1Core"], path: "Phase1LabTests", resources: [.copy("Fixtures"), .copy("AssessmentFixtures")]),
        .target(
            name: "TapHapLab",
            path: "TapHapLab/Core"
        ),
        .testTarget(
            name: "TapHapLabTests",
            dependencies: ["TapHapLab"],
            path: "TapHapLabTests"
        )
    ]
)
