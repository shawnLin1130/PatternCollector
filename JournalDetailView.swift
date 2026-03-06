import SwiftUI
import SwiftData

// 手帐本详情视图 - 页面浏览（带翻页动画）
struct JournalDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var book: JournalBook
    
    @State private var showingAddPage = false
    @State private var currentPageIndex = 0
    
    // 米白色纸张背景色
    let paperColor = Color(hex: "#FFF8F0")
    
    var sortedPages: [JournalPage] {
        book.pages.sorted(by: { $0.pageNumber < $1.pageNumber })
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 纸张纹理背景
                paperColor
                    .ignoresSafeArea()
                
                if book.pages.isEmpty {
                    // 空状态
                    emptyStateView
                } else {
                    // 翻页效果
                    VStack(spacing: 0) {
                        if sortedPages.count > 1 {
                            // 页码指示器
                            pageIndicator
                        }
                        
                        // 页面内容（使用TabView实现翻页）
                        TabView(selection: $currentPageIndex) {
                            ForEach(Array(sortedPages.enumerated()), id: \.element.id) { index, page in
                                NavigationLink {
                                    JournalPageEditorView(page: page)
                                } label: {
                                    JournalPageThumbnail(page: page, paperColor: paperColor)
                                }
                                .tag(index)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .animation(.interactiveSpring(response: 0.4, dampingFraction: 0.8), value: currentPageIndex)
                    }
                }
            }
            .navigationTitle(book.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        addNewPage()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(CuteColors.pink)
                    }
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(CuteColors.lavender.opacity(0.7))
            
            Text("还没有页面呢～📝")
                .font(.system(.title2, design: .rounded, weight: .medium))
                .foregroundColor(.secondary)
            
            Button {
                addNewPage()
            } label: {
                Label("添加第一页～✨", systemImage: "plus.circle.fill")
                    .fontDesign(.rounded)
                    .padding()
                    .background(CuteColors.softPink)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .pink.opacity(0.4), radius: 8)
            }
        }
    }
    
    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<sortedPages.count, id: \.self) { index in
                Circle()
                    .fill(currentPageIndex == index ? CuteColors.pink : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .scaleEffect(currentPageIndex == index ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3), value: currentPageIndex)
            }
        }
        .padding(.top, 8)
    }
    
    private func addNewPage() {
        let newPageNumber = (book.pages.map { $0.pageNumber }.max() ?? 0) + 1
        let newPage = JournalPage(pageNumber: newPageNumber)
        book.pages.append(newPage)
        
        // 自动跳转到新页面
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            currentPageIndex = sortedPages.count - 1
        }
    }
}

// 页面缩略图（带装订效果）
struct JournalPageThumbnail: View {
    let page: JournalPage
    let paperColor: Color
    
    var body: some View {
        VStack(spacing: 0) {
            // 纸张预览（带装订效果）
            ZStack {
                // 纸张背景
                RoundedRectangle(cornerRadius: 4)
                    .fill(paperColor)
                
                // 纸张纹理效果
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.02)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // 左侧装订线圈效果
                HStack(spacing: 12) {
                    ForEach(0..<5, id: \.self) { index in
                        Circle()
                            .fill(Color(hex: "#8B4513") ?? .brown)
                            .frame(width: 8, height: 8)
                            .shadow(color: .black.opacity(0.3), radius: 1, x: 1, y: 1)
                    }
                    Spacer()
                }
                .padding(.leading, 8)
                
                // 页面元素预览
                ForEach(page.elements.sorted(by: { $0.zIndex < $1.zIndex })) { element in
                    if let imageData = element.patternImageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: element.width * 0.25, height: element.height * 0.25)
                            .rotationEffect(.degrees(element.rotation * 0.25))
                            .position(x: element.x * 0.25, y: element.y * 0.25)
                    }
                }
                
