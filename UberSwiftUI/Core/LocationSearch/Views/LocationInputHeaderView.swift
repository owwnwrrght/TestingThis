//
//  LocationInputHeaderView.swift
//  UberSwiftUI
//
//  Created by Stephan Dowless on 12/4/21.
//

import SwiftUI

struct LocationInputHeaderView: View {
    @Binding var startLocationText: String
    @Binding var destinationText: String
    
    var body: some View {
        HStack {
            VStack {
                Circle()
                    .fill(Color(.systemGray3))
                    .frame(width: 6, height: 6)
                
                Rectangle()
                    .fill(Color(.systemGray3))
                    .frame(width: 1, height: 24)
                
                Rectangle()
                    .background(Color(.black))
                    .frame(width: 6, height: 6)
            }
            .padding(.leading)
            
            VStack {
                TextField("Current Location", text: $startLocationText)
                    .frame(height: 32)
                    .background(Color.theme.secondaryBackgroundColor.opacity(0.7))
                    .padding(.trailing)
                    .disabled(true)
                
                TextField("Where to?", text: $destinationText)
                    .frame(height: 32)
                    .background(Color.theme.secondaryBackgroundColor)
                    .padding(.trailing)
            }
            .padding(.leading)
        }
        .padding(.top, 56)
    }
}
