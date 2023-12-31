//
//  DriverArrivalView.swift
//  UberSwiftUI
//
//  Created by Stephan Dowless on 9/4/22.
//

import SwiftUI

struct DriverArrivalView: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    
    var body: some View {
        VStack(alignment: .center) {
            Capsule()
                .foregroundColor(Color(.systemGray5))
                .frame(width: 48, height: 6)
                .padding(8)
            
            VStack {
                Text("YOUR DRIVER IS HERE")
                    .fontWeight(.bold)
                    .font(.system(size: 14))
                
                Text("Please check your driver's license \n plate and ensure you have the correct ride")
                    .font(.subheadline)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(height: 44)
            }
            
            Divider()
            
            HStack {
                if let trip = homeViewModel.trip {
                    UserImageAndDetailsView(imageUrl: trip.driverImageUrl, username: trip.driverFirstNameUppercased)
                    
                    Spacer()
                    
                    DriverVehicleInfoView()
                }
            }
            .padding(.horizontal)
            
            Divider()
            
            VStack(alignment: .leading) {
                Text("TRIP")
                    .fontWeight(.semibold)
                    .font(.body)
                
                TripLocationsView()
            }
            .padding()
            
            Button {
                homeViewModel.cancelTrip()
            } label: {
                Text("CANCEL TRIP")
                    .fontWeight(.bold)
                    .frame(width: UIScreen.main.bounds.width - 64, height: 50)
                    .background(Color(.systemRed))
                    .cornerRadius(10)
                    .foregroundColor(.white)
            }
            .padding(.bottom, 24)
            .padding()
            
            Spacer()
        }
        .background(Color.theme.backgroundColor)
        .clipShape(RoundedShape(corners: [.topLeft, .topRight]))
        .frame(height: 450)
        .shadow(color: .black, radius: 10, x: 0, y: 0)
    }
}

struct DriverArrivalView_Previews: PreviewProvider {
    static var previews: some View {
        DriverArrivalView()
            .environmentObject(dev.homeViewModel)
    }
}
