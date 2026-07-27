// swift-tools-version:6.3

import PackageDescription

let package = Package(
  name: "HDXLURITemplatePublicAPIConsumer",
  platforms: [
    .macOS(.v26)
  ],
  dependencies: [
    .package(
      name: "HDXLURITemplatePackage",
      path: "../.."
    )
  ],
  targets: [
    .executableTarget(
      name: "HDXLURITemplatePublicAPIConsumer",
      dependencies: [
        .product(
          name: "HDXLURITemplate",
          package: "HDXLURITemplatePackage"
        )
      ]
    )
  ]
)
