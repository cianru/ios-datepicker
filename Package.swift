// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DatePicker",
    platforms: [
        .iOS(.v14),
    ],
    products: [
        .library(name: "DatePicker", targets: ["DatePicker"]),
    ],
    targets: [
        .target(name: "DatePicker"),
    ]
)
