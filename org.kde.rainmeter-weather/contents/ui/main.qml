import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQml
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents

PlasmoidItem {
    id: root

    // ---- Configuration bindings ----
    property string apiKey: plasmoid.configuration.apiKey
    property string latitude: plasmoid.configuration.latitude
    property string longitude: plasmoid.configuration.longitude
    property string units: plasmoid.configuration.units
    property string language: plasmoid.configuration.language
    property int refreshMinutes: plasmoid.configuration.updateMinutes
    property int forecastDays: plasmoid.configuration.forecastDays

    // ---- Runtime data ----
    property bool loading: false
    property string errorText: ""

    property string currentTempText: "--"
    property string currentIconCode: ""

    // Nes and variables for the main Tooltip/Summary card
    property string locationName: ""
    property string country: ""
    property string fetchTimeString: ""
    property string weatherStatus: ""
    property string feelsLikeString: ""
    property string windString: ""
    property string uvString: ""
    property string humidityString: ""
    property string pressureString: ""
    property string visibilityString: ""
    property string sunriseString: ""
    property string sunsetString: ""
    property string alertString: ""

    // Min max temp and precipitation chance
    property int precipChance: 0
    property string currentTempMaxString: ""
    property string currentTempMinString: ""

    property font widgetFont: Qt.font({ family: "ITC Avant Garde Gothic Pro" })

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground


    Connections {
        target: plasmoid
        function onConfigurationChanged() {
            fetchWeather()
        }
    }
    // ---- React to config changes ----
    // onApiKeyChanged: fetchWeather()
    // onLatitudeChanged: fetchWeather()
    // onLongitudeChanged: fetchWeather()
    // onUnitsChanged: fetchWeather()
    // onLanguageChanged: fetchWeather()
    onForecastDaysChanged: fetchWeather()
    Component.onCompleted: fetchWeather()

    // Forecast Model
    ListModel { id: forecastModel }


    Timer {
        id: refreshTimer
        repeat: true
        running: true
        interval: Math.max(1, root.refreshMinutes) * 60 * 1000
        onTriggered: fetchWeather()
        onIntervalChanged: restart()
    }


    function extractTimeFromString(isoString) {
        var date = new Date(isoString);

        // Using UTC methods to keep the original GMT time
        var hours = date.getUTCHours().toString().padStart(2, '0');
        var minutes = date.getUTCMinutes().toString().padStart(2, '0');

        return hours + ":" + minutes;
    }

    function iconSource(iconCode) {
        if (!iconCode || iconCode === "") {
            return ""
        }
        // Your Rainmeter pack is numeric pngs, so iconCode should be like "32", "12", etc.
        return Qt.resolvedUrl("weather-icons/" + iconCode + ".png")
    }


    function isConfigValid() {
        return root.apiKey && root.apiKey.length > 0
        && root.latitude && root.latitude.length > 0
        && root.longitude && root.longitude.length > 0
    }


    // ---- Weather fetch (Weather.com-style; adjust endpoints/fields if needed) ----
    function fetchWeather() {
        if (!isConfigValid()) {
            loading = false
            errorText = i18n("Please configure API key and coordinates.")
            return
        }

        loading = true
        errorText = ""

        const base =
        "https://api.weather.com/v3/aggcommon/" +
        "v3-wx-observations-current;" +
        "v3-wx-forecast-daily-15day;" +
        "v3alertsHeadlines;" +
        "v3-location-point;" +
        "v3-wx-forecast-hourly-12hour"

        const qs =
        "format=json" +
        "&geocode=" + encodeURIComponent(root.latitude + "," + root.longitude) +
        "&units=" + encodeURIComponent(root.units && root.units.length ? root.units : "m") +
        "&language=" + encodeURIComponent(root.language && root.language.length ? root.language : "en-GB") +
        "&apiKey=" + encodeURIComponent(root.apiKey)

        const url = base + "?" + qs

        const xhr = new XMLHttpRequest()
        xhr.open("GET", url)
        xhr.onreadystatechange = function () {

            if (xhr.readyState !== XMLHttpRequest.DONE) return

            loading = false

            if (xhr.status < 200 || xhr.status >= 300) {
                errorText = i18n("Weather request failed (%1).", xhr.status)
                return
            }

            let agg
            try {
                agg = JSON.parse(xhr.responseText)
            } catch (e) {
                errorText = i18n("Could not parse weather response.")
                return
            }

            function toDegText(v) {
                return (v === undefined || v === null) ? "--" : (String(v) + "°")
            }
            function toStr(v) {
                return (v === undefined || v === null) ? "" : String(v)
            }
            function isNum(v) {
                return v !== null && v !== undefined && !isNaN(Number(v))
            }

            // ---------------- Location ----------------
            const locBlock = agg["v3-location-point"]
            if (locBlock && locBlock.location) {
                root.locationName = toStr(locBlock.location.city || locBlock.location.displayName || "")
                root.country = locBlock.location.country
            }

            // ---------------- Current observation ----------------
            const cur = agg["v3-wx-observations-current"]
            if (cur) {
                const temp = cur.temperature
                root.currentTempText = isNum(temp) ? (String(temp) + "°") : "--"
                root.currentIconCode = toStr(cur.iconCode)
                root.fetchTimeString = `${cur.dayOfWeek}, ${extractTimeFromString(cur.validTimeLocal)} GMT`

                root.weatherStatus = cur.wxPhraseLong
                root.feelsLikeString = `Feels Like ${cur.temperatureFeelsLike}°`
                root.windString = `Wind ${cur.windDirectionCardinal} ${cur.windSpeed} km/h`
                root.uvString = `UV ${cur.uvIndex} (${cur.uvDescription}) `
                root.humidityString = `Humidity ${cur.relativeHumidity}%`
                root.pressureString = `Pressure ${cur.pressureAltimeter} mb`
                root.visibilityString = `Visibility ${cur.visibility} km`
                root.sunriseString = `☀↑ ${extractTimeFromString(cur.sunriseTimeLocal)}`
                root.sunsetString  = `☀↓ ${extractTimeFromString(cur.sunsetTimeLocal)}`
            }

            // ---------------- Daily 15 day forecast ----------------
            const daily = agg["v3-wx-forecast-daily-15day"]
            if (!daily) {
                errorText = i18n("Daily 15-Day forecast missing in response.")
                return
            }

            // Standard arrays
            const days = Array.isArray(daily.dayOfWeek) ? daily.dayOfWeek : []
            const maxArr = Array.isArray(daily.temperatureMax) ? daily.temperatureMax : []
            const minArr = Array.isArray(daily.temperatureMin) ? daily.temperatureMin : []

            // Days and Phrases array alternate values between day and night for each day
            const dayIconArr = Array.isArray(daily.daypart) && Array.isArray(daily.daypart[0].iconCode) ? daily.daypart[0].iconCode : []
            const dayPhrasesArr = Array.isArray(daily.daypart) && Array.isArray(daily.daypart[0].wxPhraseLong) ? daily.daypart[0].wxPhraseLong : []


            //Some array (icons, precipChance, etc)  contains day and night values on alternate positions
            var now = new Date()
            let iconOffset = now.getHours() < 18 ? 0 : 1

            // Current day min and max and precipitation chance
            if (maxArr.length > 0) root.currentTempMaxString = "<font color='red'> <b>↑</b></font>" + maxArr[0] + "°"
            if (minArr.length > 0) root.currentTempMinString = "<font color='cyan'><b>↓</b></font>" + minArr[0] + "°"

            if (Array.isArray(daily.daypart) && Array.isArray(daily.daypart[0].precipChance)) root.precipChance = Number(daily.daypart[0].precipChance[iconOffset])


            //Clear the model
            forecastModel.clear()

            // Fill forecast model for your 3x2 grid depending on the forecastDays value
            const count = root.forecastDays //Math.min(6, days.length, maxArr.length, minArr.length)
            for (let i = 1; i <= count; i++) {

                let icon = dayIconArr[i * 2 + iconOffset]
                let phrase = dayPhrasesArr[i * 2 + iconOffset]

                forecastModel.append({
                    dayName:  toStr(days[i]),
                    iconCode: toStr(icon),
                    maxTemp:  toDegText(maxArr[i]),
                    minTemp:  toDegText(minArr[i]),
                    toolTip:  phrase
                })
            }

            // ---------------- Alerts ----------------
            const headLines = agg["v3alertsHeadlines"]
            if (headLines && Array.isArray(headLines.alerts)) {
                root.alertString = ""
                for (let i = 0; i < headLines.alerts.length; i++) {
                    root.alertString += "<img src='icons/warning-yellow.svg' width='20' height='20'/>" + headLines.alerts[i].headlineText + "<br/>"
                }
            }
        }
        xhr.send()
    }




    // --------------------------------------------------------------------------
    // --- City, current temp + big icon, min/max and precipitation chance ------
    // --------------------------------------------------------------------------
    ColumnLayout {
        id: columns
        spacing: 0
        Layout.margins: 0
        anchors.fill: parent

        RowLayout {
            id: headerRow
            spacing: 0
            Layout.fillWidth: true
            Layout.fillHeight: false

            ColumnLayout {
                id: colTemperatures
                spacing: 0
                Layout.fillWidth: true

                // City
                PlasmaComponents.Label {
                    id: cityLabel
                    text: root.locationName && root.locationName.length ? root.locationName : ""
                    font.family: root.widgetFont.family
                    font.pointSize: 12
                    Layout.fillWidth: true
                }

                // Big temperature value
                PlasmaComponents.Label {
                    id: bigTemp
                    text: root.currentTempText && root.currentTempText.length ? root.currentTempText : "--"
                    font.family: root.widgetFont.family
                    font.pointSize: 40
                    font.weight: Font.Light
                }

                // Min and max current temps
                RowLayout {
                    id: rowMinMax
                    spacing: 2

                    PlasmaComponents.Label {
                        text: root.currentTempMaxString
                        font.family: root.widgetFont.family
                        font.pointSize: 12
                    }
                    PlasmaComponents.Label {
                        text: root.currentTempMinString
                        font.family: root.widgetFont.family
                        font.pointSize: 12
                    }
                }

                // precipitation chance (blue drop + label and percent)
                RowLayout {
                    id: rowprecipChance
                    spacing: 1

                    PlasmaComponents.Label {
                        //text: "💧"
                        textFormat: Text.RichText
                        text: "<img src='icons/droplet-blue.svg' width='16' height='16'/>"
                        // font.family: root.widgetFont.family
                        // font.pointSize: 14
                        // opacity: 0.90
                        topPadding: 4;
                    }
                    PlasmaComponents.Label {
                        text: String(root.precipChance) + "%"
                        font.family: root.widgetFont.family
                        font.pointSize: 12
                        topPadding: 4;
                    }
                }
            }

            // Big icon for current weather on the right
            Item {
                Layout.preferredWidth: 168
                Layout.fillHeight: true

                Image {
                    id: bigIcon
                    width: parent.width * 0.95
                    height: width
                    source: iconSource(root.currentIconCode)
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    x: forecastModel.count > 0 ? -20 : 19
                    y: -11
                }

                MouseArea {
                    id: ma
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                }

                ToolTip {
                    visible: ma.containsMouse
                    delay: 300
                    x: bigIcon.x + (bigIcon.width - implicitWidth) / 2
                    y: bigIcon.y + (bigIcon.height - implicitHeight) / 2

                    // Card look
                    padding: 10

                    background: Rectangle {
                        radius: 6
                        color: "white"
                        border.color: "#d0d0d0"
                        border.width: 1
                    }

                    // Custom content
                    contentItem: ColumnLayout {
                        spacing: 6

                        // Title
                        Text {
                            text: "<font color='darkblue'>"+root.locationName + ", " + root.country+"</font>"
                            font.bold: true
                            font.pointSize: 11
                            color: "#1a1a1a"
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                        }

                        // Time
                        Text {
                            text: root.fetchTimeString
                            color: "#1a1a1a"
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: "#e6e6e6"
                        }

                        // Condition
                        Text {
                            text: root.weatherStatus
                            color: "#1a1a1a"
                        }

                        // Details (simple lines)
                        ColumnLayout {
                            spacing: 2
                            Text { text: root.feelsLikeString; color: "#1a1a1a" }
                            Text { text: root.windString; color: "#1a1a1a" }
                            Text { text: root.uvString; color: "#1a1a1a" }
                            Text { text: root.humidityString; color: "#1a1a1a" }
                            Text { text: root.pressureString; color: "#1a1a1a" }
                            Text { text: root.visibilityString; color: "#1a1a1a" }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: "#e6e6e6"
                        }

                        // Sunrise / Sunset row (use your icons)
                        RowLayout {
                            spacing: 12

                            // Sunrise
                            RowLayout {
                                spacing: 6
                                Text { text: root.sunriseString; color: "#1a1a1a" }
                            }

                            // Sunset
                            RowLayout {
                                spacing: 6
                                Text { text: root.sunsetString; color: "#1a1a1a" }
                            }
                        }
                    }

                }
            }
        }

        // --------------------------------------------------------------
        // -------------- Forecast grid 3 columns x 2 rows --------------
        // --------------------------------------------------------------
        GridLayout {
            id: forecastGrid
            columns: 3
            columnSpacing: 10
            rowSpacing: 12
            Layout.fillWidth: true
            Layout.preferredHeight: forecastModel.count > 0 ? implicitHeight : 0
            Layout.topMargin: 10

            Repeater {
                model: forecastModel
                delegate: ColumnLayout {
                Layout.alignment: Qt.AlignHCenter

                    Item {
                        width: 84; height: 84

                        Image {
                            id: icon
                            anchors.fill: parent
                            source: iconSource(iconCode)
                            asynchronous: true
                        }

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.NoButton
                        }

                        ToolTip {
                            visible: mouseArea.containsMouse
                            delay: 300
                            //x: icon.x + implicitWidth / 2
                            y: icon.y - implicitHeight / 2

                            // Card look
                            padding: 5

                            background: Rectangle {
                                radius: 6
                                color: "white"
                                border.color: "#d0d0d0"
                                border.width: 1
                            }

                            // Custom content
                            contentItem: ColumnLayout {
                                spacing: 6

                                Text {
                                    text: toolTip
                                    color: "#1a1a1a"
                                }
                            }
                        }
                    }

                    // Day of the week
                    PlasmaComponents.Label {
                        text: dayName.substring(0, 3)
                        font.family: root.widgetFont.family
                        font.pointSize: 12
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignHCenter
                        topPadding: -7; bottomPadding: 0; leftPadding: 0; rightPadding: 0
                    }

                    // Min and max temps
                    PlasmaComponents.Label {
                        text: maxTemp + "/" + minTemp
                        font.family: root.widgetFont.family
                        font.pointSize: 12
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignHCenter
                        topPadding: -4; bottomPadding: 0; leftPadding: 0; rightPadding: 0
                    }
                }
            }
        }
        // --------------------------------------------------------------
        // -------------------------- Alerts ----------------------------
        // --------------------------------------------------------------
        RowLayout {
            id: rowAlert
            spacing: 2
            PlasmaComponents.Label {
                text: root.alertString
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                //font.family: root.widgetFont.family
                font.pointSize: 9
                topPadding: 15
            }
        }
    }
}
