import PackageDescription

let package = Package(
    name: "ColorLines",
    dependencies: [
        .Package(url: "../CSDL2", majorVersion: 1)
    ]
)
