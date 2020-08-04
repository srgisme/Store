//
//  AuthReducer.swift
//  
//
//  Created by Scott Gorden on 4/25/20.
//

import Combine
import Foundation
@testable import Store

let appReducer: Reducer<AppState, TestEnvironment> = { action, environment in
    switch action {
    case let authAction as AuthAction:
        return authReducer(authAction, environment.authService)
    case let counterAction as CounterAction:
        return counterReducer(counterAction, environment)
    default:
        return Just { _ in }
            .eraseToAnyPublisher()
    }
}

let authReducer: Reducer<AppState, TestAuthService> = { action, authService in
    switch action as? AuthAction {
    case .login(let result):
        return authService.login(result: result)
            .map { token in
                { state in
                    state.authenticationState = .authenticated(token)
                }
            }
            .catch { _ in
                Just { state in
                    state.authenticationState = .unauthenticated
                }.eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()

    case .logout:
        return authService.logout()
            .map { _ in
                { state in
                    state.authenticationState = .unauthenticated
                }
            }
            .catch { _ in
                Just { _ in }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()

    default:
        return Just { _ in }
            .eraseToAnyPublisher()
    }
}

let counterReducer: Reducer<AppState, TestEnvironment> = { action, _ in
    switch action as? CounterAction {
    case .increase:
        return Just { state in
            state.counterState.counter += 1
        }.eraseToAnyPublisher()

    case .decrease:
        return Just { state in
            state.counterState.counter -= 1
        }.eraseToAnyPublisher()

    default:
        return Just { _ in }
            .eraseToAnyPublisher()
    }
}
