// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Solomon",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(name: "SolomonCore", targets: ["SolomonCore"]),
        .library(name: "SolomonStorage", targets: ["SolomonStorage"]),
        .library(name: "SolomonAnalytics", targets: ["SolomonAnalytics"]),
        .library(name: "SolomonLLM", targets: ["SolomonLLM"]),
        .library(name: "SolomonEmail", targets: ["SolomonEmail"]),
        .library(name: "SolomonWeb", targets: ["SolomonWeb"]),
        .library(name: "SolomonMoments", targets: ["SolomonMoments"])
    ],
    dependencies: [
        // Faza 26: scaffold MLX integration. Real LLM inference va fi adăugat
        // odată cu vendoring-ul MLXLLM source code din mlx-swift-examples
        // (Apple nu publică MLXLLM ca SPM library standalone).
    ],
    targets: [
        .target(name: "SolomonCore"),
        .target(name: "SolomonStorage", dependencies: ["SolomonCore"]),
        .target(name: "SolomonAnalytics", dependencies: ["SolomonCore", "SolomonStorage"]),
        .target(name: "SolomonLLM", dependencies: ["SolomonCore"]),
        .target(name: "SolomonEmail", dependencies: ["SolomonCore", "SolomonStorage"]),
        .target(name: "SolomonWeb", dependencies: ["SolomonCore"]),
        .target(
            name: "SolomonMoments",
            dependencies: ["SolomonCore", "SolomonAnalytics", "SolomonLLM", "SolomonStorage"]
        ),
        .testTarget(name: "SolomonCoreTests", dependencies: ["SolomonCore"]),
        .testTarget(name: "SolomonStorageTests", dependencies: ["SolomonStorage"]),
        .testTarget(name: "SolomonAnalyticsTests", dependencies: ["SolomonAnalytics"]),
        .testTarget(name: "SolomonLLMTests", dependencies: ["SolomonLLM"]),
        .testTarget(name: "SolomonEmailTests", dependencies: ["SolomonEmail"]),
        .testTarget(name: "SolomonWebTests", dependencies: ["SolomonWeb"]),
        .testTarget(name: "SolomonMomentsTests", dependencies: ["SolomonMoments"])
    ]
)
