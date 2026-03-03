import SwiftUI

struct PatternDecorator: View {
    @State private var selectedCornerRadii: CGFloat = 10
    @State private var labelPosition: String = "Center"
    @State private var textColor: Color = .blue
    
    var body: some View {
        VStack {
            Form {
                Section(header: Text("Border Style")) {
                    Slider(value: $selectedCornerRadii, in: 0...50, step: 1)
                        .padding(.horizontal)
                        .overlay(HStack {
                            Text("0")
                            Spacer()
                            Text("50")
                        })
                    Text("CornerRadius: \(Int(selectedCornerRadii))")
                }
                
                Section(header: Text("Label Position")) {
                    Picker("Position", selection: $labelPosition) {
                        Text("Top").tag("Top")
                        Text("Center").tag("Center")
                        Text("Bottom").tag("Bottom")
                    }
                }
                
                Section(header: Text("Text Color")) {
                    ColorPicker("Select Color", selection: $textColor)
                }
            }
            
            ZStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 200, height: 200)
                    .cornerRadius(selectedCornerRadii)
                    .overlay(
                        RoundedRectangle(cornerRadius: selectedCornerRadii)
                            .stroke(Color.black, lineWidth: 2)
                    )
                
                if labelPosition == "Top" {
                    Text("Pattern")
                        .foregroundColor(textColor)
                        .padding(.top)
                } else if labelPosition == "Bottom" {
                    Text("Pattern")
                        .foregroundColor(textColor)
                        .padding(.bottom)
                } else {
                    Text("Pattern")
                        .foregroundColor(textColor)
                }
            }
            .padding()
        }
    }
}
