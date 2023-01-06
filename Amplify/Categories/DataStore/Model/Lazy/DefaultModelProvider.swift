//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

// MARK: - DefaultModelProvider

public struct DefaultModelProvider<Element: Model>: ModelProvider {
    enum LoadedState {
        case notLoaded(identifiers: [LazyReferenceIdentifier]?)
        case loaded(model: Element?)
    }
    
    var loadedState: LoadedState
    
    public init(element: Element? = nil) {
        self.loadedState = .loaded(model: element)
    }
    
    public init(identifiers: [LazyReferenceIdentifier]?) {
        self.loadedState = .notLoaded(identifiers: identifiers)
    }
    
    public func load() async throws -> Element? {
        switch loadedState {
        case .notLoaded:
            return Fatal.preconditionFailure("DefaultModelProvider does not provide loading capabilities")
        case .loaded(let model):
            return model
        }
    }
    
    public func getState() -> ModelProviderState<Element> {
        switch loadedState {
        case .notLoaded(let identifiers):
            return .notLoaded(identifiers: identifiers)
        case .loaded(let model):
            return .loaded(model)
        }
    }
}
