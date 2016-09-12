import PackageDescription

let package = Package(
    name: "ColorLines",
    dependencies: [
        .Package(url: "https://github.com/Bonremaux/CSDL2.git", majorVersion: 1)
    ]
)
