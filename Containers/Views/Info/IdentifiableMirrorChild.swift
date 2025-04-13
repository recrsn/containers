import SwiftUI

struct IdentifiableMirrorChild: Identifiable {
    let child: Mirror.Child
    let id: String

    init(_ child: Mirror.Child) {
        self.child = child
        self.id = child.label ?? UUID().uuidString
    }

    var label: String? { child.label }
    var value: Any { child.value }
}
