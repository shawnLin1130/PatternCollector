import SwiftUI
import SwiftData
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - 特效滤镜工具栏
struct FilterToolbarView: View {
    @Binding var selectedFilter: FilterType
    @Binding var filterIntensity: Double
    let onApply: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Menu {
                ForEach(FilterType.allCases, id: \.self) { filter in
                    Button {
                        selectedFilter = filter
                        onApply()
                    } label: {
                        HStack {
                            Image(systemName: filter.icon)
                            Text(filter.rawValue)
                        }
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: selectedFilter.icon)
                    Text(selectedFilter.rawValue)
                }
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(selectedFilter != .none ? CuteColors.pink.opacity(0.2) : Color.gray.opacity(0.15))
                .foregroundColor(selectedFilter != .none ? CuteColors.pink : .primary)
                .clipShape(Capsule())
            }
            
            if selectedFilter != .none {
                VStack {
                    HStack {
                        Text("强度")
                            .font(.caption)
                        Slider(value: $filterIntensity, in: 0...1, step: 0.05)
                    }
                    Text("\(String(format: "%.1f", filterIntensity))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(width: 120)
            }
            
            Button {
                selectedFilter = .none
                filterIntensity = 0.5
                onApply()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}

// MARK: - 滤镜预览视图
struct FilterPreviewView: View {
    let image: UIImage?
    let filterType: FilterType
    let intensity: Double
    
    var filteredImage: UIImage? {
        guard let image = image else { return nil }
        return applyFilter(filterType, intensity: intensity, to: image)
    }
    
    var body: some View {
        ZStack {
            if let filtered = filteredImage {
                Image(uiImage: filtered)
                    .resizable()
                    .scaledToFit()
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - 滤镜应用函数（增强版）
func applyFilter(_ filterType: FilterType, intensity: Double = 0.8, to image: UIImage) -> UIImage? {
    guard let ciImage = CIImage(image: image) else { return nil }
    let context = CIContext()
    
    switch filterType {
    case .none:
        return image
        
    case .sepia:
        let sepia = CIFilter.sepiaTone()
        sepia.inputImage = ciImage
        sepia.intensity = Float(intensity)
        guard let output = sepia.outputImage else { return nil }
        let extent = output.extent
        guard let cgImage = context.createCGImage(output, from: extent) else { return nil }
        return UIImage(cgImage: cgImage)
        
    case .blur:
        let blur = CIFilter.gaussianBlur()
        blur.inputImage = ciImage
        blur.radius = Float(10 * intensity)
        guard let output = blur.outputImage else { return nil }
        let extent = output.extent
        guard let cgImage = context.createCGImage(output, from: extent) else { return nil }
        return UIImage(cgImage: cgImage)
        
    case .mono:
        let mono = CIFilter.photoEffectMono()
        mono.inputImage = ciImage
        guard let output = mono.outputImage else { return nil }
        let extent = output.extent
        guard let cgImage = context.createCGImage(output, from: extent) else { return nil }
        return UIImage(cgImage: cgImage)
        
    case .brightness:
        let brightness = CIFilter.colorControls()
        brightness.inputImage = ciImage
        brightness.brightness = Float(0.5 * intensity)
        guard let output = brightness.outputImage else { return nil }
        let extent = output.extent
        guard let cgImage = context.createCGImage(output, from: extent) else { return nil }
        return UIImage(cgImage: cgImage)
        
    case .contrast:
        let contrast = CIFilter.colorControls()
        contrast.inputImage = ciImage
        contrast.contrast = Float(1.2 + 0.8 * intensity)
        guard let output = contrast.outputImage else { return nil }
        let extent = output.extent
        guard let cgImage = context.createCGImage(output, from: extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - 滤镜设置Sheet
struct FilterSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedFilter: FilterType
    @Binding var filterIntensity: Double
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("滤镜效果")
                    .font(.title2)
                    .fontWeight(.bold)
                
                FilterPreviewView(
                    image: UIImage(systemName: "photo.fill") ?? UIImage(),
                    filterType: selectedFilter,
                    intensity: filterIntensity
                )
                .frame(height: 200)
                
                Form {
                    FilterToolbarView(
                        selectedFilter: $selectedFilter,
                        filterIntensity: $filterIntensity,
                        onApply: {}
                    )
                }
            }
            .padding()
            .navigationTitle("滤镜设置")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("应用") { dismiss() }
                }
            }
        }
    }
}
