//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

extension AWSCognitoAuthPlugin: Resettable {

    public func reset() {
        try? makeCredentialStore().deleteCredential()
    }
}

public struct AmplifyConfigurationLogging: Codable {
    public let awsCloudWatchLoggingPlugin: AWSCloudWatchLoggingPluginConfiguration
}
