import SwiftUI
import SwiftData
import UIKit
import PDFKit

// MARK: - 导出视图
struct ExportView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var book: JournalBook?
    
    @State private var exportFormat: ExportFormat = .pdf
    @State private var exportScope: ExportScope = .allPages
    @State private var selectedPageIndex: Int = 0
    @State private var isExporting = false
    @State private var exportedImage: UIImage?
    @State private var showingShareSheet = false
    @State private var showingSaveAlert = false
    @State private var saveSuccess = false
    
    enum ExportFormat: String, CaseIterable {
        case pdf = "PDF"
        case image = "图片"
        
        var icon: String {
            switch self {
            case .pdf: return "doc.richtext"
            case .image: return "photo"
            }
        }
    }
    
    enum ExportScope: String, CaseIterable {
        case allPages = "整本手帐"
        case singlePage = "单页"
    }
    
    var sortedPages: [JournalPage] {
        book?.pages.sorted(by: { $0.pageNumber < $1.pageNumber }) ?? []
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // 格式选择
                VStack(alignment: .leading, spacing: 12) {
                    Text("导出格式")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    HStack(spacing: 16) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Button {
                                exportFormat = format
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: format.icon)
                                        .font(.title)
                                    
                                    Text(format.rawValue)
                                        .font(.subheadline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(exportFormat == format ? CuteColors.pink.opacity(0.15) : Color.gray.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(exportFormat == format ? CuteColors.pink : .clear, lineWidth: 2)
                                )
                            }
                            .foregroundColor(exportFormat == format ? CuteColors.pink : .primary)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // 范围选择
                if exportFormat == .image {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("导出范围")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Picker("范围", selection: $exportScope) {
                            ForEach(ExportScope.allCases, id: \.self) { scope in
                                Text(scope.rawValue).tag(scope)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        
                        if exportScope == .singlePage && !sortedPages.isEmpty {
                            // 页码选择
                            VStack(alignment: .leading, spacing: 8) {
                                Text("选择页面")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(Array(sortedPages.enumerated()), id: \.element.id) { index, page in
                                            Button {
                                                selectedPageIndex = index
                                            } label: {
                                                VStack {
                                                    Text("第 \(page.pageNumber) 页")
                                                        .font(.caption)
                                                }
                                                .frame(width: 60, height: 40)
                                                .background(selectedPageIndex == index ? CuteColors.pink : Color.gray.opacity(0.15))
                                                .foregroundColor(selectedPageIndex == index ? .white : .primary)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                }
                
                // 预览
                if exportFormat == .image {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("预览")
                            .font(.headline)
                        
                        if !sortedPages.isEmpty {
                            let page = sortedPages[selectedPageIndex]
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: page.backgroundColor) ?? Color(hex: "#FFF8F0")!)
                                .frame(height: 200)
                                .overlay(
                                    Text("第 \(page.pageNumber) 页预览")
                                        .foregroundColor(.secondary)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .shadow(radius: 2)
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // 导出按钮
                Button {
                    performExport()
                } label: {
                    HStack {
                        if isExporting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "square.and.arrow.up")
                            Text("导出\(exportFormat.rawValue)")
                        }
                    }
                    .font(.headline)
                    .fontDesign(.rounded)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [CuteColors.pink, Color(hex: "#FF69B4")!],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .pink.opacity(0.4), radius: 8)
                }
                .disabled(sortedPages.isEmpty || isExporting)
                .padding()
            }
            .padding(.top)
            .navigationTitle("导出\(book?.name ?? "手帐")")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let image = exportedImage {
                    ShareSheet(activityItems: [image])
                }
            }
            .alert(saveSuccess ? "导出成功" : "导出失败", isPresented: $showingSaveAlert) {
                Button("确定") {
                    dismiss()
                }
            }
        }
    }
    
    private func performExport() {
        isExporting = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            switch exportFormat {
            case .pdf:
                exportPDF()
            case .image:
                exportImage()
            }
            isExporting = false
        }
    }
    
    private func exportPDF() {
        guard let book = book, !sortedPages.isEmpty else { return }
        
        // 创建PDF
        let pdfMetaData = [
            kCGPDFContextCreator: "Pattern Collector",
            kCGPDFContextAuthor: "Pattern Collector User",
            kCGPDFContextTitle: book.name
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth: CGFloat = 612  // A4尺寸
        let pageHeight: CGFloat = 792
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            for page in sortedPages {
                context.beginPage()
                
                // 绘制背景
                let bgColor = UIColor(Color(hex: page.backgroundColor) ?? Color(hex: "#FFF8F0")!)
                bgColor.setFill()
                pageRect.fill()
                
                // 绘制元素
                drawPageElements(page, in: pageRect)
            }
        }
        
        // 分享PDF
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(book.name).pdf")
        try? data.write(to: tempURL)
        
        exportedImage = UIImage(data: data)
        showingShareSheet = true
    }
    
    private func exportImage() {
        guard !sortedPages.isEmpty else { return }
        
        let page: JournalPage
        if exportScope == .allPages {
            // 导出第一页作为预览
            page = sortedPages[0]
        } else {
            page = sortedPages[selectedPageIndex]
        }
        
        // 创建页面图片
        let size = CGSize(width: 800, height: 600)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { ctx in
            // 背景
            let bgColor = UIColor(Color(hex: page.backgroundColor) ?? Color(hex: "#FFF8F0")!)
            bgColor.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            
            // 元素
            drawPageElementsForImage(page, in: CGRect(origin: .zero, size: size))
        }
        
        exportedImage = image
        showingShareSheet = true
    }
    
    private func drawPageElements(_ page: JournalPage, in rect: CGRect) {
        let scale: CGFloat = min(rect.width / 400, rect.height / 600)
        
        for element in page.elements {
            if let imageData = element.patternImageData,
               let uiImage = UIImage(data: imageData) {
                let drawRect = CGRect(
                    x: element.x * scale,
                    y: element.y * scale,
                    width: element.width * scale,
                    height: element.height * scale
                )
                
                ctx_saveGState(UIGraphicsGetCurrentContext())
                ctx_translateCTM(UIGraphicsGetCurrentContext(), drawRect.midX, drawRect.midY)
                ctx_rotateCTM(UIGraphicsGetCurrentContext(), element.rotation * .pi / 180)
                ctx_translateCTM(UIGraphicsGetCurrentContext(), -drawRect.midX, -drawRect.midY)
                
                uiImage.draw(in: drawRect)
                
                ctx_restoreGState(UIGraphicsGetCurrentContext())
            }
        }
    }
    
    private func drawPageElementsForImage(_ page: JournalPage, in rect: CGRect) {
        let scale: CGFloat = min(rect.width / 400, rect.height / 600)
        
        for element in page.elements {
            if let imageData = element.patternImageData,
               let uiImage = UIImage(data: imageData) {
                let drawRect = CGRect(
                    x: element.x * scale,
                    y: element.y * scale,
                    width: element.width * scale,
                    height: element.height * scale
                )
                
                uiImage.draw(in: drawRect)
            }
        }
    }
}

