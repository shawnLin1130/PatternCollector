import SwiftUI
import SwiftData

// 视图模式枚举
// 可爱颜色定义
struct CuteColors {
    static let pink = Color(hex: "#FFB6C1")
    static let mint = Color(hex: "#98FB98")
    static let lavender = Color(hex: "#E6E6FA")
    static let softPink = Color(hex: "#F8D7DA")
    static let backgroundGradient = Gradient(colors: [Color(hex: "#FFF0F5").opacity(0.8), Color(hex: "#E0F2FE").opacity(0.8), Color(hex: "#F3E5F5").opacity(0.8)])
}

enum ViewMode: String, CaseIterable {
    case largeGrid = "大网格"
    case smallGrid = "小网格"
    case list = "列表"
}

// 收藏筛选器
enum FavoriteFilter: String, CaseIterable {
    case all = "全部"
    case favorites = "只看收藏"
    case notFavorites = "只看未收藏"
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PatternItem.createdAt, order: .reverse) private var patterns: [PatternItem]
    
    @State private var selectedCategory: String = "全部"
    @State private var showingAddSheet = false
    @State private var searchText = ""
    @State private var viewMode: ViewMode = .largeGrid
    @State private var favoriteFilter: FavoriteFilter = .all
    @State private var selectedColor: String? = nil
    
    var categories: [String] {
        var cats = Set(patterns.map { $0.category })
        cats.insert("全部")
        return cats.sorted()
    }
    
    var availableColors: [String] {
        let colors = Set(patterns.map { $0.dominantColor })
        return colors.filter { $0 != "#000000" }.sorted()
    }
    
    var filteredPatterns: [PatternItem] {
        var result = patterns
        
        // 分类筛选
        if selectedCategory != "全部" {
            result = result.filter { $0.category == selectedCategory }
        }
        
        // 收藏筛选
        switch favoriteFilter {
        case .all:
            break
        case .favorites:
            result = result.filter { $0.isFavorite }
        case .notFavorites:
            result = result.filter { !$0.isFavorite }
        }
        
        // 颜色筛选
        if let color = selectedColor {
            result = result.filter { $0.dominantColor == color }
        }
        
        // 文字搜索
        if !searchText.isEmpty {
            result = result.filter { 
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.notes.localizedCaseInsensitiveContains(searchText) ||
                $0.tags.contains { $0.localizedCaseInsensitiveContains($0) }
            }
        }
        
        return result
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 工具栏：视图模式和收藏筛选
                HStack {
                    // 视图模式切换 - 圆角更大，可爱字体
                    Picker("视图", selection: $viewMode) {
                        ForEach(ViewMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue)
                                .fontDesign(.rounded)
                                .tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .pink.opacity(0.2), radius: 2)
                    
                    Spacer()
                    
                    // 收藏筛选
                    Menu {
                        ForEach(FavoriteFilter.allCases, id: \.self) { filter in
                            Button {
                                favoriteFilter = filter
                            } label: {
                                HStack {
                                    Text(filter.rawValue)
                                        .fontDesign(.rounded)
                                    if favoriteFilter == filter {
                                        Image(systemName: "checkmark.circle.fill")
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: favoriteFilter == .all ? "heart.circle" : (favoriteFilter == .favorites ? "heart.circle.fill" : "heart.slash.circle"))
                            .foregroundStyle(favoriteFilter == .all ? .primary : (favoriteFilter == .favorites ? CuteColors.pink : .orange))
                            .fontDesign(.rounded)
                    }
                    
                    // 颜色筛选
                    Menu {
                        Button {
                            selectedColor = nil
                        } label: {
                            HStack {
                                Text("全部颜色")
                                    .fontDesign(.rounded)
                                if selectedColor == nil {
                                    Image(systemName: "checkmark.circle.fill")
                                }
                            }
                        }
                        
                        Divider()
                        
                        ForEach(availableColors, id: \.self) { color in
                            Button {
                                selectedColor = color
                            } label: {
                                HStack {
                                    Circle()
                                        .fill(Color(hex: color) ?? .gray)
                                        .frame(width: 20, height: 20)
                                    Text(color)
                                        .fontDesign(.rounded)
                                    if selectedColor == color {
                                        Image(systemName: "checkmark.circle.fill")
                                    }
                                }
                            }
                        }
                    } label: {
                        ZStack(alignment: .bottomTrailing) {
                            Image(systemName: "paintbrush.pointed.fill")
                            if let color = selectedColor {
                                Circle()
                                    .fill(Color(hex: color) ?? .gray)
                                    .frame(width: 10, height: 10)
                            }
                        }
                        .foregroundStyle(CuteColors.lavender)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // 分类筛选
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(categories, id: \.self) { category in
                            Button {
                                selectedCategory = category
                            } label: {
                                Text(category)
                                    .font(.system(.medium, design: .rounded))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(selectedCategory == category ? CuteColors.pink : Color.gray.opacity(0.15))
                                    .foregroundColor(selectedCategory == category ? .white : .primary)
                                    .clipShape(Capsule())
                                    .shadow(color: .pink.opacity(0.3), radius: 4)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // 图案网格/列表
                if filteredPatterns.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 60))
                            .foregroundColor(CuteColors.mint)
                            .symbolEffect(.pulse)
                        Text("还没有图案哦～💕")
                            .font(.system(.title2, design: .rounded, weight: .medium))
                            .foregroundColor(.secondary)
                        Button {
                            showingAddSheet = true
                        } label: {
                            Label("添加第一个图案～✨", systemImage: "plus.circle.fill")
                                .fontDesign(.rounded)
                                .padding()
                                .background(CuteColors.softPink)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .shadow(color: .pink.opacity(0.4), radius: 8)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    contentView
                }
            }
            .navigationTitle("图案收集册💕")
            .searchable(text: $searchText, prompt: "搜索图案")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(CuteColors.pink)
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "paintbrush.pointed.fill")
                            .foregroundColor(CuteColors.lavender)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddPatternView(categories: categories)
            }
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch viewMode {
        case .largeGrid:
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
                    ForEach(filteredPatterns) { pattern in
                        PatternCard(pattern: pattern, viewMode: .largeGrid)
                    }
                }
                .padding()
            }
        case .smallGrid:
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
                    ForEach(filteredPatterns) { pattern in
                        PatternCard(pattern: pattern, viewMode: .smallGrid)
                    }
                }
                .padding()
            }
        case .list:
            List(filteredPatterns) { pattern in
                PatternCard(pattern: pattern, viewMode: .list)
            }
            .listStyle(.plain)
        }
    }
}

