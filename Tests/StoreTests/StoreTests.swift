import XCTest
@testable import Store

final class StoreTests: XCTestCase {
    func testActionDispatcher() {
        let store = Store<AppState, TestEnvironment>(initialState: .init(), reducer: appReducer, environment: .init())
        let expectation = XCTestExpectation()
        let cancellable = store.$state
            .dropFirst()
            .map(\.counterState.counter)
            .sink {
                XCTAssertEqual($0, 1)
                expectation.fulfill()
            }
        store.actionDispatcher.send(CounterAction.increase, .default)
        wait(for: [expectation], timeout: 5)
        cancellable.cancel()
    }
    func testCounterReducer() {
        let store = Store<AppState, TestEnvironment>(initialState: .init(), reducer: appReducer, environment: .init())
        let expectation = XCTestExpectation()
        let cancellable = store.$state
            .dropFirst()
            .map(\.counterState.counter)
            .sink {
                XCTAssertEqual($0, 1)
                expectation.fulfill()
            }
        store.send(CounterAction.increase)
        wait(for: [expectation], timeout: 5)
        cancellable.cancel()
    }

    func testAuthReducer() {
        let store = Store<AppState, TestEnvironment>(initialState: .init(), reducer: appReducer, environment: .init())
        let testToken = "testToken123"
        let expectation = XCTestExpectation()
        let cancellable = store.$state
            .dropFirst()
            .map(\.authenticationState)
            .sink(receiveValue: {
                XCTAssertEqual($0, .authenticated(testToken))
                expectation.fulfill()
            })
        store.send(AuthAction.login(result: .success(testToken)))
        wait(for: [expectation], timeout: 5)
        cancellable.cancel()
    }

    func testFlattenedActionSequence() {
        let actionSequence = AuthAction.login(result: .success(""))
            .then(CounterAction.decrease)
            .then(AuthAction.logout)
            .then(CounterAction.increase)
        let normalizedActions = actionSequence.normalized
        XCTAssertEqual(normalizedActions.count, 4)
        XCTAssertEqual(normalizedActions[0] as? AuthAction, .login(result: .success("")))
        XCTAssertEqual(normalizedActions[1] as? CounterAction, .decrease)
        XCTAssertEqual(normalizedActions[2] as? AuthAction, .logout)
        XCTAssertEqual(normalizedActions[3] as? CounterAction, .increase)
    }

    func testEmbeddedActions() {
        let actionSequence = AuthAction.login(result: .success(""))
            .then(CounterAction.decrease)
        let otherActionSequence = CounterAction.increase
            .then(CounterAction.increase.then(AuthAction.logout))
        let someOtherActionSequence = CounterAction.decrease
            .then(AuthAction.login(result: .success("")).then(otherActionSequence.then(actionSequence)))
            .then(CounterAction.increase)
        let normalizedActions = someOtherActionSequence.normalized

        XCTAssertEqual(normalizedActions.count, 8)
        XCTAssertEqual(normalizedActions[0] as? CounterAction, .decrease)
        XCTAssertEqual(normalizedActions[1] as? AuthAction, .login(result: .success("")))
        XCTAssertEqual(normalizedActions[2] as? CounterAction, .increase)
        XCTAssertEqual(normalizedActions[3] as? CounterAction, .increase)
        XCTAssertEqual(normalizedActions[4] as? AuthAction, .logout)
        XCTAssertEqual(normalizedActions[5] as? AuthAction, .login(result: .success("")))
        XCTAssertEqual(normalizedActions[6] as? CounterAction, .decrease)
        XCTAssertEqual(normalizedActions[7] as? CounterAction, .increase)
    }

    func testFlattenedActionsStateChanges() {
        let store = Store(initialState: AppState(), reducer: appReducer, environment: TestEnvironment())
        let testToken = "testToken123"
        let expectation = XCTestExpectation()
        let cancellable = store.$state
            .removeDuplicates()
            .collect(6)
            .sink {
                XCTAssertEqual($0, [
                    AppState(),
                    AppState(counterState: .init(counter: 0), authenticationState: .authenticated(testToken)),
                    AppState(counterState: .init(counter: 1), authenticationState: .authenticated(testToken)),
                    AppState(counterState: .init(counter: 1), authenticationState: .unauthenticated),
                    AppState(counterState: .init(counter: 1), authenticationState: .authenticated(testToken)),
                    AppState(counterState: .init(counter: 0), authenticationState: .authenticated(testToken))
                ])
                expectation.fulfill()
            }

        let actionSequence = AuthAction.login(result: .success(testToken))
            .then(CounterAction.increase)
            .then(AuthAction.logout)
            .then(AuthAction.login(result: .success(testToken)))
            .then(CounterAction.decrease)

        store.send(actionSequence)
        wait(for: [expectation], timeout: 15)
        cancellable.cancel()
    }

    func testEmbeddedActionsStateChanges() {
        let store = Store(initialState: AppState(), reducer: appReducer, environment: TestEnvironment())
        let expectation = XCTestExpectation()
        let cancellable = store.$state
            .removeDuplicates()
            .collect(9)
            .sink {
                XCTAssertEqual($0, [
                    AppState(),
                    AppState(counterState: .init(counter: -1), authenticationState: .unauthenticated),
                    AppState(counterState: .init(counter: -1), authenticationState: .authenticated("")),
                    AppState(counterState: .init(counter: 0), authenticationState: .authenticated("")),
                    AppState(counterState: .init(counter: 1), authenticationState: .authenticated("")),
                    AppState(counterState: .init(counter: 1), authenticationState: .unauthenticated),
                    AppState(counterState: .init(counter: 1), authenticationState: .authenticated("")),
                    AppState(counterState: .init(counter: 0), authenticationState: .authenticated("")),
                    AppState(counterState: .init(counter: 1), authenticationState: .authenticated(""))
                ])
                expectation.fulfill()
            }

        let actionSequence = AuthAction.login(result: .success(""))
            .then(CounterAction.decrease)
        let otherActionSequence = CounterAction.increase
            .then(CounterAction.increase.then(AuthAction.logout))
        let someOtherActionSequence = CounterAction.decrease
            .then(AuthAction.login(result: .success("")).then(otherActionSequence.then(actionSequence)))
            .then(CounterAction.increase)

        store.send(someOtherActionSequence)
        wait(for: [expectation], timeout: 15)
        cancellable.cancel()
    }

    static var allTests = [
        ("testCounterReducer", testCounterReducer),
        ("testAuthReducer", testAuthReducer),
        ("testFlattenedActionSequence", testFlattenedActionSequence),
        ("testEmbeddedActions", testEmbeddedActions),
        ("testFlattenedActionsStateChanges", testFlattenedActionsStateChanges),
        ("testEmbeddedActionsStateChanges", testEmbeddedActionsStateChanges)
    ]
}
