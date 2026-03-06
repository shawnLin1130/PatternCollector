import SwiftUI
import SwiftData

// MARK: - 装饰贴纸模型
@Model
class StickerDecor {
    var id: UUID
    var emoji: String              // 贴纸emoji或图片名
    var x: Double                  // X坐标
    var y: Double                  // Y坐标
    var scale: Double              // 缩放比例
    var rotation: Double           // 旋转角度
    var zIndex: Int               // 图层顺序
    var page: JournalPage?
    
    init(emoji: String = "⭐", x: Double = 150, y: Double = 250, scale: Double = 1.0, rotation: Double = 0, zIndex: Int = 0) {
        self.id = UUID()
        self.emoji = emoji
        self.x = x
        self.y = y
        self.scale = scale
        self.rotation = rotation
        self.zIndex = zIndex
    }
}

// 内置装饰贴纸
enum BuiltInDecorSticker: String, CaseIterable {
    case star = "⭐"
    case ribbon = "🎀"
    case heart = "❤️"
    case cloud = "☁️"
    case flower = "🌸"
    case lace = "🕸️"
    case sparkle = "✨"
    case rainbow = "🌈"
    case butterfly = "🦋"
    case crown = "👑"
    case bow = "🎀"
    case candy = "🍬"
    case cake = "🎂"
    case icecream = "🍦"
    case strawberry = "🍓"
    
    var emoji: String { rawValue }
}

// MARK: - 手绘涂鸦模型
@Model
class DrawingPath {
    var id: UUID
    var pointsData: Data?          // 序列化后的点数组
    var colorHex: String           // 颜色（hex）
    var lineWidth: Double          // 线条粗细
    var zIndex: Int               // 图层顺序
    var page: JournalPage?
    
    init(colorHex: String = "#000000", lineWidth: Double = 3.0, zIndex: Int = 0) {
        self.id = UUID()
        self.colorHex = colorHex
        self.lineWidth = lineWidth
        self.zIndex = zIndex
    }
}

// 涂鸦点
struct DrawingPoint: Codable {
    var x: Double
    var y: Double
}

// 画笔选项
enum DrawingBrush: String, CaseIterable {
    case fine = "细"
    case medium = "中"
    case thick = "粗"
    
    var lineWidth: Double {
        switch self {
        case .fine: return 2.0
        case .medium: return 5.0
        case .thick: return 10.0
        }
    }
    
    var icon: String {
        switch self {
        case .fine: return "line.diagonal"
        case .medium: return "line.diagonal"
        case .thick: return "line.diagonal"
        }
    }
}

// 预设颜色
let drawingColors: [String] = [
    "#000000", "#FF0000", "#FF69B4", "#FFB6C1", "#FFD700",
    "#90EE90", "#87CEEB", "#9370DB", "#FFA500", "#8B4513"
]

// MARK: - 日期印章模型
@Model
class DateStamp {
    var id: UUID
    var dateString: String         // 显示的日期字符串
    var formatType: String         // 格式类型
    var x: Double                  // X坐标
    var y: Double                  // Y坐标
    var fontSize: Double           // 字体大小
    var rotation: Double           // 旋转角度
    var zIndex: Int               // 图层顺序
    var page: JournalPage?
    
    init(dateString: String = "", formatType: String = "YYYY/MM/DD", x: Double = 150, y: Double = 250, fontSize: Double = 16, rotation: Double = 0, zIndex: Int = 0) {
        self.id = UUID()
        self.dateString = dateString.isEmpty ? Self.formatDate(type: formatType) : dateString
        self.formatType = formatType
        self.x = x
        self.y = y
        self.fontSize = fontSize
        self.rotation = rotation
        self.zIndex = zIndex
    }
    
    static func formatDate(type: String) -> String {
        let formatter = DateFormatter()
        let now = Date()
        
        switch type {
        case "YYYY/MM/DD":
            formatter.dateFormat = "yyyy/MM/dd"
            return formatter.string(from: now)
        case "DD/MM":
            formatter.dateFormat = "dd/MM"
            return formatter.string(from: now)
        case "MM/DD":
            formatter.dateFormat = "MM/dd"
            return formatter.string(from: now)
        case "今天是好日子":
            return "今天是好日子 ☀️"
        case "美好的一天":
            return "美好的一天 ✨"
        case "记得开心":
            return "记得开心 💕"
        default:
            formatter.dateFormat = "yyyy/MM/dd"
            return formatter.string(from: now)
        }
    }
}

