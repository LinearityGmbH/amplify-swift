//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Combine
import XCTest

@testable import Amplify
import AWSPluginsCore

extension GraphQLLazyLoadCompositePKTests {

    // MARK: - CompositePKParent / CompositePKChild
    
    func initChild(with parent: CompositePKParent? = nil) -> CompositePKChild {
        CompositePKChild(childId: UUID().uuidString, content: "content", parent: parent)
    }
    
    func testSaveCompositePKChild() async throws {
        await setup(withModels: CompositePKModels())
        
        let parent = initParent()
        let savedParent = try await mutate(.create(parent))
        let child = initChild(with: savedParent)
        try await mutate(.create(child))
    }
    
    func testUpdateCompositePKChild() async throws {
        await setup(withModels: CompositePKModels())
        let parent = initParent()
        let savedParent = try await mutate(.create(parent))
        let child = initChild(with: parent)
        var savedChild = try await mutate(.create(child))
        let loadedParent = try await savedChild.parent
        XCTAssertEqual(loadedParent?.identifier, savedParent.identifier)
        
        // update the child to a new parent
        let newParent = initParent()
        let savedNewParent = try await mutate(.create(newParent))
        savedChild.setParent(savedNewParent)
        let updatedChild = try await mutate(.update(savedChild))
        let loadedNewParent = try await updatedChild.parent
        XCTAssertEqual(loadedNewParent?.identifier, savedNewParent.identifier)
    }
    
    func testUpdateFromNoParentCompositePKChild() async throws {
        await setup(withModels: CompositePKModels())
        let parent = initParent()
        let savedParent = try await mutate(.create(parent))
        
        let childWithoutParent = initChild()
        var savedChild = try await mutate(.create(childWithoutParent))
        let nilParent = try await savedChild.parent
        XCTAssertNil(nilParent)
        
        // update the child to a parent
        savedChild.setParent(savedParent)
        let savedChildWithParent = try await mutate(.update(savedChild))
        let loadedParent = try await savedChildWithParent.parent
        XCTAssertEqual(loadedParent?.identifier, savedParent.identifier)
    }
    
    func testDeleteCompositePKChild() async throws {
        await setup(withModels: CompositePKModels())
        let parent = initParent()
        let savedParent = try await mutate(.create(parent))
        let child = initChild(with: parent)
        let savedChild = try await mutate(.create(child))
        
        try await mutate(.delete(savedParent))
        try await assertModelDoesNotExist(savedParent)
        try await mutate(.delete(savedChild))
        try await assertModelDoesNotExist(savedChild)
    }
    
    func testGetCompositePKChild() async throws {
        await setup(withModels: CompositePKModels())

        let parent = initParent()
        let savedParent = try await mutate(.create(parent))
        let child = initChild(with: parent)
        let savedCompositePKChild = try await mutate(.create(child))

        // query parent and load the children
        let queriedParent = try await query(.get(CompositePKParent.self,
                                                 byIdentifier: .identifier(customId: savedParent.customId,
                                                                           content: savedParent.content)))!
        assertList(queriedParent.children!, state: .isNotLoaded(associatedIdentifiers: [queriedParent.customId,
                                                                                        queriedParent.content],
                                                                associatedFields: ["parent"]))
        try await queriedParent.children?.fetch()
        assertList(queriedParent.children!, state: .isLoaded(count: 1))

        // query child and load the parent - CompositePKChild
        let queriedCompositePKChild = try await query(.get(CompositePKChild.self,
                                                           byIdentifier: .identifier(childId: savedCompositePKChild.childId,
                                                                                     content: savedCompositePKChild.content)))!
        assertLazyReference(queriedCompositePKChild._parent,
                            state: .notLoaded(identifiers: [.init(name: "customId", value: savedParent.customId),
                                                            .init(name: "content", value: savedParent.content)]))
        let loadedParent = try await queriedCompositePKChild.parent
        assertLazyReference(queriedCompositePKChild._parent,
                            state: .loaded(model: loadedParent))
    }

    func testListCompositePKChild() async throws {
        await setup(withModels: CompositePKModels())
        let parent = initParent()
        let savedParent = try await mutate(.create(parent))
        let child = initChild(with: savedParent)
        try await mutate(.create(child))

        var queriedChild = try await listQuery(.list(CompositePKChild.self,
                                                     where: CompositePKChild.keys.childId == child.childId))
        while queriedChild.hasNextPage() {
            queriedChild = try await queriedChild.getNextPage()
        }
        assertList(queriedChild, state: .isLoaded(count: 1))
    }

