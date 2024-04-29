/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app's scene delegate object.
*/

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

}

func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    if let windowScene = scene as? UIWindowScene {
        windowScene.windows.forEach { window in
            window.overrideUserInterfaceStyle = .light // Forces light mode
        }
    }
}
