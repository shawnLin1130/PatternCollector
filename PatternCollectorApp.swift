import SwiftUI
import SwiftData

@main
struct PatternCollectorApp: App {
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0 // 0: 系统, 1: 浅色, 2: 深色
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(appearanceMode == 0 ? nil : (appearanceMode == 1 ? .light : .dark))
        }
        .modelContainer(for: PatternItem.self)
    }
}

@Model
class PatternItem {
    var id: UUID
    var name: String
    @Attribute(.externalStorage) var imageData: Data?
    var category: String
    @Attribute(.searchable) var tags: [String]
    var notes: String
    var createdAt: Date
    var isFavorite: Bool
    var dominantColor: String // hex颜色码，如 "#FF5733"
    
    init(
        name: String = "",
        category: String = "默认",
        tags: [String] = [],
        notes: String = "",
        imageData: Data? = nil,
        isFavorite: Bool = false,
        dominantColor: String = "#000000"
    ) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.tags = tags
        self.notes = notes
        self.imageData = imageData
        self.createdAt = Date()
        self.isFavorite = isFavorite
        self.dominantColor = dominantColor
    }
}