    /*
     - Given: Api category setup with CompositePKModels
     - When:
        - Subscribe onCreate events of CompositePKChild
        - Create new CompositePKChild instance with API
     - Then:
        - the newly created instance is successfully created through API. onCreate event is received.
     */
    func testSubscribeCompositePKChildOnCreate() async throws {
        await setup(withModels: CompositePKModels())
        let connected = asyncExpectation(description: "Subscription connected")
        let onCreate = asyncExpectation(description: "onCreate received")
        let child = CompositePKChild(childId: UUID().uuidString, content: UUID().uuidString)
        let subscription = Amplify.API.subscribe(request: .subscription(of: CompositePKChild.self, type: .onCreate))
        Task {
            do {
                for try await subscriptionEvent in subscription {
                    switch subscriptionEvent {
                    case .connection(.connected):
                        await connected.fulfill()
                    case let .data(.success(newModel)):
                        if newModel.identifier == child.identifier {
                            await onCreate.fulfill()
                        }
                    case let .data(.failure(error)):
                        XCTFail("Failed to create CompositePKChild, error: \(error.errorDescription)")
                    default: ()
                    }
                }
            }
        }

        await waitForExpectations([connected], timeout: 10)
        try await mutate(.create(child))
        await waitForExpectations([onCreate], timeout: 10)
        subscription.cancel()
    }

    /*
     - Given: Api category setup with CompositePKModels
     - When:
        - Subscribe onCreate events of CompositePKChild
        - Create new CompositePKChild instance with API
        - Create new CompositePKParent instance with API
        - Update newly created CompositePKParent instance with API
     - Then:
        - the newly created instance is successfully updated through API. onUpdate event is received.
     */
    func testSubscribeCompositePKChildOnUpdate() async throws {
        await setup(withModels: CompositePKModels())
        let connected = asyncExpectation(description: "Subscription connected")
        let onUpdate = asyncExpectation(description: "onUpdate received")
        let child = CompositePKChild(childId: UUID().uuidString, content: UUID().uuidString)
        let parent = CompositePKParent(customId: UUID().uuidString, content: UUID().uuidString)
        let subscription = Amplify.API.subscribe(request: .subscription(of: CompositePKChild.self, type: .onUpdate))
        Task {
            do {
                for try await subscriptionEvent in subscription {
                    switch subscriptionEvent {
                    case .connection(.connected):
                        await connected.fulfill()
                    case let .data(.success(newModel)):
                        let associatedParent = try await newModel.parent
                        if newModel.identifier == child.identifier,
                           associatedParent?.identifier == parent.identifier
                        {
                            await onUpdate.fulfill()
                        }
                    case let .data(.failure(error)):
                        XCTFail("Failed to update CompositePKParent, error: \(error.errorDescription)")
                    default: ()
                    }
                }
            }
        }

        await waitForExpectations([connected], timeout: 10)
        try await mutate(.create(child))
        try await mutate(.create(parent))

        var updatingChild = child
        updatingChild.setParent(parent)
        try await mutate(.update(updatingChild))
        await waitForExpectations([onUpdate], timeout: 10)
        subscription.cancel()
    }

    /*
     - Given: Api category setup with CompositePKModels
     - When:
        - Subscribe onCreate events of CompositePKChild
        - Create new CompositePKChild instance with API
        - Delete newly created CompositePKChild with API
     - Then:
        - the newly created instance is successfully deleted through API. onDelete event is received.
     */
    func testSubscribeCompositePKChildOnDelete() async throws {
        await setup(withModels: CompositePKModels())
        let connected = asyncExpectation(description: "Subscription connected")
        let onDelete = asyncExpectation(description: "onUpdate received")
        let child = CompositePKChild(childId: UUID().uuidString, content: UUID().uuidString)
        let subscription = Amplify.API.subscribe(request: .subscription(of: CompositePKChild.self, type: .onDelete))
        Task {
            do {
                for try await subscriptionEvent in subscription {
                    switch subscriptionEvent {
                    case .connection(.connected):
                        await connected.fulfill()
                    case let .data(.success(newModel)):
                        if newModel.identifier == child.identifier {
                            await onDelete.fulfill()
                        }
                    case let .data(.failure(error)):
                        XCTFail("Failed to update CompositePKParent, error: \(error.errorDescription)")
                    default: ()
                    }
                }
            }
        }

        await waitForExpectations([connected], timeout: 10)
        try await mutate(.create(child))
        try await mutate(.delete(child))
        await waitForExpectations([onDelete], timeout: 10)
        subscription.cancel()
    }
}
