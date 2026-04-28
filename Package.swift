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
        // Faza 26B: MLXLLM real inference via shareup/mlx-swift-lm
        // (fork care expune MLXLLM/MLXLMCommon/MLXVLM ca SPM products separate —
        // Apple oficial nu le publica).
        .package(url: "https://github.com/shareup/mlx-swift-lm", from: "0.0.14"),
        // MLXHuggingFace macros expand la cod care folosește HubClient și AutoTokenizer
        .package(url: "https://github.com/huggingface/swift-huggingface.git", from: "0.9.0"),
        .package(url: "https://github.com/huggingface/swift-transformers", exact: "0.1.20")
    ],
    targets: [
        .target(name: "SolomonCore"),
        .target(name: "SolomonStorage", dependencies: ["SolomonCore"]),
        .target(name: "SolomonAnalytics", dependencies: ["SolomonCore", "SolomonStorage"]),
        .target(
            name: "SolomonLLM",
            dependencies: [
                "SolomonCore",
                .product(name: "MLXLLM", package: "mlx-swift-lm"),
                .product(name: "MLXLMCommon", package: "mlx-swift-lm"),
                .product(name: "MLXHuggingFace", package: "mlx-swift-lm"),
                .product(name: "HuggingFace", package: "swift-huggingface"),
                .product(name: "Transformers", package: "swift-transformers")
            ],
            swiftSettings: [
                // Macro-urile mlx-swift-lm 0.0.14 produc cod cu Sendable issues sub
                // Swift 6 strict concurrency. Folosim modul minimal (warning-uri doar).
                .swiftLanguageMode(.v5)
            ]
        ),
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
