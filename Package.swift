// swift-tools-version: 6.2

import PackageDescription

// ISO/IEC 14496-22: Open Font Format (OFF)
// Specifies the structure of TrueType and OpenType font files
let package = Package(
    name: "swift-iso-14496-22",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26)
    ],
    products: [
        .library(name: "ISO 14496-22", targets: ["ISO 14496-22"])
    ],
    dependencies: [
        .package(url: "https://github.com/swift-primitives/swift-standard-library-extensions.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-binary-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-byte-primitives.git", branch: "main")
    ],
    targets: [
        .target(
            name: "ISO 14496-22",
            dependencies: [
                .product(name: "Standard Library Extensions", package: "swift-standard-library-extensions"),
                .product(name: "Binary Primitives", package: "swift-binary-primitives"),
                .product(name: "Byte Primitives", package: "swift-byte-primitives"),
                .product(name: "Byte Primitives Standard Library Integration", package: "swift-byte-primitives")
            ]
        ),
        .testTarget(
            name: "ISO 14496-22 Tests",
            dependencies: [
                "ISO 14496-22",
                .product(name: "Byte Primitives", package: "swift-byte-primitives"),
                .product(name: "Byte Primitives Standard Library Integration", package: "swift-byte-primitives")
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

extension String {
    var tests: Self { self + " Tests" }
}

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
