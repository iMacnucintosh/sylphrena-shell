import QtQuick

QtObject {
    property string currentName
    property bool hasCurrent
    // Target activity for the bar-side activity context popout.
    property string activityMenuId
    // A password/OTP/settings dialog is open and must survive hover-away. Requires
    // hasCurrent: several close paths (e.g. update started → UpdatesPassword) hide the
    // popout with hasCurrent = false and leave currentName untouched; without this the
    // stale name kept sticky true forever and no bar popout opened until a shell restart.
    readonly property bool sticky: hasCurrent && (currentName === "updatesPassword" || currentName === "wirelesspassword" || currentName === "vpnOtp" || currentName === "vpnSettings")

    signal detachRequested(mode: string)
}
