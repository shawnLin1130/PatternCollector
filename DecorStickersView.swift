import SwiftUI
import SwiftData

// MARK: - 装饰贴纸选择视图
struct DecorStickerPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (String) -> Void
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 5)
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 分类标题
                    VStack(alignment: .leading, spacing: 8) {
                        Text("可爱装饰 ✨")
                            .font(.headline)
                            .foregroundColor(CuteColors.pink)
                        
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(BuiltInDecorSticker.allCases, id: \.self) { sticker in
                                Button {
                                    onSelect(sticker.emoji)
                                    dismiss()
                                } label: {
                                    Text(sticker.emoji)
                                        .font(.system(size: 32))
                                        .frame(width: 50, height: 50)
                                        .background(Color.pink.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                    }
                    
                    Divider()
                    
                    // 更多装饰
                    VStack(alignment: .leading, spacing: 8) {
                        Text("浪漫氛围 💕")
                            .font(.headline)
                            .foregroundColor(CuteColors.lavender)
                        
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(["💕", "💗", "💖", "💘", "💝", "🌸", "🌺", "🌻", "🌷", "🌹"], id: \.self) { emoji in
                                Button {
                                    onSelect(emoji)
                                    dismiss()
                                } label: {
                                    Text(emoji)
                                        .font(.system(size: 32))
                                        .frame(width: 50, height: 50)
                                        .background(Color.purple.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("自然元素 🌿")
                            .font(.headline)
                            .foregroundColor(CuteColors.mint)
                        
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(["🌿", "🍀", "🌱", "🌴", "🌵", "🍁", "🍃", "🍂", "☁️", "🌈"], id: \.self) { emoji in
                                Button {
                                    onSelect(emoji)
                                    dismiss()
                                } label: {
                                    Text(emoji)
                                        .font(.system(size: 32))
                                        .frame(width: 50, height: 50)
                                        .background(Color.green.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("节日主题 🎉")
                            .font(.headline)
                            .foregroundColor(.orange)
                        
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(["🎄", "🎅", "🎃", "🎂", "🎁", "🎉", "🎊", "🎈", "🎐", "🏮"], id: \.self) { emoji in
                                Button {
                                    onSelect(emoji)
                                    dismiss()
                                } label: {
                                    Text(emoji)
                                        .font(.system(size: 32))
                                        .frame(width: 50, height: 50)
                                        .background(Color.orange.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("选择装饰贴纸")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 装饰贴纸组件（可拖拽、缩放、旋转）
struct DraggableStickerView: View {
    @Bindable var sticker: StickerDecor
    let isSelected: Bool
    let onTap: () -> Void
    let onUpdate: (StickerDecor) -> Void
    let onDelete: () -> Void
    
    @State private var offset: CGSize = .zero
    @State private var currentScale: CGFloat = 1.0
    @State private var currentRotation: Double = 0
    @State private var lastScale: CGFloat = 1.0
    @State private var lastRotation: Double = 0
    
    var body: some View {
        Group {
            Text(sticker.emoji)
                .font(.system(size: 40 * sticker.scale))
                .rotationEffect(.degrees(sticker.rotation + currentRotation))
                .scaleEffect(currentScale)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(isSelected ? CuteColors.pink : .clear, lineWidth: 2)
                )
                .shadow(color: isSelected ? .pink.opacity(0.3) : .black.opacity(0.1), radius: isSelected ? 8 : 4)
                .offset(offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            offset = CGSize(width: value.translation.width, height: value.translation.height)
                        }
                        .onEnded { value in
                            sticker.x += value.translation.width
                            sticker.y += value.translation.height
                            offset = .zero
                            onUpdate(sticker)
                        }
                )
                .simultaneousGesture(
                    MagnificationGesture()
                        .onChanged { scale in
                            currentScale = lastScale * scale
                        }
                        .onEnded { scale in
                            let newScale = sticker.scale * lastScale * scale
                            sticker.scale = max(0.3, min(newScale, 3.0))
                            lastScale = 1.0
                            currentScale = 1.0
                            onUpdate(sticker)
                        }
                )
                .simultaneousGesture(
                    RotationGesture()
                        .onChanged { angle in
                            currentRotation = lastRotation + angle.degrees
                        }
                        .onEnded { angle in
                            sticker.rotation += lastRotation + angle.degrees
                            lastRotation = 0
                            currentRotation = 0
                            onUpdate(sticker)
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

// MARK: - 贴纸编辑Sheet
struct StickerEditorSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var sticker: StickerDecor
    let onDismiss: () -> Void
    
    @State private var scale: Double = 1.0
    @State private var rotation: Double = 0
    
    var body: some View {
        NavigationStack {
            Form {
                Section("预览") {
                    HStack {
                        Spacer()
                        Text(sticker.emoji)
                            .font(.system(size: 60 * scale))
                            .rotationEffect(.degrees(rotation))
                        Spacer()
                    }
                    .frame(height: 100)
                }
                
                Section("缩放") {
                    VStack {
                        Slider(value: $scale, in: 0.3...3.0, step: 0.1) {
                            Text("缩放")
                        }
                        Text("\(String(format: "%.1f", scale))x")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("旋转") {
                    VStack {
                        Slider(value: $rotation, in: -180...180, step: 5) {
                            Text("旋转")
                        }
                        Text("\(Int(rotation))°")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        deleteSticker()
                    } label: {
                        HStack {
                            Spacer()
                            Text("删除贴纸")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("编辑装饰")
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
                scale = sticker.scale
                rotation = sticker.rotation
            }
        }
    }
    
    private func saveChanges() {
        sticker.scale = scale
        sticker.rotation = rotation
    }
    
    private func deleteSticker() {
        modelContext.delete(sticker)
    }
}
