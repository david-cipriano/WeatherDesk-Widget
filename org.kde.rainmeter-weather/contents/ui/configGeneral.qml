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

    //forest 6 days, 3 days of none
    //choose font


    Kirigami.FormLayout {
        id: form
        anchors.fill: parent

        QQC2.Label {
            Kirigami.FormData.isSection: true
            text: i18n("Weather.com")
        }

        QQC2.TextField {
            id: apiKeyField
            Kirigami.FormData.label: i18n("API key:")
            placeholderText: i18n("Paste your Weather.com API key")
        }

        QQC2.Label {
            Kirigami.FormData.isSection: true
            text: i18n("Location")
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
            text: i18n("Display")
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

            // currentValue exists because we set valueRole above.
            // Provide a safe default if empty.
            Component.onCompleted: {
                if (currentValue === "" || currentValue === undefined || currentValue === null) {
                    // default metric
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
