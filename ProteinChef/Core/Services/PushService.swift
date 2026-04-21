import Foundation
import UIKit

protocol PushServiceProtocol: Sendable {
    func requestAuthorization() async -> Bool
    func registerForRemoteNotifications()
}
