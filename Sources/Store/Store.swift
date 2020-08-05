import Foundation
import Combine
import SwiftUI

public typealias StateChange<State> = AnyPublisher<(inout State) -> Void, Never>
public typealias Reducer<State, Environment> = (Action, Environment) -> StateChange<State>

public final class Store<State, Environment>: ObservableObject {
    @Published public private(set) var state: State

    private let environment: Environment
    private let reducer: Reducer<State, Environment>
    private var stateChangeCancellables: Set<AnyCancellable> = []

    public init(initialState: State, reducer: @escaping Reducer<State, Environment>, environment: Environment) {
        self.state = initialState
        self.reducer = reducer
        self.environment = environment
    }

    public func send(_ action: Action, _ animation: Animation = .default) {
        send(action.normalized, animation)
    }

    private func send(_ actions: [Action], _ animation: Animation = .default) {
        serializedStateChanges(actions.normalized)
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] stateChange in withAnimation(animation) { stateChange(&self.state) } }
            .store(in: &stateChangeCancellables)
    }

    private func serializedStateChanges(_ actions: [Action]) -> StateChange<State> {
        let normalizedActions = actions.normalized
        guard let firstAction = normalizedActions.first else {
            return Empty(completeImmediately: true)
                .eraseToAnyPublisher()
        }

        return normalizedActions.dropFirst().reduce(into: reducer(firstAction, environment)) { [unowned self] in $0 = $0.append(self.reducer($1, self.environment)).eraseToAnyPublisher() }
    }

    public var actionDispatcher: ActionDispatcher {
        .init { [weak self] in self?.send($0, $1) }
    }
}

public final class ActionDispatcher: ObservableObject {
    public let send: (_ action: Action, _ animation: Animation) -> Void

    public init(send: @escaping (_ action: Action, _ animation: Animation) -> Void) {
        self.send = send
    }
}