// 颜色扩展
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}

struct PatternCard: View {
    let pattern: PatternItem
    let viewMode: ViewMode
    
    var body: some View {
        switch viewMode {
        case .largeGrid:
            largeGridCard
        case .smallGrid:
            smallGridCard
        case .list:
            listCard
        }
    }
    
    private var largeGridCard: some View {
        NavigationLink {
            PatternDetailView(pattern: pattern)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                // 图片
                ZStack(alignment: .topTrailing) {
                    if let imageData = pattern.imageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 150)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 150)
                            .overlay {
                                Image(systemName: "photo")
                                    .font(.title)
                                    .foregroundColor(.gray)
                            }
                    }
                    
                    // 收藏按钮
                    Button {
                        pattern.isFavorite.toggle()
                    } label: {
                        Image(systemName: pattern.isFavorite ? "heart.fill" : "heart")
                            .font(.title3)
                            .foregroundColor(pattern.isFavorite ? .red : .white)
                            .padding(8)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                    .padding(8)
                    
                    // 颜色标签
                    if pattern.dominantColor != "#000000" {
                        Circle()
                            .fill(Color(hex: pattern.dominantColor) ?? .gray)
                            .frame(width: 16, height: 16)
                            .overlay(Circle().stroke(Color.white, lineWidth: 1))
                            .padding(8)
                            .position(x: 30, y: 30)
                    }
                }
                
