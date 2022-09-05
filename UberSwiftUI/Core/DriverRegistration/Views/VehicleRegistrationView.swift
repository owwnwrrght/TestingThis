//
//  VehicleRegistrationView.swift
//  UberSwiftUI
//
//  Created by Stephan Dowless on 9/5/22.
//

import SwiftUI

struct VehicleRegistrationView: View {
    @State private var make = ""
    @State private var model = ""
    @State private var year = ""
    @State private var licensePlate = ""
    @State private var color = ""
    @State private var type = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Your Car")
                    .font(.system(size: 36))
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                
                VStack(spacing: 32) {
                    VehicleInputField(text: $make, title: "Vehicle Make", placeholder: "Enter make..")
                    
                    VehicleInputField(text: $model, title: "Vehicle Model", placeholder: "Enter model..")
                    
                    VehicleInputField(text: $year, title: "Vehicle Year", placeholder: "2022")
                    
                    VehicleInputField(text: $licensePlate, title: "License Plate", placeholder: "G53XYC")
                    
                    VehicleInputField(text: $color, title: "Color", placeholder: "Enter color..")
                    
                    VehicleInputField(text: $type, title: "Vehicle Type", placeholder: "Select type..")

                }
                .padding()
                
                Button {
                    
                } label: {
                    Text("ADD VEHICLE")
                        .fontWeight(.bold)
                        .frame(width: UIScreen.main.bounds.width - 32, height: 50)
                        .background(.blue)
                        .cornerRadius(10)
                        .foregroundColor(.white)
                }
                .padding(.top)
            }
        }
    }
}

struct VehicleInputField: View {
    @Binding var text: String
    let title: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .fontWeight(.semibold)
                .font(.footnote)
                .opacity(0.87)
            
            TextField(placeholder, text: $text)
            
            Divider()
        }
    }
}

struct VehicleRegistrationView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VehicleRegistrationView()
        }
    }
}