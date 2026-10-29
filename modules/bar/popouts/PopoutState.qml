import QtQuick

QtObject {
    property string currentName
    property bool hasCurrent
    readonly property bool sticky: currentName === "updatesPassword" || currentName === "wirelesspassword" || currentName === "vpnOtp" || currentName === "vpnSettings"

    signal detachRequested(mode: string)
}
