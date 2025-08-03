// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "CharBox",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "CharBox",
            targets: ["CharBox"]
        )
    ],
    dependencies: [
        // 可以在这里添加外部依赖
    ],
    targets: [
        .executableTarget(
            name: "CharBox",
            dependencies: [],
            path: ".",
            sources: [
                "CharboxApp.swift",
                "ContentView.swift",
                "Models.swift",
                "ChatManager.swift",
                "SettingsManager.swift",
                "SidebarView.swift",
                "ChatView.swift",
                "SettingsView.swift"
            ]
        )
    ]
)
