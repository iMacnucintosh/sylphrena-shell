import QtQuick

QtObject {
    property string currentName
    property bool hasCurrent
    // Target activity for the bar-side activity context popout.
    property string activityMenuId
    readonly property bool sticky: currentName === "updatesPassword" || currentName === "wirelesspassword" || currentName === "vpnOtp" || currentName === "vpnSettings"

    signal detachRequested(mode: string)
}
