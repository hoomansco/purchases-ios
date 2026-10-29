//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

//  AsyncButton.swift
//
//  Created by Nacho Soto on 7/13/23.

import RevenueCat
import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct AsyncButton<Label>: View where Label: View {

    typealias Action = @Sendable @MainActor () async throws -> Void

    private let action: Action
    private let label: Label

    @State
    private var error: NSError?

    init(
        action: @escaping Action,
        @ViewBuilder label: () -> Label
    ) {
        self.action = action
        self.label = label()
    }

    var body: some View {
        Button {
            Task<Void, Never> {
                do {
                    try await self.action()
                } catch let error as NSError {
                    // A pending purchase (Ask to Buy, UPI mandate approval) is not a
                    // failure the user can act on here: StoreKit completes it later and
                    // `Transaction.updates` delivers it. The error still reaches
                    // `onPurchaseFailure`, so the app can show its own guidance instead
                    // of a generic error alert.
                    guard !error.isPaymentPending else { return }
                    self.error = error
                }
            }
        } label: {
            self.label
        }
        .displayError(self.$error)
    }

}

private extension NSError {

    var isPaymentPending: Bool {
        return self.domain == ErrorCode.errorDomain
            && self.code == ErrorCode.paymentPendingError.rawValue
    }

}
