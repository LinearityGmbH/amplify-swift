//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation


public struct FetchIdentityEvent: StateMachineEvent {
    public enum EventType: Equatable {

        case fetch(AWSAuthCognitoSession)
        
        case fetched
        
        case throwError(AuthorizationError)

    }

    public let id: String
    public let eventType: EventType
    public let time: Date?

    public var type: String {
        switch eventType {
        case .fetch: return "FetchIdentityEvent.fetch"
        case .fetched: return "FetchIdentityEvent.fetched"
        case .throwError: return "FetchIdentityEvent.throwError"
        }
    }

    public init(
        id: String = UUID().uuidString,
        eventType: EventType,
        time: Date? = nil
    ) {
        self.id = id
        self.eventType = eventType
        self.time = time
    }
}
