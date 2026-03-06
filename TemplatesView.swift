import SwiftUI
import SwiftData

// MARK: - 主题模板视图
struct TemplatesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalTemplate.name) private var templates: [JournalTemplate]
    
    @State private var selectedCategory: TemplateCategory = .blank
    @State private var selectedTemplate: JournalTemplate?
    @State private var showingPreview = false
    @State private var showingApplyAlert = false
    
    var filteredTemplates: [JournalTemplate] {
        if selectedCategory == .blank {
            return templates
        }
        return templates.filter { $0.category == selectedCategory.rawValue }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "#FFF0F5").opacity(0.6), Color(hex: "#E0F2FE").opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 分类筛选
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(TemplateCategory.allCases, id: \.self) { category in
                                Button {
                                    selectedCategory = category
                                } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: category.icon)
                                            .font(.title3)
                                            .foregroundColor(selectedCategory == category ? .white : .primary)
                                        
                                        Text(category.rawValue)
                                            .font(.caption)
                                            .foregroundColor(selectedCategory == category ? .white : .primary)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(
                                        selectedCategory == category ?
                                        LinearGradient(colors: [CuteColors.pink, Color.pink.opacity(0.8)], startPoint: .leading, endPoint: .trailing) :
                                        Color.gray.opacity(0.15)
                                    )
                                    .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                    
                    // 模板网格
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ], spacing: 16) {
                            if filteredTemplates.isEmpty {
                                // 空状态
                                VStack(spacing: 16) {
                                    Image(systemName: "rectangle.stack.badge.plus")
                                        .font(.system(size: 50))
                                        .foregroundColor(CuteColors.lavender.opacity(0.6))
                                    
                                    Text("还没有模板～")
                                        .font(.title3)
                                        .foregroundColor(.secondary)
                                    
                                    Text("使用预设模板开始创作吧！")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxHeight: .infinity)
                            } else {
                                ForEach(filteredTemplates) { template in
                                    TemplateCard(template: template)
                                        .onTapGesture {
                                            selectedTemplate = template
                                            showingPreview = true
                                        }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("主题模板 🎨")
            .sheet(isPresented: $showingPreview) {
                if let template = selectedTemplate {
                    TemplatePreviewView(template: template) {
                        selectedTemplate = nil
                    } onApply: {
                        selectedTemplate = nil
                        showingApplyAlert = true
                    }
                }
            }
            .alert("应用模板？", isPresented: $showingApplyAlert) {
                Button("取消", role: .cancel) { }
                Button("应用到新页面") {
                    // 应用逻辑由调用方处理
                }
            } message: {
                Text("模板将被应用到当前或新页面")
            }
        }
        .onAppear {
            initializePresetTemplates()
        }
    }
    
    private func initializePresetTemplates() {
        guard templates.isEmpty else { return }
        
        for preset in presetTemplates {
            let template = JournalTemplate(
                name: preset.name,
                category: preset.category,
                backgroundColor: preset.color,
                isDefault: false
            )
            modelContext.insert(template)
        }
    }
}

// MARK: - 模板卡片
struct TemplateCard: View {
    let template: JournalTemplate
    
    var body: some View {
        VStack(spacing: 12) {
            // 预览背景
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: template.backgroundColor) ?? Color(hex: "#FFF8F0")!)
                .frame(height: 120)
                .overlay(
                    VStack {
                        Image(systemName: "magic")
                            .font(.title)
                            .foregroundColor(CuteColors.pink.opacity(0.6))
                        
                        Text("预览")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(CuteColors.pink.opacity(0.3), lineWidth: 1)
                )
            
            VStack(spacing: 4) {
                Text(template.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(template.category)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .pink.opacity(0.2), radius: 4)
    }
}

// MARK: - 模板预览视图
struct TemplatePreviewView: View {
    let template: JournalTemplate
    let onDismiss: () -> Void
    let onApply: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: template.backgroundColor)?.opacity(0.9).ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text(template.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("分类: \(template.category)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // 模板预览区域
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.9))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .overlay(
                            VStack(spacing: 20) {
                                Image(systemName: "rectangle.grid.2x2")
                                    .font(.system(size: 50))
                                    .foregroundColor(CuteColors.pink.opacity(0.5))
                                
                                VStack(spacing: 8) {
                                    Text("预设布局")
                                        .font(.headline)
                                    
                                    Text("• 背景颜色: \(template.backgroundColor)")
                                        .font(.caption)
                                    
                                    Text("• 元素位置已优化")
                                        .font(.caption)
                                }
                            }
                        )
                        .padding()
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("模板预览")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        onDismiss()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("应用模板") {
                        onApply()
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
    }
}