                // 名称和分类
                VStack(alignment: .leading, spacing: 4) {
                    Text(pattern.name.isEmpty ? "未命名" : pattern.name)
                        .font(.headline)
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    
                    Text(pattern.category)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
    
    private var smallGridCard: some View {
        NavigationLink {
            PatternDetailView(pattern: pattern)
        } label: {
            VStack(spacing: 4) {
                // 图片
                ZStack(alignment: .topTrailing) {
                    if let imageData = pattern.imageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 70, height: 70)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 70, height: 70)
                            .overlay {
                                Image(systemName: "photo")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    // 收藏按钮
                    Button {
                        pattern.isFavorite.toggle()
                    } label: {
                        Image(systemName: pattern.isFavorite ? "heart.fill" : "heart")
                            .font(.caption)
                            .foregroundColor(pattern.isFavorite ? .red : .white)
                            .padding(4)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    private var listCard: some View {
        NavigationLink {
            PatternDetailView(pattern: pattern)
        } label: {
            HStack(spacing: 12) {
                // 图片
                if let imageData = pattern.imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 60, height: 60)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                // 资讯
                VStack(alignment: .leading, spacing: 4) {
                    Text(pattern.name.isEmpty ? "未命名" : pattern.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    HStack {
                        Text(pattern.category)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if pattern.dominantColor != "#000000" {
                            Circle()
                                .fill(Color(hex: pattern.dominantColor) ?? .gray)
                                .frame(width: 12, height: 12)
                        }
                    }
                }
                
                Spacer()
                
                // 收藏按钮
                Button {
                    pattern.isFavorite.toggle()
                } label: {
                    Image(systemName: pattern.isFavorite ? "heart.fill" : "heart")
                        .font(.title3)
                        .foregroundColor(pattern.isFavorite ? .red : .gray)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

struct AddPatternView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let categories: [String]
    
    @State private var name = ""
    @State private var category = "默认"
    @State private var notes = ""
    @State private var tagsText = ""
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var selectedColor: String = "#FF5733"
    
    // 预定义颜色选项
    let colorOptions: [String] = [
        "#FF5733", "#FFBD33", "#DBFF33", "#75FF33", "#33FF57",
        "#33FFBD", "#33DBFF", "#3375FF", "#5733FF", "#BD33FF",
        "#FF33DB", "#FF3375", "#FFFFFF", "#000000", "#808080"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button {
                        showingImagePicker = true
                    } label: {
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 200)
                                .clipped()
                        } else {
                            VStack {
                                Image(systemName: "photo.badge.plus")
                                    .font(.largeTitle)
                                Text("添加图片")
                            }
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.1))
                        }
                    }
                }
                
                Section("资讯") {
                    TextField("名称", text: $name)
                    
                    Picker("分类", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                    
                    TextField("笔记", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("标签") {
                    TextField("标签（用逗号分隔）", text: $tagsText)
                }
                
                Section("主色调") {
                    // 快速选择预设颜色
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 35))], spacing: 8) {
                        ForEach(colorOptions, id: \.self) { color in
                            Button {
                                selectedColor = color
                            } label: {
                                Circle()
                                    .fill(Color(hex: color) ?? .gray)
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedColor == color ? Color.blue : Color.clear, lineWidth: 2)
                                    )
                            }
                        }
                    }
                    .padding(.top, 8)
                    
                    HStack {
                        Text("已选颜色:")
                        Spacer()
                        Circle()
                            .fill(Color(hex: selectedColor) ?? .gray)
                            .frame(width: 30, height: 30)
                        Text(selectedColor)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("添加图案")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        savePattern()
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage)
            }
        }
    }
    
