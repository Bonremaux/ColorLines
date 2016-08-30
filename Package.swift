import PackageDescription

let package = Package(
    name: "Lines",
    dependencies: [
        .Package(url: "../CSDL2", majorVersion: 1)
    ]
)
