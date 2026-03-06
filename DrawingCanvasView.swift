import SwiftUI
import SwiftData

// MARK: - 手绘涂鸦画布视图
struct DrawingCanvasView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var page: JournalPage
    
    @State private var isDrawingMode = false
    @State private var currentColor: String = "#000000"
    @State private var currentBrush: DrawingBrush = .medium
    @State private var currentPath: [DrawingPoint] = []
    @State private var paths: [(points: [DrawingPoint], color: String, lineWidth: Double)] = []
    @State private var selectedPathIndex: Int?
    @State private var showingColorPicker = false
    @State private var showingBrushPicker = false
    @State private var undoStack: [[(points: [DrawingPoint], color: String, lineWidth: Double)]] = []
    
    var body: some View {
        ZStack {
            // 原有页面内容（半透明，作为背景）
            // 这里可以放页面内容的预览
            
            // 涂鸦层
            Canvas { context, size in
                // 绘制所有路径
                for (index, pathData) in paths.enumerated() {
                    if pathData.points.count > 1 {
                        var path = Path()
                        path.move(to: CGPoint(x: pathData.points[0].x, y: pathData.points[0].y))
                        for point in pathData.points.dropFirst() {
                            path.addLine(to: CGPoint(x: point.x, y: point.y))
                        }
                        
                        context.stroke(
                            path,
                            with: .color(Color(hex: pathData.color) ?? .black),
                            style: StrokeStyle(lineWidth: pathData.lineWidth, lineCap: .round, lineJoin: .round)
                        )
                    }
                }
                
                // 绘制当前正在画的路径
                if currentPath.count > 1 {
                    var path = Path()
                    path.move(to: CGPoint(x: currentPath[0].x, y: currentPath[0].y))
                    for point in currentPath.dropFirst() {
                        path.addLine(to: CGPoint(x: point.x, y: point.y))
                    }
                    
                    context.stroke(
                        path,
                        with: .color(Color(hex: currentColor) ?? .black),
                        style: StrokeStyle(lineWidth: currentBrush.lineWidth, lineCap: .round, lineJoin: .round)
                    )
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if isDrawingMode {
                            let point = DrawingPoint(x: value.location.x, y: value.location.y)
                            currentPath.append(point)
                        }
                    }
                    .onEnded { value in
                        if isDrawingMode && currentPath.count > 1 {
                            // 保存当前路径到undo stack
                            undoStack.append(paths)
                            
                            // 保存到paths
                            paths.append((points: currentPath, color: currentColor, lineWidth: currentBrush.lineWidth))
                            
                            // 保存到数据库
                            savePathToDatabase(points: currentPath, color: currentColor, lineWidth: currentBrush.lineWidth)
                        }
                        currentPath = []
                    }
            )
            
            // 绘制模式指示器
            if isDrawingMode {
                VStack {
                    HStack {
                        Spacer()
                        HStack(spacing: 12) {
                            // 颜色显示
                            Circle()
                                .fill(Color(hex: currentColor) ?? .black)
                                .frame(width: 24, height: 24)
                                .overlay(Circle().strokeBorder(Color.white, lineWidth: 2))
                                .onTapGesture {
                                    showingColorPicker = true
                                }
                            
                            // 画笔粗细显示
                            Image(systemName: "line.diagonal")
                                .font(.system(size: 16, weight: currentBrush == .fine ? .thin : (currentBrush == .medium ? .regular : .bold)))
                                .foregroundColor(Color(hex: currentColor) ?? .black)
                                .onTapGesture {
                                    showingBrushPicker = true
                                }
                            
                            // 撤销按钮
                            if !paths.isEmpty {
                                Button {
                                    undo()
                                } label: {
                                    Image(systemName: "arrow.uturn.backward")
                                        .font(.title3)
                                }
                            }
                            
                            // 完成按钮
                            Button {
                                isDrawingMode = false
                            } label: {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(CuteColors.pink)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .shadow(radius: 4)
                    }
                    .padding()
                    
                    Spacer()
                }
            }
        }
        .sheet(isPresented: $showingColorPicker) {
            ColorPickerSheet(selectedColor: $currentColor)
        }
        .sheet(isPresented: $showingBrushPicker) {
            BrushPickerSheet(selectedBrush: $currentBrush)
        }
        .onAppear {
            loadPathsFromDatabase()
        }
    }
    
    private func savePathToDatabase(points: [DrawingPoint], color: String, lineWidth: Double) {
        guard let pointsData = try? JSONEncoder().encode(points) else { return }
        
        let drawingPath = DrawingPath(colorHex: color, lineWidth: lineWidth, zIndex: page.elements.count)
        drawingPath.pointsData = pointsData
        drawingPath.page = page
        page.elements.append(contentsOf: [])
    }
    
    private func loadPathsFromDatabase() {
        // 从数据库加载现有的涂鸦路径
        // 这里需要查询DrawingPath模型
    }
    
    private func undo() {
        guard !undoStack.isEmpty else { return }
        paths = undoStack.removeLast()
    }
}

// MARK: - 颜色选择Sheet
struct ColorPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedColor: String
    
    private let columns = Array(repeating: GridItem(.flexible(), count: 5), count: 2)
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // 预览
                HStack {
                    Spacer()
                    Circle()
                        .fill(Color(hex: selectedColor) ?? .black)
                        .frame(width: 60, height: 60)
                        .overlay(Circle().strokeBorder(Color.white, lineWidth: 3))
                        .shadow(radius: 4)
                    Spacer()
                }
                .padding(.top, 20)
                
                // 颜色网格
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(drawingColors, id: \.self) { color in
                        Button {
                            selectedColor = color
                            dismiss()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: color) ?? .gray)
                                    .frame(width: 44, height: 44)
                                
                                if selectedColor == color {
                                    Circle()
                                        .strokeBorder(Color.white, lineWidth: 3)
                                        .frame(width: 44, height: 44)
                                    
                                    Image(systemName: "checkmark")
                                        .font(.caption.bold())
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("选择颜色")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - 画笔粗细选择Sheet
struct BrushPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedBrush: DrawingBrush
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // 预览
                VStack(spacing: 16) {
                    ForEach(DrawingBrush.allCases, id: \.self) { brush in
                        Button {
                            selectedBrush = brush
                            dismiss()
                        } label: {
                            HStack {
                                Text(brush.rawValue)
                                    .font(.headline)
                                
                                Spacer()
                                
                                // 粗细预览
                                RoundedRectangle(cornerRadius: brush.lineWidth / 2)
                                    .fill(Color.black)
                                    .frame(width: 80, height: brush.lineWidth)
                                
                                if selectedBrush == brush {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(CuteColors.pink)
                                }
                            }
                            .padding()
                            .background(selectedBrush == brush ? CuteColors.pink.opacity(0.1) : Color.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .foregroundColor(.primary)
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("选择画笔粗细")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - 涂鸦控制工具栏
struct DrawingToolbarView: View {
    @Binding var isDrawingMode: Bool
    @Binding var currentColor: String
    @Binding var currentBrush: DrawingBrush
    let onUndo: () -> Void
    let canUndo: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // 画笔模式按钮
            Button {
                isDrawingMode.toggle()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: isDrawingMode ? "pencil.circle.fill" : "pencil.circle")
                    Text(isDrawingMode ? "完成绘画" : "画笔模式")
                }
                .font(.system(.subheadline, design: .rounded))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isDrawingMode ? CuteColors.pink : Color.gray.opacity(0.15))
                .foregroundColor(isDrawingMode ? .white : .primary)
                .clipShape(Capsule())
            }
            
            if isDrawingMode {
                // 颜色按钮
                Button {
                    // 颜色选择由外部sheet处理
                } label: {
                    Circle()
                        .fill(Color(hex: currentColor) ?? .black)
                        .frame(width: 32, height: 32)
                        .overlay(Circle().strokeBorder(Color.white, lineWidth: 2))
                }
                
                // 粗细按钮
                Button {
                    // 粗细选择由外部sheet处理
                } label: {
                    Image(systemName: "line.diagonal")
                        .font(.system(size: 18, weight: currentBrush == .fine ? .thin : (currentBrush == .medium ? .regular : .bold)))
                        .frame(width: 32, height: 32)
                        .background(Color.gray.opacity(0.15))
                        .clipShape(Circle())
                }
                
                // 撤销按钮
                if canUndo {
                    Button {
                        onUndo()
                    } label: {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.title3)
                            .frame(width: 32, height: 32)
                            .background(Color.gray.opacity(0.15))
                            .clipShape(Circle())
                    }
                }
            }
        }
    }
}