// 日期格式选项
enum DateStampFormat: String, CaseIterable {
    case ymd = "YYYY/MM/DD"
    case dm = "DD/MM"
    case md = "MM/DD"
    case goodDay = "今天是好日子"
    case wonderfulDay = "美好的一天"
    case rememberHappy = "记得开心"
    
    var displayName: String { rawValue }
}

// MARK: - 成就模型
@Model
class Achievement {
    var id: UUID
    var name: String               // 成就名称
    var description: String        // 成就描述
    var icon: String               // 图标emoji
    var conditionType: String      // 条件类型
    var conditionValue: Int        // 条件数值
    var isUnlocked: Bool           // 是否解锁
    var unlockedAt: Date?          // 解锁时间
    var user: UserProfile?
    
    init(name: String, description: String, icon: String, conditionType: String, conditionValue: Int) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.icon = icon
        self.conditionType = conditionType
        self.conditionValue = conditionValue
        self.isUnlocked = false
    }
}

// 成就条件类型
enum AchievementCondition: String, CaseIterable {
    case patternsCount = "收集数量"
    case favoritesCount = "收藏数量"
    case journalsCount = "手帐本数量"
    case pagesCount = "手帐页数"
    case consecutiveDays = "连续天数"
    case tagsCount = "标签数量"
}

// 预设成就
let presetAchievements: [(name: String, desc: String, icon: String, condition: String, value: Int)] = [
    ("初学者", "收集第1个图案", "🌱", "收集数量", 1),
    ("小有收集", "收集10个图案", "🌿", "收集数量", 10),
    ("收藏达人", "收集50个图案", "🌳", "收集数量", 50),
    ("图案大师", "收集100个图案", "🏆", "收集数量", 100),
    ("初尝收藏", "收藏第1个图案", "💝", "收藏数量", 1),
    ("收藏家", "收藏10个图案", "💖", "收藏数量", 10),
    ("手帐新手", "创建第1本手帐", "📒", "手帐本数量", 1),
    ("手帐达人", "创建5本手帐", "📓", "手帐本数量", 5),
    ("书写者", "累计10页手帐", "✏️", "手帐页数", 10),
    ("日记达人", "累计50页手帐", "📝", "手帐页数", 50),
    ("每日记录", "连续记录3天", "📅", "连续天数", 3),
    ("坚持不懈", "连续记录7天", "💪", "连续天数", 7),
    ("坚持就是胜利", "连续记录30天", "🌟", "连续天数", 30),
    ("标签达人", "累计10个标签", "🏷️", "标签数量", 10)
]

// MARK: - 用户档案（成就关联）
@Model
class UserProfile {
    var id: UUID
    var createdAt: Date
    var lastActiveDate: Date
    var consecutiveDays: Int
    var totalPatternsCount: Int
    var achievements: [Achievement]
    
    init() {
        self.id = UUID()
        self.createdAt = Date()
        self.lastActiveDate = Date()
        self.consecutiveDays = 0
        self.totalPatternsCount = 0
        self.achievements = []
    }
}

// MARK: - 心情贴纸模型
@Model
class MoodSticker {
    var id: UUID
    var mood: String               // 心情类型
    var emoji: String              // 对应emoji
    var x: Double                  // X坐标
    var y: Double                  // Y坐标
    var scale: Double              // 缩放比例
    var rotation: Double           // 旋转角度
    var zIndex: Int               // 图层顺序
    var page: JournalPage?
    
    init(mood: String = "happy", emoji: String = "😊", x: Double = 150, y: Double = 250, scale: Double = 1.0, rotation: Double = 0, zIndex: Int = 0) {
        self.id = UUID()
        self.mood = mood
        self.emoji = emoji
        self.x = x
        self.y = y
        self.scale = scale
        self.rotation = rotation
        self.zIndex = zIndex
    }
}

// 心情类型
enum MoodType: String, CaseIterable {
    case happy = "开心"
    case sad = "难过"
    case excited = "激动"
    case calm = "平静"
    case inLove = "恋爱中"
    case tired = "疲惫"
    case angry = "生气"
    case surprised = "惊讶"
    
    var emoji: String {
        switch self {
        case .happy: return "😊"
        case .sad: return "😢"
        case .excited: return "🤩"
        case .calm: return "😌"
        case .inLove: return "🥰"
        case .tired: return "😴"
        case .angry: return "😠"
        case .surprised: return "😲"
        }
    }
}

