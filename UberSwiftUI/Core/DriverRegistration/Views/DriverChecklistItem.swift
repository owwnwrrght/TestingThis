//
//  DriverChecklistItem.swift
//  UberSwiftUI
//
//  Created by Stephan Dowless on 9/8/22.
//

import SwiftUI

struct DriverChecklistItem: View {
    let imageName: String
    let title: String
    @Binding var isComplete: Bool
    
    var body: some View {
        ZStack {
            HStack {
                Image(systemName: imageName)
                    .font(.title)
                    .imageScale(.small)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Get started")
                    
                    Text(title)
                        .font(.system(size: 18))
                        .fontWeight(.semibold)
                }
                .padding(.leading)
                
                Spacer()
                
                Image(systemName: "\(isComplete ? "checkmark" : "chevron.forward").circle.fill")
                    .font(.title)
                    .imageScale(.small)
                    .foregroundColor(isComplete ? .green : Color.theme.primaryTextColor)
            }
            .foregroundColor(Color.theme.primaryTextColor)
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.theme.secondaryBackgroundColor))
        }
    }
}

struct DriverChecklistItem_Previews: PreviewProvider {
    static var previews: some View {
        DriverChecklistItem(imageName: "car.circle.fill", title: "Add your vehicle", isComplete: .constant(false))
    }
}
