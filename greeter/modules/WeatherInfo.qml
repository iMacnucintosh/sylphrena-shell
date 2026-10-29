pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import M3Shapes
import qs.components
import qs.services

StyledRect {
    id: root

    required property int rootHeight
    readonly property bool showForecast: rootHeight >= Theme.lock.showForecastHeight
    readonly property bool showDetails: rootHeight >= Theme.lock.showWeatherDetailsHeight

    implicitHeight: column.implicitHeight + Theme.spacing.largeIncreased * 2
    radius: Theme.rounding.extraExtraLarge
    color: Theme.palette.m3surfaceContainer

    ColumnLayout {
        id: column

        // Top/left/right only — filling the parent makes implicitHeight circular
        // and the card grows with empty space under the forecast.
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Theme.spacing.largeIncreased
        spacing: Theme.spacing.large

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: Theme.spacing.extraSmall

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Weather.description
                color: Theme.palette.m3onSurfaceVariant
                font.pixelSize: Theme.font.bodyLarge
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Theme.spacing.medium

                StyledText {
                    text: Weather.temp
                    color: Theme.palette.m3primary
                    widthAxis: 80
                    font.pixelSize: Math.round(Theme.font.headlineLarge * 1.5)
                    font.weight: Font.DemiBold
                }

                MaterialIcon {
                    text: Weather.icon
                    color: Theme.palette.m3secondary
                    iconSize: Math.round(Theme.font.headlineLarge * 1.5)
                }
            }

            StyledText {
                visible: root.showDetails
                Layout.alignment: Qt.AlignHCenter
                text: `Sensación térmica ${Weather.feelsLike}`
                color: Theme.palette.m3onSurfaceVariant
                font.pixelSize: Theme.font.bodyLarge
            }

            StyledText {
                visible: root.showDetails
                Layout.alignment: Qt.AlignHCenter
                text: `Máx ${Weather.high} • Mín ${Weather.low}`
                color: Theme.palette.m3onSurfaceVariant
                font.pixelSize: Theme.font.bodyMedium
            }
        }

        Loader {
            id: forecast

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            active: root.showForecast
            visible: active
            asynchronous: true

            sourceComponent: StyledRect {
                // Loader does not always push its laid-out width onto the item.
                width: forecast.width
                color: Theme.palette.m3surfaceContainerHigh
                radius: Theme.rounding.extraLargeIncreased
                implicitHeight: forecastCol.implicitHeight + Theme.spacing.large * 2

                ColumnLayout {
                    id: forecastCol

                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: Theme.spacing.large
                    spacing: Theme.spacing.medium

                    Item {
                        Layout.fillWidth: true
                        implicitHeight: forecastHeader.implicitHeight

                        RowLayout {
                            id: forecastHeader

                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: Theme.spacing.small

                            MaterialIcon {
                                text: "schedule"
                                iconSize: Theme.font.iconMedium
                            }

                            StyledText {
                                text: "Previsión horaria"
                                font.pixelSize: Theme.font.titleMedium
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        implicitHeight: hoursRow.implicitHeight

                        RowLayout {
                            id: hoursRow

                            anchors.horizontalCenter: parent.horizontalCenter
                            width: implicitWidth
                            spacing: Theme.spacing.medium

                            Repeater {
                                model: Math.min(7, Weather.hourly.length)

                                ColumnLayout {
                                    id: hour

                                    required property int index
                                    readonly property var cond: Weather.hourly[index]

                                    Layout.preferredWidth: Theme.lock.forecastItemWidth
                                    spacing: Theme.spacing.extraSmall

                                    MaterialShape {
                                        Layout.alignment: Qt.AlignHCenter
                                        implicitSize: temp.implicitHeight + Theme.spacing.medium * 2
                                        shape: MaterialShape.Cookie4Sided
                                        color: Qt.alpha(Theme.palette.m3primary, hour.index === 0 ? 1 : 0)

                                        StyledText {
                                            id: temp

                                            anchors.centerIn: parent
                                            text: Weather.formatTemp(hour.cond.tempC)
                                            color: hour.index === 0 ? Theme.palette.m3onPrimary : Theme.palette.m3onSurface
                                            font.pixelSize: Theme.font.titleMedium
                                        }
                                    }

                                    MaterialIcon {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: hour.cond.icon
                                        color: Theme.palette.m3secondary
                                        iconSize: Theme.font.iconLarge
                                    }

                                    StyledText {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: `${Math.round(hour.cond.precipChance ?? 0)}%`
                                        color: Theme.palette.m3primary
                                        font.pixelSize: Theme.font.bodySmall
                                    }

                                    StyledText {
                                        Layout.topMargin: Theme.spacing.extraSmall
                                        Layout.alignment: Qt.AlignHCenter
                                        text: hour.index === 0 ? "Ahora" : Qt.formatDateTime(new Date(hour.cond.time), "HH:00")
                                        color: Theme.palette.m3onSurfaceVariant
                                        font.pixelSize: Theme.font.bodyMedium
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
