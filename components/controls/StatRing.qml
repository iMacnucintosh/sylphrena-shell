import QtQuick

// CircularProgress for live stats (CPU, memory, storage, battery…): set `reading` instead of
// `value`. The ring only follows changes of `minStep` (2 %) or more. Stats update every second
// and nearly always move a little; animating each tiny change kept the ring animating non-stop,
// and that kept the whole dashboard window redrawing at the monitor refresh rate.
CircularProgress {
    id: root

    property real reading
    property real minStep: 0.02

    onReadingChanged: {
        if (isNaN(reading) || Math.abs(reading - value) >= minStep || reading <= 0 || reading >= 1)
            value = reading;
    }
    Component.onCompleted: value = reading
}