    func savePattern() {
        let tags = tagsText.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
        
        let item = PatternItem(
            name: name,
            category: category,
            tags: tags,
            notes: notes,
            imageData: selectedImage?.jpegData(compressionQuality: 0.8),
            isFavorite: false,
            dominantColor: selectedColor
        )
        
        modelContext.insert(item)
        
        dismiss()
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

struct PatternDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var pattern: PatternItem
    
    @State private var newTag = ""
    @State private var isEditingNotes = false
    @State private var editedNotes = ""
    @State private var showingShareSheet = false
    @State private var shareImage: UIImage? = nil
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 图片
                    if let imageData = pattern.imageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .onTapGesture {
                                shareImage = uiImage
                                showingShareSheet = true
                            }
                    }
                    
                    // 基本资讯
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(pattern.name.isEmpty ? "未命名" : pattern.name)
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            // 收藏按钮
                            Button {
                                pattern.isFavorite.toggle()
                            } label: {
                                Image(systemName: pattern.isFavorite ? "heart.fill" : "heart")
                                    .font(.title2)
                                    .foregroundColor(pattern.isFavorite ? .red : .gray)
                            }
                        }
                        
                        HStack {
                            Text("分类:")
                                .foregroundColor(.secondary)
                            Text(pattern.category)
                                .fontWeight(.medium)
                        }
                        
                        if pattern.dominantColor != "#000000" {
                            HStack {
                                Text("主色调:")
                                    .foregroundColor(.secondary)
                                Circle()
                                    .fill(Color(hex: pattern.dominantColor) ?? .gray)
                                    .frame(width: 20, height: 20)
                                Text(pattern.dominantColor)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if !pattern.notes.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("笔记:")
                                    .foregroundColor(.secondary)
                                Text(pattern.notes)
                            }
                            .padding(.top, 8)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Divider()
                    
                    // 标签管理
                    VStack(alignment: .leading, spacing: 12) {
                        Text("标签")
                            .font(.headline)
                        
                        // 现有标签
                        FlowLayout(spacing: 8) {
                            ForEach(pattern.tags, id: \.self) { tag in
                                HStack(spacing: 4) {
                                    Text(tag)
                                        .font(.subheadline)
                                    
                                    Button {
                                        removeTag(tag)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(Capsule())
                            }
                        }
                        
                        // 添加标签
                        HStack {
                            TextField("新标签", text: $newTag)
                                .textFieldStyle(.roundedBorder)
                                .submitLabel(.done)
                                .onSubmit {
                                    addTag()
                                }
                            
                            Button {
                                addTag()
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                            }
                            .disabled(newTag.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("图案详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if pattern.imageData != nil {
                        Button {
                            if let imageData = pattern.imageData {
                                shareImage = UIImage(data: imageData)
                                showingShareSheet = true
                            }
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let image = shareImage {
                    ShareSheet(activityItems: [image])
                }
            }
        }
    }
    
    private func addTag() {
        let tag = newTag.trimmingCharacters(in: .whitespaces)
        if !tag.isEmpty && !pattern.tags.contains(tag) {
            pattern.tags.append(tag)
            newTag = ""
        }
    }
    
    private func removeTag(_ tag: String) {
        pattern.tags.removeAll { $0 == tag }
    }
}

// 分享Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// 设置页面
struct SettingsView: View {
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0
    
    var body: some View {
        Form {
            Section("外观") {
                Picker("主题模式", selection: $appearanceMode) {
                    Text("跟随系统").tag(0)
                    Text("浅色").tag(1)
                    Text("深色").tag(2)
                }
            }
            
            Section("关于") {
                HStack {
                    Text("版本")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("设置")
    }
}

// 流式布局用于标签
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }
    
    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            totalHeight = currentY + lineHeight
        }
        
        return (CGSize(width: maxWidth, height: totalHeight), positions)
    }
}

#Preview {
    NavigationStack {
        ContentView()
    }
    .modelContainer(for: PatternItem.self, inMemory: true)
}
