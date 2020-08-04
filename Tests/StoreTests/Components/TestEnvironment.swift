//
//  TestEnvironment.swift
//  
//
//  Created by Scott Gorden on 7/28/20.
//

import Foundation
import Combine

final class TestEnvironment {
    let authService = TestAuthService()
}

final class TestAuthService {
    enum AuthError: Error {
        case someFailure
    }

    func login(result: Result<String, AuthError>) -> AnyPublisher<String, AuthError> {
        result
            .publisher
            .delay(for: .seconds(1), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func logout() -> AnyPublisher<Bool, AuthError> {
        return Just(true)
            .mapError { _ in AuthError.someFailure }
            .delay(for: .seconds(1), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
