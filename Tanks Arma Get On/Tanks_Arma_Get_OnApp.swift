//
//  Tanks_Arma_Get_OnApp.swift
//  Tanks Arma Get On
//
//  Created by Antonio Loggia on 02.09.24.
//

import SwiftUI

@main
struct Tanks_Arma_Get_OnApp: App {
    // Core Data Persistence Controller
    let persistenceController = PersistenceController.shared
    var body: some Scene {
        WindowGroup {
            StartView()
                .environment( \.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
 