// Core Graphics helpers
private func ctx_saveGState(_ context: CGContext?) {
    context?.saveGState()
}

private func ctx_restoreGState(_ context: CGContext?) {
    context?.restoreGState()
}

private func ctx_translateCTM(_ context: CGContext?, _ tx: CGFloat, _ ty: CGFloat) {
    context?.translateBy(x: tx, y: ty)
}

private func ctx_rotateCTM(_ context: CGContext?, _ angle: CGFloat) {
    context?.rotate(by: angle)
}

// MARK: - 打印视图
struct PrintView: View {
    let book: JournalBook?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "printer.fill")
                    .font(.system(size: 60))
                    .foregroundColor(CuteColors.pink)
                
                Text("打印功能")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("连接打印机后可打印手帐内容")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                Button {
                    printBook()
                } label: {
                    Text("开始打印")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(CuteColors.pink)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding()
            }
            .navigationTitle("打印")
        }
    }
    
    private func printBook() {
        guard let book = book, let printController = UIHostingController(rootView: PrintPageView(book: book)) else { return }
        
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.outputType = .general
        printInfo.jobName = book.name
        
        let printController2 = UIPrintInteractionController.shared
        printController2.printInfo = printInfo
        printController2.printingItem = nil
    }
}

struct PrintPageView: View {
    let book: JournalBook
    
    var body: some View {
        ForEach(book.pages.sorted(by: { $0.pageNumber < $1.pageNumber })) { page in
            Text("Page \(page.pageNumber)")
                .frame(width: 612, height: 792)
        }
    }
}
