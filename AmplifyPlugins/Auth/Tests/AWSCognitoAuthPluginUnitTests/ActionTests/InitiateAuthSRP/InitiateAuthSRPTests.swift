//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSCognitoIdentityProvider

@testable import AWSCognitoAuthPlugin

class InitiateAuthSRPTests: XCTestCase {

    func testInitiate() async {
        let initiateAuthInvoked = expectation(description: "initiateAuthInvoked")
        let identityProviderFactory: BasicSRPAuthEnvironment.CognitoUserPoolFactory = {
            MockIdentityProvider(
                mockInitiateAuthResponse: { _ in
                    initiateAuthInvoked.fulfill()
                    return InitiateAuthOutput()
                }
            )
        }

        let environment = Defaults.makeDefaultAuthEnvironment(
            userPoolFactory: identityProviderFactory)
        let action = InitiateAuthSRP(username: "testUser", password: "testPassword", respondToAuthChallenge: nil)

        await action.execute(
            withDispatcher: MockDispatcher { _ in },
            environment: environment
        )

        await fulfillment(
            of: [initiateAuthInvoked],
            timeout: 0.1
        )
    }

    func testFailedInitiateAuthPropagatesError() async {
        let identityProviderFactory: BasicSRPAuthEnvironment.CognitoUserPoolFactory = {
            MockIdentityProvider(
                mockInitiateAuthResponse: { _ in
                    throw NSError(domain: "testError", code: 0, userInfo: nil)

                }
            )
        }

        let environment = Defaults.makeDefaultAuthEnvironment(
            userPoolFactory: identityProviderFactory)

        let action = InitiateAuthSRP(username: "testUser", password: "testPassword", respondToAuthChallenge: nil)

        let errorEventSent = expectation(description: "errorEventSent")
        let dispatcher = MockDispatcher { event in

            guard let event = event as? SignInEvent else {
                XCTFail("Expected event to be SignInEvent")
                return
            }

            if case let .throwAuthError(error) = event.eventType {
                XCTAssertNotNil(error)
                errorEventSent.fulfill()
            }

        }

        await action.execute(
            withDispatcher: dispatcher,
            environment: environment
        )

        await fulfillment(
            of: [errorEventSent],
            timeout: 0.1
        )
    }

    func testSuccessfulInitiateAuthPropagatesSuccess() async {
        let identityProviderFactory: BasicSRPAuthEnvironment.CognitoUserPoolFactory = {
            MockIdentityProvider(
                mockInitiateAuthResponse: { _ in
                    return InitiateAuthOutput()
                }
            )
        }

        let environment = Defaults.makeDefaultAuthEnvironment(
            userPoolFactory: identityProviderFactory)

        let action = InitiateAuthSRP(username: "testUser", password: "testPassword", respondToAuthChallenge: nil)

        let successEventSent = expectation(description: "successEventSent")

        let dispatcher = MockDispatcher { event in
            guard let event = event as? SignInEvent else {
                XCTFail("Expected event to be SignInEvent")
                return
            }

            if case let .respondPasswordVerifier(_, authResponse, _) = event.eventType {
                XCTAssertNotNil(authResponse)
                successEventSent.fulfill()
            }
        }

        await action.execute(
            withDispatcher: dispatcher,
            environment: environment
        )

        await fulfillment(
            of: [successEventSent],
            timeout: 0.1
        )
    }
}
