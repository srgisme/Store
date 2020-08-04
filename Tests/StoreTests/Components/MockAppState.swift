//
//  MockAppState.swift
//  
//
//  Created by Scott Gorden on 4/24/20.
//

import Foundation

struct AppState: Equatable {
    var counterState = CounterState()
    var authenticationState = AuthenticationState.unauthenticated
}

struct CounterState: Equatable {
    var counter = 0
}

enum AuthenticationState: Equatable {
    case authenticated(String)
    case unauthenticated
}
