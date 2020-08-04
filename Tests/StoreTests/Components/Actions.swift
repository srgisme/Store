//
//  Actions.swift
//  
//
//  Created by Scott Gorden on 7/28/20.
//

import Foundation
@testable import Store

enum AppAction: Action, Equatable {
    case auth(AuthAction)
    case counter(CounterAction)
}

enum AuthAction: Action, Equatable {
    case login(result: Result<String, TestAuthService.AuthError>)
    case logout
    case updateAuthState(AuthenticationState)
}

enum CounterAction: Action, Equatable {
    case increase
    case decrease
}
