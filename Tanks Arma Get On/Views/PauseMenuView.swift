//
//  PauseView.swift
//  Tanks Arma Get On
//
//  Created by Antonio Loggia on 11.10.24.
//

import SwiftUI

struct PauseMenuView: View {
    @Binding var isPaused: Bool // Binding to track if the game is paused
    @Environment(\.presentationMode) var presentationMode // For navigation control
    
    var body: some View {
        VStack {
            Text("PAUSED")
                .font(.largeTitle)
                .padding(.bottom, 40)
            
            // Resume Button
            Button(action: {
                // Action to resume the game
                isPaused = false
            }) {
                Text("Resume")
                    .font(.title)
                    .padding()
                    .frame(width: 200)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.bottom, 20)
            
            // Exit Button
            NavigationLink(destination: SelectScreenView()) {
                Text("Exit")
                    .font(.title)
                    .padding()
                    .frame(width: 200)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.5))
        .edgesIgnoringSafeArea(.all)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
