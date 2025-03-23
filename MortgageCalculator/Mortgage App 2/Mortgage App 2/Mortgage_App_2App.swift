//
//  Mortgage_App_2App.swift
//  Mortgage App 2
//
//  Created by Esekia Perelini on 05/03/2025.
//

import SwiftUI

@main
struct Mortgage_App_2App: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
