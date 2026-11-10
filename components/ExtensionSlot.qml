import QtQuick
import qs.services

// Places one component contributed by an extension (see services/Extensions.qml). The component is
// created with `ext` and `service` set (extensions declare them as required properties), fills
// this item, and is destroyed with it. Extra properties for the component go in `props`.
Item {
    id: root

    // { id, ext, component } as listed by Extensions (e.g. an entry of Extensions.widgets)
    required property var entry
    property var props: ({})
    readonly property Item item: _item
    property Item _item: null

    implicitWidth: _item?.implicitWidth ?? 0
    implicitHeight: _item?.implicitHeight ?? 0

    Component.onCompleted: {
        const obj = entry.component.createObject(root, Object.assign({
            ext: entry.ext,
            service: entry.ext.service
        }, props));
        if (!obj) {
            console.warn(`ExtensionSlot: could not create ${entry.ext.id}/${entry.id}: ${entry.component.errorString()}`);
            return;
        }
        obj.anchors.fill = root;
        _item = obj;
    }
}
