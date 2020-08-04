import Foundation
import Combine

public typealias StateChange<State, Environment> = AnyPublisher<(inout State) -> Void, Never>
public typealias Reducer<State, Environment> = (Action, Environment) -> StateChange<State, Environment>

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

    public func send(_ action: Action) {
        send(action.normalized)
    }

    private func send(_ actions: [Action]) {
        serializedStateChanges(actions.normalized)
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] in $0(&self.state) }
            .store(in: &stateChangeCancellables)
    }

    private func serializedStateChanges(_ actions: [Action]) -> StateChange<State, Environment> {
        let normalizedActions = actions.normalized
        guard let firstAction = normalizedActions.first else {
            return Empty(completeImmediately: true)
                .eraseToAnyPublisher()
        }

        return normalizedActions.dropFirst().reduce(into: reducer(firstAction, environment)) { [unowned self] in $0 = $0.append(self.reducer($1, self.environment)).eraseToAnyPublisher() }
    }
}
