import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Dialogs
import org.kde.kirigami as Kirigami

QQC2.ScrollView {
    id: root

    contentWidth: availableWidth

    property alias cfg_drive1Label: drive1LabelField.text
    property alias cfg_drive1Device: drive1DeviceField.text
    property alias cfg_drive1ReadColor: drive1ReadSwatch.color
    property alias cfg_drive1WriteColor: drive1WriteSwatch.color
    property alias cfg_drive1MaxMiB: drive1MaxSpin.value

    property alias cfg_drive2Label: drive2LabelField.text
    property alias cfg_drive2Device: drive2DeviceField.text
    property alias cfg_drive2ReadColor: drive2ReadSwatch.color
    property alias cfg_drive2WriteColor: drive2WriteSwatch.color
    property alias cfg_drive2MaxMiB: drive2MaxSpin.value

    property alias cfg_drive3Label: drive3LabelField.text
    property alias cfg_drive3Device: drive3DeviceField.text
    property alias cfg_drive3ReadColor: drive3ReadSwatch.color
    property alias cfg_drive3WriteColor: drive3WriteSwatch.color
    property alias cfg_drive3MaxMiB: drive3MaxSpin.value

    property alias cfg_drive4Label: drive4LabelField.text
    property alias cfg_drive4Device: drive4DeviceField.text
    property alias cfg_drive4ReadColor: drive4ReadSwatch.color
    property alias cfg_drive4WriteColor: drive4WriteSwatch.color
    property alias cfg_drive4MaxMiB: drive4MaxSpin.value

    property alias cfg_trackColor: trackSwatch.color
    property alias cfg_updateInterval: intervalSpin.value
    property alias cfg_barLength: barLengthSpin.value
    property alias cfg_barThickness: barThicknessSpin.value
    property alias cfg_smoothingPercent: smoothingSpin.value

    // Reusable color-swatch + picker row. Single direct child of the
    // FormLayout (the RowLayout itself), so its FormData.label applies.
    component ColorRow: RowLayout {
        id: colorRow
        property alias color: swatch.color

        Rectangle {
            id: swatch
            width: Kirigami.Units.gridUnit * 1.6
            height: Kirigami.Units.gridUnit * 1.6
            radius: 4
            border.width: 1
            border.color: Kirigami.Theme.disabledTextColor

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: colorDialog.open()
            }
        }

        QQC2.Button {
            text: i18n("Choose…")
            onClicked: colorDialog.open()
        }

        ColorDialog {
            id: colorDialog
            options: ColorDialog.ShowAlphaChannel
            selectedColor: swatch.color
            onAccepted: swatch.color = selectedColor
        }
    }

    Kirigami.FormLayout {
        width: root.availableWidth
        // --- Drive 1 ---
    Kirigami.Separator { Kirigami.FormData.label: i18n("Drive 1"); Kirigami.FormData.isSection: true }
    QQC2.TextField {
        id: drive1LabelField
        Kirigami.FormData.label: i18n("Display name:")
    }
    QQC2.TextField {
        id: drive1DeviceField
        Kirigami.FormData.label: i18n("Block device (e.g. nvme0n1, sdb2):")
        placeholderText: i18n("run 'lsblk' to find this")
    }
    ColorRow {
        id: drive1ReadSwatch
        Kirigami.FormData.label: i18n("Read color:")
    }
    ColorRow {
        id: drive1WriteSwatch
        Kirigami.FormData.label: i18n("Write color:")
    }
    QQC2.SpinBox {
        id: drive1MaxSpin
        Kirigami.FormData.label: i18n("Max throughput / top of bar (MiB/s):")
        from: 1
        to: 10000
        stepSize: 10
        editable: true
    }

    // --- Drive 2 ---
    Kirigami.Separator { Kirigami.FormData.label: i18n("Drive 2"); Kirigami.FormData.isSection: true }
    QQC2.TextField {
        id: drive2LabelField
        Kirigami.FormData.label: i18n("Display name:")
    }
    QQC2.TextField {
        id: drive2DeviceField
        Kirigami.FormData.label: i18n("Block device (e.g. nvme0n1, sdb2):")
        placeholderText: i18n("run 'lsblk' to find this")
    }
    ColorRow {
        id: drive2ReadSwatch
        Kirigami.FormData.label: i18n("Read color:")
    }
    ColorRow {
        id: drive2WriteSwatch
        Kirigami.FormData.label: i18n("Write color:")
    }
    QQC2.SpinBox {
        id: drive2MaxSpin
        Kirigami.FormData.label: i18n("Max throughput / top of bar (MiB/s):")
        from: 1
        to: 10000
        stepSize: 10
        editable: true
    }

    // --- Drive 3 ---
    Kirigami.Separator { Kirigami.FormData.label: i18n("Drive 3"); Kirigami.FormData.isSection: true }
    QQC2.TextField {
        id: drive3LabelField
        Kirigami.FormData.label: i18n("Display name:")
    }
    QQC2.TextField {
        id: drive3DeviceField
        Kirigami.FormData.label: i18n("Block device (e.g. nvme0n1, sdb2):")
        placeholderText: i18n("run 'lsblk' to find this")
    }
    ColorRow {
        id: drive3ReadSwatch
        Kirigami.FormData.label: i18n("Read color:")
    }
    ColorRow {
        id: drive3WriteSwatch
        Kirigami.FormData.label: i18n("Write color:")
    }
    QQC2.SpinBox {
        id: drive3MaxSpin
        Kirigami.FormData.label: i18n("Max throughput / top of bar (MiB/s):")
        from: 1
        to: 10000
        stepSize: 10
        editable: true
    }

    // --- Drive 4 ---
    Kirigami.Separator { Kirigami.FormData.label: i18n("Drive 4"); Kirigami.FormData.isSection: true }
    QQC2.TextField {
        id: drive4LabelField
        Kirigami.FormData.label: i18n("Display name:")
    }
    QQC2.TextField {
        id: drive4DeviceField
        Kirigami.FormData.label: i18n("Block device (e.g. nvme0n1, sdb2):")
        placeholderText: i18n("run 'lsblk' to find this")
    }
    ColorRow {
        id: drive4ReadSwatch
        Kirigami.FormData.label: i18n("Read color:")
    }
    ColorRow {
        id: drive4WriteSwatch
        Kirigami.FormData.label: i18n("Write color:")
    }
    QQC2.SpinBox {
        id: drive4MaxSpin
        Kirigami.FormData.label: i18n("Max throughput / top of bar (MiB/s):")
        from: 1
        to: 10000
        stepSize: 10
        editable: true
    }

    // --- Appearance ---
    Kirigami.Separator { Kirigami.FormData.label: i18n("Appearance"); Kirigami.FormData.isSection: true }

    ColorRow {
        id: trackSwatch
        Kirigami.FormData.label: i18n("Unused bar (track) color:")
    }

    QQC2.SpinBox {
        id: intervalSpin
        Kirigami.FormData.label: i18n("Update interval (seconds):")
        from: 1
        to: 60
        stepSize: 1
    }

    QQC2.SpinBox {
        id: barLengthSpin
        Kirigami.FormData.label: i18n("Bar length / height (px):")
        from: 30
        to: 400
        stepSize: 10
    }

    QQC2.SpinBox {
        id: barThicknessSpin
        Kirigami.FormData.label: i18n("Bar thickness / width (px):")
        from: 2
        to: 60
        stepSize: 1
    }

    QQC2.SpinBox {
        id: smoothingSpin
        Kirigami.FormData.label: i18n("Responsiveness (%, lower = smoother/less flicker):")
        from: 5
        to: 100
        stepSize: 5
    }
}
}
