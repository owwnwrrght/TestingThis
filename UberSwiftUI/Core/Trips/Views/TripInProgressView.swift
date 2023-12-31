//
//  TripInProgressView.swift
//  UberSwiftUI
//
//  Created by Stephan Dowless on 11/26/21.
//

import SwiftUI

struct TripInProgressView: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    
    var body: some View {
        VStack {
            Capsule()
                .foregroundColor(Color(.systemGray5))
                .frame(width: 48, height: 6)
                .padding(8)
            
            VStack {
                if let trip = homeViewModel.trip, let user = homeViewModel.user {
                    HStack {
                        Text("En Route to destination")
                            .font(.body)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        EstimatedTimeArrivalView(time: "15")
                    }
                    .padding(.horizontal)
                    
                    Divider()
                    
                    TripInfoView(trip: trip, user: user)
                        .padding(.vertical)
                        .padding(.trailing)
                                        
                    Divider()
                }
                
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
                .padding()
                
                Spacer()
            }
        }
        .background(Color.theme.backgroundColor)
        .clipShape(RoundedShape(corners: [.topLeft, .topRight]))
        .frame(height: 320)
        .shadow(color: .black, radius: 10, x: 0, y: 0)
    }
}

struct TripInProgressView_Previews: PreviewProvider {    
    static var previews: some View {
        TripInProgressView()
            .environmentObject(dev.homeViewModel)
    }
}


