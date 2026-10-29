pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import M3Shapes
import qs.components
import qs.services

StyledRect {
    id: root

    required property real centerScale
    required property int centerWidth

    property string buffer

    implicitWidth: {
        const w = centerWidth * 0.8;
        return root.buffer ? w : Math.min(w, inputField.placeholderWidth + iconWrapper.implicitWidth + enterButton.implicitWidth + input.spacing * 2 + Theme.spacing.medium * 2);
    }
    implicitHeight: input.implicitHeight + Theme.spacing.small

    color: Theme.palette.m3surfaceContainer
    radius: Theme.rounding.full

    // Hidden TextInput owns focus/IME; the shapes are just the visual.
    focus: true
    onActiveFocusChanged: {
        if (activeFocus)
            field.forceActiveFocus();
    }

    function submit(): void {
        if (!root.buffer || Auth.busy || Auth.success)
            return;
        const password = root.buffer;
        root.buffer = "";
        field.text = "";
        inputField.showPassword = false;
        Auth.submit(password);
    }

    TextInput {
        id: field

        // Zero-size so it never steals clicks from the eye / submit button.
        width: 0
        height: 0
        opacity: 0
        enabled: !Auth.busy && !Auth.success
        focus: true
        activeFocusOnPress: false

        onTextChanged: root.buffer = text
        onAccepted: root.submit()

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                event.accepted = true;
                root.buffer = "";
                field.text = "";
                inputField.showPassword = false;
            }
        }

        Component.onCompleted: forceActiveFocus()
    }

    Behavior on implicitWidth {
        Anim {}
    }

    StateLayer {
        hoverEnabled: false
        cursorShape: Qt.IBeamCursor
        onClicked: field.forceActiveFocus()
    }

    RowLayout {
        id: input

        anchors.fill: parent
        anchors.margins: Theme.spacing.extraSmall
        spacing: Theme.spacing.medium

        Item {
            id: iconWrapper

            Layout.fillHeight: true
            implicitWidth: height

            Loader {
                anchors.centerIn: parent
                active: Auth.busy
                sourceComponent: LoadingIndicator {
                    implicitSize: iconWrapper.height - Theme.spacing.small * 2
                }
            }

            MaterialIcon {
                anchors.centerIn: parent
                visible: !Auth.busy
                text: inputField.showPassword ? "visibility" : "lock"
                fill: inputField.showPassword ? 1 : 0
                color: Theme.palette.m3onSurfaceVariant
                iconSize: Math.round(Theme.font.iconMedium * root.centerScale)
                z: 2

                // Own the click target (lock screen pattern): toggling a
                // parent-bound showPassword broke the InputField binding.
                MouseArea {
                    anchors.centerIn: parent
                    width: parent.implicitHeight + Theme.spacing.small * 2
                    height: width
                    cursorShape: Qt.PointingHandCursor
                    z: 3
                    onClicked: {
                        inputField.showPassword = !inputField.showPassword;
                        field.forceActiveFocus();
                    }
                }
            }
        }

        InputField {
            id: inputField

            Layout.fillWidth: true
            Layout.fillHeight: true

            centerScale: root.centerScale
            buffer: root.buffer
            busy: Auth.busy
        }

        Item {
            id: enterButton

            implicitWidth: implicitHeight
            implicitHeight: {
                const h = enterIcon.implicitHeight + Theme.spacing.extraSmall * 2;
                return h % 2 === 0 ? h : h + 1;
            }

            MaterialShape {
                anchors.fill: parent

                color: root.buffer ? Theme.palette.m3primary : Theme.palette.m3surfaceContainerHigh
                shape: root.buffer ? MaterialShape.Arrow : MaterialShape.Circle
                scale: !root.buffer ? 1 : mouse.pressed ? 0.6 : mouse.containsMouse ? 0.8 : 0.7
                rotation: 90

                Behavior on scale {
                    Anim {
                        type: Anim.FastSpatial
                    }
                }

                Behavior on color {
                    CAnim {}
                }

                MouseArea {
                    id: mouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: root.buffer ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: root.submit()
                }
            }

            MaterialIcon {
                id: enterIcon

                anchors.centerIn: parent
                text: "arrow_forward"
                color: Theme.palette.m3onSurfaceVariant
                iconSize: Math.round(Theme.font.iconMedium * root.centerScale * 1.2)
                opacity: root.buffer ? 0 : 1

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }
        }
    }
}
