// swift-tools-version:6.3

import PackageDescription

let package = Package(
  name: "HDXLURITemplate",
  platforms: [
    .iOS(.v26),
    .macOS(.v26),
    .tvOS(.v26),
    .watchOS(.v26),
    .visionOS(.v26),
    .macCatalyst(.v26),
  ],
  products: [
    // Products define the executables and libraries produced by a package, and make them visible to other packages.
    .library(
      name: "HDXLURITemplate",
      targets: ["HDXLURITemplate"]
    )
  ],
  dependencies: [],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages which this package depends on.
    .target(
      name: "HDXLURITemplate",
      dependencies: []
    ),
    .target(
      name: "HDXLURITemplateAPI03BenchmarkSupport",
      dependencies: [
        "HDXLURITemplate"
      ],
      path: "Benchmarks/API03/Support"
    ),
    .executableTarget(
      name: "HDXLURITemplateAPI03Benchmark",
      dependencies: [
        "HDXLURITemplateAPI03BenchmarkSupport"
      ],
      path: "Benchmarks/API03/Runner"
    ),
    .executableTarget(
      name: "HDXLURITemplateARCH01Benchmark",
      dependencies: [
        "HDXLURITemplate"
      ],
      path: "Benchmarks/ARCH01"
    ),
    .executableTarget(
      name: "HDXLURITemplateARCH02Benchmark",
      dependencies: [
        "HDXLURITemplate"
      ],
      path: "Benchmarks/ARCH02"
    ),
    .target(
      name: "HDXLURITemplateQA03Support",
      dependencies: [
        "HDXLURITemplate"
      ],
      path: "Hardening/QA03/Support"
    ),
    .executableTarget(
      name: "HDXLURITemplateQA03",
      dependencies: [
        "HDXLURITemplateQA03Support"
      ],
      path: "Hardening/QA03/Runner"
    ),
    .testTarget(
      name: "HDXLURITemplateTests",
      dependencies: [
        "HDXLURITemplate",
        "HDXLURITemplateAPI03BenchmarkSupport",
        "HDXLURITemplateQA03Support",
      ],
      exclude: [
        "Resources/README.md"
      ],
      resources: [
        Resource.copy(
          "Resources/extended-tests.json"
        ),
        Resource.copy(
          "Resources/negative-tests.json"
        ),
        Resource.copy(
          "Resources/spec-examples.json"
        ),
        Resource.copy(
          "Resources/spec-examples-by-section.json"
        ),
      ]
    ),
    .testTarget(
      name: "HDXLURITemplatePublicAPITests",
      dependencies: [
        "HDXLURITemplate"
      ]
    ),
  ],
  swiftLanguageModes: [
    .v6
  ]
)
