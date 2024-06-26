//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSPluginsCore
import AWSPinpoint
@testable import Amplify
@_spi(InternalAWSPinpoint) @testable import InternalAWSPinpoint

class AWSPinpointAnalyticsKeyValueStoreTests: XCTestCase {
    private let keychain = MockKeychainStore()
    private let archiver = AmplifyArchiver()
    private let userDefaults = UserDefaults.standard
    private let pinpointClient = MockPinpointClient()
    private let endpointInformation = MockEndpointInformation()
    private let currentApplicationId = "applicationId"
    private let currentEndpointId = "endpointId"

    override func setUp() {
        userDefaults.removeObject(forKey: EndpointClient.Constants.deviceTokenKey)
        userDefaults.removeObject(forKey: EndpointClient.Constants.endpointProfileKey)
        keychain.resetCounters()
        do {
            try keychain._removeAll()
        } catch {
            XCTFail("Failed to setup AWSPinpointAnalyticsKeyValueStoreTests")
        }
    }

    func testDeviceTokenMigrateFromUserDefaultsToKeychain() {
        let deviceToken = "000102030405060708090a0b0c0d0e0f"
        let deviceTokenData = deviceToken.data(using: .utf8)
        userDefaults.setValue(deviceTokenData, forKey: EndpointClient.Constants.deviceTokenKey)
        
        var currentKeychainDeviceToken = try? self.keychain._getData(EndpointClient.Constants.deviceTokenKey)
        XCTAssertNil(currentKeychainDeviceToken)
        XCTAssertNotNil(userDefaults.data(forKey: EndpointClient.Constants.deviceTokenKey))

        _ = EndpointClient(configuration: .init(appId: currentApplicationId,
                                                             uniqueDeviceId: currentEndpointId,
                                                             isDebug: false),
                                        pinpointClient: pinpointClient,
                                        archiver: archiver,
                                        endpointInformation: endpointInformation,
                                        userDefaults: userDefaults,
                                        keychain: keychain)
        
        currentKeychainDeviceToken = try? self.keychain._getData(EndpointClient.Constants.deviceTokenKey)
        XCTAssertNil(userDefaults.data(forKey:EndpointClient.Constants.deviceTokenKey))
        XCTAssertNotNil(currentKeychainDeviceToken)
    }

    func testEndpointProfileMigrateFromUserDefaultsToKeychain() {
        let profile = PinpointEndpointProfile(applicationId: "appId", endpointId: "endpointId")
        let profileData = try? archiver.encode(profile)
        userDefaults.setValue(profileData, forKey: EndpointClient.Constants.endpointProfileKey)
        
        var currentKeychainProfile = try? self.keychain._getData(EndpointClient.Constants.endpointProfileKey)
        XCTAssertNil(currentKeychainProfile)
        XCTAssertNotNil(userDefaults.data(forKey: EndpointClient.Constants.endpointProfileKey))

        _ = EndpointClient(configuration: .init(appId: currentApplicationId,
                                                             uniqueDeviceId: currentEndpointId,
                                                             isDebug: false),
                                        pinpointClient: pinpointClient,
                                        archiver: archiver,
                                        endpointInformation: endpointInformation,
                                        userDefaults: userDefaults,
                                        keychain: keychain)
        
        currentKeychainProfile = try? self.keychain._getData(EndpointClient.Constants.endpointProfileKey)
        XCTAssertNil(userDefaults.data(forKey:EndpointClient.Constants.endpointProfileKey))
        XCTAssertNotNil(currentKeychainProfile)
    }
}