                // 空白提示
                if page.elements.isEmpty {
                    VStack(spacing: 4) {
                        Image(systemName: "photo.badge.plus")
                            .font(.title2)
                            .foregroundColor(.gray.opacity(0.3))
                        Text("空白页")
                            .font(.caption2)
                            .foregroundColor(.gray.opacity(0.4))
                    }
                }
            }
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .shadow(color: .black.opacity(0.1), radius: 2, x: 1, y: 1)
            
            // 页码
            HStack(spacing: 4) {
                Image(systemName: "doc.text.fill")
                    .font(.caption2)
                Text("第 \(page.pageNumber) 页")
                    .font(.caption)
            }
            .foregroundColor(.secondary)
            .padding(.top, 8)
        }
        .padding(8)
        .background(Color.white.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// 页面编辑器视图（支持拖拽、缩放、旋转）
struct JournalPageEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var page: JournalPage
    
    @State private var showingPatternPicker = false
    @State private var selectedElement: PageElement?
    @State private var showingElementEditor = false
    
    // 纸张颜色
    let paperColor = Color(hex: "#FFF8F0")
    
    var body: some View {
        ZStack {
            // 米白色纸张背景
            paperColor
                .ignoresSafeArea()
            
            // 装订效果（左侧）
            HStack(spacing: 0) {
                // 装订区域背景
                Rectangle()
                    .fill(Color(hex: "#F5E6D3") ?? Color(hex: "#FFF8E7")!)
                    .frame(width: 30)
                
                // 主纸张区域
                GeometryReader { geometry in
                    ZStack {
                        // 纸张纹理
                        paperTextureOverlay
                        
                        // 页面元素（可拖拽、缩放、旋转）
                        ForEach(page.elements.sorted(by: { $0.zIndex < $1.zIndex })) { element in
                            DraggableElementView(
                                element: element,
                                isSelected: selectedElement?.id == element.id,
                                onTap: {
                                    selectedElement = element
                                    showingElementEditor = true
                                },
                                onUpdate: { updatedElement in
                                    // 更新位置
                                    element.x = updatedElement.x
                                    element.y = updatedElement.y
                                    element.width = updatedElement.width
                                    element.height = updatedElement.height
                                    element.rotation = updatedElement.rotation
                                }
                            )
                        }
                        
                        // 点击空白区域取消选择
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedElement = nil
                            }
                    }
                }
            }
            
            // 空状态提示
            if page.elements.isEmpty {
                emptyStateOverlay
            }
            
            // 添加图案按钮
            VStack {
                Spacer()
                HStack {
                    // 左侧：添加图案按钮
                    Button {
                        showingPatternPicker = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                            Text("添加图案")
                        }
                        .font(.system(.headline, design: .rounded))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [CuteColors.pink, Color(hex: "#FF69B4")!],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .shadow(color: .pink.opacity(0.4), radius: 8)
                    }
                    .padding(.leading, 40)
                    .padding(.bottom, 20)
                    
                    Spacer()
                }
            }
        }
        .navigationTitle("第 \(page.pageNumber) 页")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingPatternPicker = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(CuteColors.pink)
                }
            }
        }
        .sheet(isPresented: $showingPatternPicker) {
            PatternPickerSheet(page: page)
        }
        .sheet(isPresented: $showingElementEditor) {
            if let element = selectedElement {
                ElementEditorSheet(element: element) {
                    selectedElement = nil
                }
            }
        }
    }
    
    // 纸张纹理叠加
    private var paperTextureOverlay: some View {
        GeometryReader { geometry in
            ZStack {
                // 淡淡的噪点纹理效果
                ForEach(0..<50, id: \.self) { _ in
                    Circle()
                        .fill(Color.black.opacity(0.01))
                        .frame(width: CGFloat.random(in: 1...3), height: CGFloat.random(in: 1...3))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                }
                
                // 纸张边缘效果
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(Color.black.opacity(0.05), lineWidth: 1)
            }
        }
    }
    
    // 空状态
    private var emptyStateOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "hand.draw")
                .font(.system(size: 50))
                .foregroundColor(CuteColors.lavender.opacity(0.6))
            
            Text("点击下方按钮添加图案～✨")
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.secondary)
            
            Text("长按图案可拖拽移动")
                .font(.caption)
                .foregroundColor(.gray.opacity(0.7))
        }
    }
}

// 可拖拽的元素视图（支持拖拽、缩放、旋转）
struct DraggableElementView: View {
    @Bindable var element: PageElement
    let isSelected: Bool
    let onTap: () -> Void
    let onUpdate: (PageElement) -> Void
    
    @State private var offset: CGSize = .zero
    @State private var currentScale: CGFloat = 1.0
    @State private var currentRotation: Double = 0
    @State private var lastScale: CGFloat = 1.0
    @State private var lastRotation: Double = 0
    
    // 初始位置
    private var initialPosition: CGPoint {
        CGPoint(x: element.x, y: element.y)
    }
    
