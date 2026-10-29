pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

// Open-Meteo, fixed location (no IP geolocation: the greeter runs before the
// user session and should not depend on ip-api availability).
Singleton {
    id: root

    property var cc
    property var hourly: []
    property var daily

    readonly property string icon: cc ? getIcon(cc.code, cc.isDay) : "cloud_alert"
    readonly property string description: cc ? getCondition(cc.code) : "Sin datos del tiempo"
    readonly property string temp: formatTemp(cc?.tempC)
    readonly property string feelsLike: formatTemp(cc?.feelsLikeC)
    readonly property string high: formatTemp(daily?.max)
    readonly property string low: formatTemp(daily?.min)

    function formatTemp(value: var): string {
        return value === undefined || value === null ? "--" : `${Math.round(value)}°`;
    }

    function getIcon(code: int, isDay: bool): string {
        const icons = {
            0: "clear_day",
            1: "clear_day",
            2: "partly_cloudy_day",
            3: "cloud",
            45: "foggy",
            48: "foggy",
            51: "rainy",
            53: "rainy",
            55: "rainy",
            56: "rainy",
            57: "rainy",
            61: "rainy",
            63: "rainy",
            65: "rainy",
            66: "rainy",
            67: "rainy",
            71: "cloudy_snowing",
            73: "cloudy_snowing",
            75: "snowing_heavy",
            77: "cloudy_snowing",
            80: "rainy",
            81: "rainy",
            82: "rainy",
            85: "cloudy_snowing",
            86: "snowing_heavy",
            95: "thunderstorm",
            96: "thunderstorm",
            99: "thunderstorm"
        };
        if (!isDay && (code === 0 || code === 1))
            return "clear_night";
        if (!isDay && code === 2)
            return "partly_cloudy_night";
        return icons[code] ?? "air";
    }

    function getCondition(code: int): string {
        const conditions = {
            0: "Despejado",
            1: "Despejado",
            2: "Parcialmente nublado",
            3: "Cubierto",
            45: "Niebla",
            48: "Niebla",
            51: "Llovizna",
            53: "Llovizna",
            55: "Llovizna",
            56: "Llovizna helada",
            57: "Llovizna helada",
            61: "Lluvia ligera",
            63: "Lluvia",
            65: "Lluvia fuerte",
            66: "Lluvia ligera",
            67: "Lluvia fuerte",
            71: "Nieve ligera",
            73: "Nieve",
            75: "Nieve fuerte",
            77: "Nieve",
            80: "Lluvia ligera",
            81: "Lluvia",
            82: "Lluvia fuerte",
            85: "Nevadas ligeras",
            86: "Nevadas fuertes",
            95: "Tormenta",
            96: "Tormenta con granizo",
            99: "Tormenta con granizo"
        };
        return conditions[code] ?? "Desconocido";
    }

    function reload(): void {
        if (!proc.running)
            proc.running = true;
    }

    function parse(text: string): void {
        let data;
        try {
            data = JSON.parse(text);
        } catch (e) {
            console.warn(`greeter: bad weather response: ${e}`);
            return;
        }
        const current = data.current;
        if (!current)
            return;

        root.cc = {
            tempC: current.temperature_2m,
            feelsLikeC: current.apparent_temperature,
            code: current.weather_code,
            isDay: current.is_day === 1,
            humidity: current.relative_humidity_2m,
            wind: current.wind_speed_10m
        };

        const h = data.hourly;
        if (h?.time) {
            const now = new Date();
            let start = h.time.findIndex(t => new Date(t) >= now);
            if (start < 0)
                start = 0;
            const list = [];
            for (let i = start; i < Math.min(start + 8, h.time.length); i++) {
                list.push({
                    time: h.time[i],
                    tempC: h.temperature_2m?.[i],
                    code: h.weather_code?.[i],
                    precipChance: h.precipitation_probability?.[i] ?? 0,
                    icon: root.getIcon(h.weather_code?.[i], true)
                });
            }
            root.hourly = list;
        }

        const d = data.daily;
        if (d?.time?.length)
            root.daily = {
                max: d.temperature_2m_max?.[0],
                min: d.temperature_2m_min?.[0]
            };
    }

    Component.onCompleted: reload()

    Timer {
        interval: 900000 // 15 minutes
        running: true
        repeat: true
        onTriggered: root.reload()
    }

    Process {
        id: proc

        command: ["curl", "-sS", "--max-time", "10", `https://api.open-meteo.com/v1/forecast?latitude=${Theme.location.split(",")[0]}&longitude=${Theme.location.split(",")[1]}&hourly=weather_code,temperature_2m,precipitation_probability&daily=weather_code,temperature_2m_max,temperature_2m_min&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,weather_code,wind_speed_10m&timezone=auto&forecast_days=3`]

        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }
}
