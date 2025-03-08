// swift-tools-version:6.0

import PackageDescription

let package = Package(
  name: "HDXLURITemplate",
  platforms: [
    .iOS(.v18),
    .macOS(.v15),
    .tvOS(.v18),
    .watchOS(.v9)
  ],
  products: [
    // Products define the executables and libraries produced by a package, and make them visible to other packages.
    .library(
      name: "HDXLURITemplate",
      targets: ["HDXLURITemplate"]
    )
  ],
  dependencies: [ ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages which this package depends on.
    .target(
      name: "HDXLURITemplate",
      dependencies: []
    ),
    .testTarget(
      name: "HDXLURITemplateTests",
      dependencies: [
        "HDXLURITemplate", 
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
        )
      ]
    )
  ],
  swiftLanguageModes: [
    .v6
  ]
)