    var body: some View {
        Group {
            if let imageData = element.patternImageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: element.width, height: element.height)
                    .rotationEffect(.degrees(element.rotation + currentRotation))
                    .scaleEffect(currentScale)
                    .overlay(
                        // 选中边框
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(isSelected ? CuteColors.pink : .clear, lineWidth: 2)
                    )
                    .overlay(
                        // 删除按钮（选中时显示）
                        Group {
                            if isSelected {
                                VStack {
                                    HStack {
                                        Spacer()
                                        deleteButton
                                    }
                                    Spacer()
                                }
                            }
                        }
                    )
                    .shadow(color: isSelected ? .pink.opacity(0.3) : .black.opacity(0.1), radius: isSelected ? 8 : 4)
                    .offset(offset)
                    .gesture(
                        // 拖拽手势
                        DragGesture()
                            .onChanged { value in
                                offset = CGSize(
                                    width: value.translation.width,
                                    height: value.translation.height
                                )
                            }
                            .onEnded { value in
                                // 更新元素位置
                                let newX = element.x + value.translation.width
                                let newY = element.y + value.translation.height
                                element.x = newX
                                element.y = newY
                                offset = .zero
                                onUpdate(element)
                            }
                    )
                    .simultaneousGesture(
                        // 缩放手势
                        MagnificationGesture()
                            .onChanged { scale in
                                currentScale = lastScale * scale
                            }
                            .onEnded { scale in
                                let newScale = element.width * lastScale * scale
                                element.width = max(30, min(newScale, 500))
                                element.height = max(30, min(element.height * scale, 500))
                                lastScale = 1.0
                                currentScale = 1.0
                                onUpdate(element)
                            }
                    )
                    .simultaneousGesture(
                        // 旋转手势
                        RotationGesture()
                            .onChanged { angle in
                                currentRotation = lastRotation + angle.degrees
                            }
                            .onEnded { angle in
                                element.rotation += lastRotation + angle.degrees
                                lastRotation = 0
                                currentRotation = 0
                                onUpdate(element)
                            }
                    )
                    .onTapGesture {
                        onTap()
                    }
                    .onAppear {
                        lastScale = 1.0
                        lastRotation = 0
                    }
            }
        }
    }
    
    // 删除按钮
    private var deleteButton: some View {
        Button {
            // 删除功能由外部处理
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.title2)
                .foregroundColor(.white)
                .background(Circle().fill(Color.red).frame(width: 24, height: 24))
        }
        .padding(4)
    }
}

// 图案选择器Sheet
struct PatternPickerSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var page: JournalPage
    
    @Query(sort: \PatternItem.createdAt, order: .reverse) private var patterns: [PatternItem]
    
    @State private var searchText = ""
    
    var filteredPatterns: [PatternItem] {
        if searchText.isEmpty {
            return patterns
        }
        return patterns.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if patterns.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 50))
                            .foregroundColor(CuteColors.lavender)
                        
                        Text("还没有图案呢～💕")
                            .font(.system(.title3, design: .rounded))
                            .foregroundColor(.secondary)
                        
                        Text("先去图案收集册添加一些图案吧～")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else if filteredPatterns.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(CuteColors.lavender)
                        
                        Text("没有找到相关图案～")
                            .font(.system(.title3, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ], spacing: 12) {
                            ForEach(filteredPatterns) { pattern in
                                Button {
                                    addPatternToPage(pattern)
                                    dismiss()
                                } label: {
                                    if let imageData = pattern.imageData, let uiImage = UIImage(data: imageData) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 100, height: 100)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .shadow(color: .black.opacity(0.1), radius: 2)
                                    } else {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(width: 100, height: 100)
                                            .overlay(
                                                Image(systemName: "photo")
                                                    .foregroundColor(.gray)
                                            )
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("选择图案")
            .searchable(text: $searchText, prompt: "搜索图案")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func addPatternToPage(_ pattern: PatternItem) {
        let element = PageElement(
            patternId: pattern.id,
            patternImageData: pattern.imageData,
            x: 150,
            y: 250,
            width: 120,
            height: 120,
            rotation: 0,
            zIndex: page.elements.count
        )
        element.page = page
        page.elements.append(element)
    }
}

// 元素编辑器Sheet
struct ElementEditorSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var element: PageElement
    let onDismiss: () -> Void
    
    @State private var width: Double = 120
    @State private var height: Double = 120
    @State private var rotation: Double = 0
    
    var body: some View {
        NavigationStack {
            Form {
                Section("尺寸") {
                    HStack {
                        Text("宽度")
                        Spacer()
                        TextField("", value: $width, format: .number)
                            .keyboardType(.numberPad)
                            .frame(width: 60)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    HStack {
                        Text("高度")
                        Spacer()
                        TextField("", value: $height, format: .number)
                            .keyboardType(.numberPad)
                            .frame(width: 60)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                
                Section("旋转") {
                    VStack {
                        Slider(value: $rotation, in: -180...180, step: 1) {
                            Text("旋转角度")
                        }
                        Text("\(Int(rotation))°")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        deleteElement()
                    } label: {
                        HStack {
                            Spacer()
                            Text("删除这个图案")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("编辑图案")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        onDismiss()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveChanges()
                        onDismiss()
                        dismiss()
                    }
                }
            }
            .onAppear {
                width = element.width
                height = element.height
                rotation = element.rotation
            }
        }
    }
    
    private func saveChanges() {
        element.width = width
        element.height = height
        element.rotation = rotation
    }
    
    private func deleteElement() {
        modelContext.delete(element)
    }
}
