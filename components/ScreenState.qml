import Quickshell

PersistentProperties {
    required property ShellScreen modelData

    // Drawer visibilities
    property bool bar
    property bool osd
    property bool session
    property bool launcher
    property bool dashboard
    property bool utilities
    property bool sidebar

    // Dashboard state
    property int dashboardTab
    // A text field in the dashboard (Tasks) is being typed in: grab the keyboard and keep it open
    property bool dashboardTyping
    property date dashboardDate: new Date()

    onDashboardChanged: {
        if (!dashboard)
            dashboardTyping = false;
    }
}
