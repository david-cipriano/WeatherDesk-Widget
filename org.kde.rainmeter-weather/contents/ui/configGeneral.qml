import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: root

    property alias cfg_apiKey: apiKeyField.text
    property alias cfg_latitude: latitudeField.text
    property alias cfg_longitude: longitudeField.text
    property alias cfg_units: unitsCombo.currentValue
    property alias cfg_language: languageField.text
    property alias cfg_updateMinutes: refreshSpin.value
    property int cfg_forecastDays: 6

    //choose font

    Kirigami.FormLayout {
        id: form
        anchors.fill: parent

        QQC2.Label {
            Kirigami.FormData.isSection: true
            text: i18n("Weather.com")
            font.bold: true
        }

        QQC2.TextField {
            id: apiKeyField
            Kirigami.FormData.label: i18n("API key:")
            placeholderText: i18n("Paste your Weather.com API key")
        }

        QQC2.Label {
            Kirigami.FormData.isSection: true
            text: i18n("Location")
            font.bold: true
        }

        QQC2.TextField {
            id: latitudeField
            Kirigami.FormData.label: i18n("Latitude:")
            placeholderText: i18n("e.g. 55.9533")
            inputMethodHints: Qt.ImhFormattedNumbersOnly
        }

        QQC2.TextField {
            id: longitudeField
            Kirigami.FormData.label: i18n("Longitude:")
            placeholderText: i18n("e.g. -3.1883")
            inputMethodHints: Qt.ImhFormattedNumbersOnly
        }


        QQC2.Label {
            Kirigami.FormData.isSection: true
            text: i18n("Forecast")
            font.bold: true
        }

        // --- Forecast selection (2 rows x 3 columns) ---
        QQC2.ButtonGroup { id: forecastGroup }
        Item {
            Kirigami.FormData.label: i18n("Days:")
            Kirigami.FormData.labelAlignment: Qt.AlignRight | Qt.AlignTop

            implicitWidth: forecastGrid.implicitWidth
            implicitHeight: forecastGrid.implicitHeight
            GridLayout {
                id: forecastGrid
                columns: 3
                rowSpacing: Kirigami.Units.smallSpacing
                columnSpacing: Kirigami.Units.largeSpacing

                Repeater {
                    model: [
                        { label: i18n("None"), value: 0 },
                        { label: i18n("3-day"), value: 3 },
                        { label: i18n("6-day"), value: 6 },
                        { label: i18n("9-day"), value: 9 },
                        { label: i18n("12-day"), value: 12 },
                        { label: i18n("14-day"), value: 14 }
                    ]
                    QQC2.RadioButton {
                        text: modelData.label
                        QQC2.ButtonGroup.group: forecastGroup
                        checked: cfg_forecastDays === modelData.value
                        onClicked: cfg_forecastDays = modelData.value
                    }
                }
            }
        }

        QQC2.Label {
            Kirigami.FormData.isSection: true
            text: i18n("Display")
            font.bold: true
        }

        QQC2.ComboBox {
            id: unitsCombo
            Kirigami.FormData.label: i18n("Units:")
            textRole: "text"
            valueRole: "value"
            model: [
                { text: i18n("Metric (°C, m/s)"), value: "m" },
                { text: i18n("Imperial (°F, mph)"), value: "e" }
            ]

            Component.onCompleted: {
                if (currentValue === "" || currentValue === undefined || currentValue === null) {
                    currentIndex = 0
                }
            }
        }

        QQC2.TextField {
            id: languageField
            Kirigami.FormData.label: i18n("Language:")
            placeholderText: i18n("e.g. en-GB, pt-PT")
            inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
        }

        QQC2.SpinBox {
            id: refreshSpin
            Kirigami.FormData.label: i18n("Refresh (minutes):")
            from: 1
            to: 180
            stepSize: 1
        }
    }
}
