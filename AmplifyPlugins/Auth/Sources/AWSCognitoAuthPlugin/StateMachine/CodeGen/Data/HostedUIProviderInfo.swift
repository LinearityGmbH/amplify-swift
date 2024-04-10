//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public struct HostedUIProviderInfo: Equatable, Codable {

    let authProvider: AuthProvider?

    let idpIdentifier: String?
    
    public init(authProvider: AuthProvider?, idpIdentifier: String?) {
        self.authProvider = authProvider
        self.idpIdentifier = idpIdentifier
    }

    enum CodingKeys: String, CodingKey {

        case idpIdentifier
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        idpIdentifier = try values.decodeIfPresent(String.self, forKey: .idpIdentifier)
        authProvider = nil
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(idpIdentifier, forKey: .idpIdentifier)
    }
}
