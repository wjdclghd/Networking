// swift-tools-version: 5.9

//
//  Package.swift
//  Networking
//
//  Created by jch on 3/21/26.
//

import PackageDescription

let package = Package(
    name: "Networking",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "Networking",
            targets: ["Networking"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.9.1")
    ],
    targets: [
        .target(
            name: "Networking",
            dependencies: [
                .product(name: "Alamofire", package: "Alamofire")
            ],
            path: "Sources/Networking"
        ),
        .testTarget(
            name: "NetworkingTests",
            dependencies: [
                "Networking",
                .product(name: "Alamofire", package: "Alamofire")
            ],
            path: "Tests/NetworkingTests"
        )
    ]
)