// MARK: - 主题模板模型
@Model
class JournalTemplate {
    var id: UUID
    var name: String               // 模板名称
    var category: String          // 分类（旅行、美食、穿搭、日记等）
    var backgroundColor: String    // 背景色
    var backgroundImageData: Data? // 背景图
    var layoutData: Data?          // 预设布局数据（JSON）
    var isDefault: Bool            // 是否为默认模板
    
    init(name: String, category: String, backgroundColor: String = "#FFF8F0", isDefault: Bool = false) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.backgroundColor = backgroundColor
        self.isDefault = isDefault
    }
}

// 模板分类
enum TemplateCategory: String, CaseIterable {
    case travel = "旅行"
    case food = "美食"
    case fashion = "穿搭"
    case diary = "日记"
    case study = "学习"
    case health = "健康"
    case blank = "空白"
    
    var icon: String {
        switch self {
        case .travel: return "airplane"
        case .food: return "fork.knife"
        case .fashion: return "tshirt"
        case .diary: return "book.closed"
        case .study: return "book"
        case .health: return "heart"
        case .blank: return "doc"
        }
    }
}

// 预设模板
let presetTemplates: [(name: String, category: String, color: String)] = [
    ("空白模板", "空白", "#FFF8F0"),
    ("旅行日志", "旅行", "#E3F2FD"),
    ("美食记录", "美食", "#FFF3E0"),
    ("今日穿搭", "穿搭", "#F3E5F5"),
    ("日常日记", "日记", "#FFF8E1"),
    ("学习笔记", "学习", "#E8F5E9"),
    ("健康追踪", "健康", "#FFEBEE"),
    ("周计划", "日记", "#E0F7FA"),
    ("月总结", "日记", "#FCE4EC"),
    ("旅行回忆", "旅行", "#E1F5FE")
]

// MARK: - 特效滤镜类型
enum FilterType: String, CaseIterable {
    case none = "无"
    case sepia = "复古"
    case blur = "模糊"
    case mono = "黑白"
    case brightness = "提亮"
    case contrast = "对比"
    
    var icon: String {
        switch self {
        case .none: return "circle.slash"
        case .sepia: return "camera.filters"
        case .blur: return "drop.circle"
        case .mono: return "circle.lefthalf.filled"
        case .brightness: return "sun.max"
        case .contrast: return "circle.righthalf.filled"
        }
    }
}

// 应用滤镜到图像
func applyFilter(_ filterType: FilterType, to image: UIImage) -> UIImage? {
    guard let ciImage = CIImage(image: image) else { return nil }
    
    let context = CIContext()
    var outputImage: CIImage?
    
    switch filterType {
    case .none:
        return image
        
    case .sepia:
        if let sepiaFilter = CIFilter(name: "CISepiaTone") {
            sepiaFilter.setValue(ciImage, forKey: kCIInputImageKey)
            sepiaFilter.setValue(0.8, forKey: kCIInputIntensityKey)
            outputImage = sepiaFilter.outputImage
        }
        
    case .blur:
        if let blurFilter = CIFilter(name: "CIGaussianBlur") {
            blurFilter.setValue(ciImage, forKey: kCIInputImageKey)
            blurFilter.setValue(3.0, forKey: kCIInputRadiusKey)
            outputImage = blurFilter.outputImage?.cropped(to: ciImage.extent)
        }
        
    case .mono:
        if let monoFilter = CIFilter(name: "CIPhotoEffectMono") {
            monoFilter.setValue(ciImage, forKey: kCIInputImageKey)
            outputImage = monoFilter.outputImage
        }
        
    case .brightness:
        if let brightnessFilter = CIFilter(name: "CIColorControls") {
            brightnessFilter.setValue(ciImage, forKey: kCIInputImageKey)
            brightnessFilter.setValue(0.2, forKey: kCIInputBrightnessKey)
            outputImage = brightnessFilter.outputImage
        }
        
    case .contrast:
        if let contrastFilter = CIFilter(name: "CIColorControls") {
            contrastFilter.setValue(ciImage, forKey: kCIInputImageKey)
            contrastFilter.setValue(1.3, forKey: kCIInputContrastKey)
            outputImage = contrastFilter.outputImage
        }
    }
    
    guard let output = outputImage,
          let cgImage = context.createCGImage(output, from: output.extent) else {
        return nil
    }
    
    return UIImage(cgImage: cgImage)
}
