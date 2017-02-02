import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.0
import Qt.labs.settings 1.0
import QtGraphicalEffects 1.0

import "md5.js" as MD5

ApplicationWindow {
    id: root

    visible: true
    width: 1600
    height: 1200
    title: qsTr("Travis Status")

    property var repositories: [
        {name: "CINPLA/exdir"}
    ]

    property string repositoriesString

    Settings {
        property alias repositories: root.repositoriesString
    }

    Binding {
        target: root
        property: "repositories"
        value: JSON.parse(repositoriesString)
    }

    Binding {
        target: root
        property: "repositoriesString"
        value: JSON.stringify(repositories)
    }

    Rectangle {
        anchors.fill: parent
        color: "#121212"
    }

    Row {
        id: row

        property bool revealed: false

        anchors {
            left: parent.left
            top: parent.top
            topMargin: revealed ? anchors.margins : -height
            margins: 16
        }

        spacing: 8

        function add() {
            root.repositories = root.repositories.concat([{name: text}])
            text = ""
        }

        Label {
            anchors.baseline: textField.baseline
            color: "white"
            text: "Add another repository:"
        }

        TextField {
            id: textField
            placeholderText: "e.g. CINPLA/exdir"
            Keys.onReturnPressed: {
                row.add()
            }
        }

        Button {
            text: "Add"
            onClicked: {
                row.add()
            }
        }

        Behavior on anchors.topMargin {
            NumberAnimation {
                duration: 600
                easing.type: Easing.InOutQuad
            }
        }
    }

    GridLayout {
        anchors {
            left: parent.left
            right: parent.right
            top: row.bottom
            bottom: parent.bottom
            margins: 16
        }
        columnSpacing: 16
        rowSpacing: 16
        columns: 4

        Repeater {
            model: repositories
            RepositoryDelegate {
                id: background
                Layout.fillHeight: true
                Layout.fillWidth: true
            }
        }
    }

    MouseArea {
        id: topMouseArea
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: row.height * 2
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onEntered: {
            hideTimer.stop()
            row.revealed = true
        }
        onExited: {
            hideTimer.restart()
        }
    }

    Timer {
        id: hideTimer
        interval: 1000
        onTriggered: {
            row.revealed = false
        }
    }
}
