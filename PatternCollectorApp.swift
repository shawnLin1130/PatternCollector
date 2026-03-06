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
        .modelContainer(for: [PatternItem.self, JournalBook.self, JournalPage.self, PageElement.self])
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

// MARK: - 手帐本模型

// 手帐本
@Model
class JournalBook {
    var id: UUID
    var name: String              // 手帐本名字
    var coverImageData: Data?     // 封面图片
    var coverColor: String        // 封面颜色（hex）
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \JournalPage.book) var pages: [JournalPage]
    
    init(name: String = "新手帐本", coverImageData: Data? = nil, coverColor: String = "#FFB6C1") {
        self.id = UUID()
        self.name = name
        self.coverImageData = coverImageData
        self.coverColor = coverColor
        self.createdAt = Date()
        self.pages = []
    }
}

// 页面
@Model
class JournalPage {
    var id: UUID
    var pageNumber: Int           // 页码
    var backgroundColor: String   // 背景色（hex）
    var backgroundImageData: Data? // 背景图（可选纸张纹理）
    var book: JournalBook?
    @Relationship(deleteRule: .cascade, inverse: \PageElement.page) var elements: [PageElement]
    
    init(pageNumber: Int = 1, backgroundColor: String = "#FFF8E7", backgroundImageData: Data? = nil) {
        self.id = UUID()
        self.pageNumber = pageNumber
        self.backgroundColor = backgroundColor
        self.backgroundImageData = backgroundImageData
        self.elements = []
    }
}

// 页面元素（贴在页面上的图案）
@Model
class PageElement {
    var id: UUID
    var patternId: UUID?          // 关联的PatternItem ID
    var patternImageData: Data?   // 直接存储图案图片（避免关联问题）
    var x: Double                 // X坐标
    var y: Double                 // Y坐标
    var width: Double             // 宽度
    var height: Double            // 高度
    var rotation: Double          // 旋转角度
    var zIndex: Int              // 图层顺序
    var page: JournalPage?
    
    init(patternId: UUID? = nil, patternImageData: Data? = nil, x: Double = 0, y: Double = 0, width: Double = 100, height: Double = 100, rotation: Double = 0, zIndex: Int = 0) {
        self.id = UUID()
        self.patternId = patternId
        self.patternImageData = patternImageData
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.rotation = rotation
        self.zIndex = zIndex
    }
}
