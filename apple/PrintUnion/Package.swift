// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "PrintUnion",
  platforms: [
    .macOS(.v14),
    .iOS(.v17)
  ],
  products: [
    .library(
      name: "PrintUnionCore",
      targets: ["PrintUnionCore"]
    ),
    .executable(
      name: "PrintUnionApp",
      targets: ["PrintUnionApp"]
    )
  ],
  targets: [
    .target(
      name: "PrintUnionCore"
    ),
    .executableTarget(
      name: "PrintUnionApp",
      dependencies: ["PrintUnionCore"]
    ),
    .testTarget(
      name: "PrintUnionCoreTests",
      dependencies: ["PrintUnionCore"]
    )
  ]
)
