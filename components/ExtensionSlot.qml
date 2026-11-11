import QtQuick
import qs.services

// Places one component contributed by an extension (see services/Extensions.qml). The component is
// created with `ext` and `service` set (extensions declare them as required properties), fills
// this item, and is destroyed with it. Extra properties for the component go in `props`.
// `entry` may be null (nothing is shown) and may change: the item is rebuilt, e.g. when an
// extension finishes loading or is disabled.
Item {
    id: root

    // { ext, component, ... } as listed by Extensions (e.g. an entry of Extensions.widgets), or null
    property var entry: null
    property var props: ({})
    readonly property Item item: _item
    property Item _item: null

    // Popout dialogs of extensions are closed by the bar's popout wrapper (Escape): forward to the item
    function closeDialog(): void {
        if (_item?.closeDialog)
            _item.closeDialog();
    }

    function rebuild(): void {
        if (_item) {
            _item.destroy();
            _item = null;
        }
        if (!entry?.component)
            return;
        const obj = entry.component.createObject(root, Object.assign({
            ext: entry.ext,
            service: entry.ext.service
        }, props));
        if (!obj) {
            console.warn(`ExtensionSlot: could not create ${entry.ext.id}: ${entry.component.errorString()}`);
            return;
        }
        obj.anchors.fill = root;
        _item = obj;
    }

    implicitWidth: _item?.implicitWidth ?? 0
    implicitHeight: _item?.implicitHeight ?? 0

    onEntryChanged: rebuild()
    Component.onCompleted: rebuild()
}
