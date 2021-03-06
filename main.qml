import QtQuick 2.7
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.0
import Qt.labs.settings 1.0
import QtGraphicalEffects 1.0

import "md5.js" as MD5
import "."

ApplicationWindow {
    id: root

    visible: true
    width: 1600
    height: 1200
    title: qsTr("Travis Status")

    property string travisToken
    property string githubToken
    property var repositories: [
        {name: "CINPLA/exdir", private: false}
    ]

    property string repositoriesString
    property bool avoidLoop: false

    onTravisTokenChanged: {
        Travis.token = travisToken
    }

    onGithubTokenChanged: {
        Travis.githubToken = githubToken
    }

    Settings {
        property alias repositories: root.repositoriesString
        property alias token: root.travisToken
        property alias githubToken: root.githubToken
    }

    onRepositoriesChanged: {
        if(avoidLoop) {
            return
        }
        avoidLoop = true
        repositoriesString = JSON.stringify(repositories)
        avoidLoop = false
    }

    onRepositoriesStringChanged: {
        if(avoidLoop) {
            return
        }
        avoidLoop = true
        repositories = JSON.parse(repositoriesString)
        avoidLoop = false
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

        spacing: 16

        function add() {
            var repo = {
                name: repoTextField.text,
                branch: branchTextField.text,
                private: privateCheckbox.checked
            }
            root.repositories = root.repositories.concat([repo])
            repoTextField.text = ""
            branchTextField.text = ""
        }

        Label {
            anchors.baseline: repoTextField.baseline
            color: "white"
            text: "Repo:"
        }

        TextField {
            id: repoTextField
            placeholderText: "e.g. CINPLA/exdir"
            onFocusChanged: {
                if(!focus) {
                    hideTimer.restart()
                }
            }

            Keys.onReturnPressed: {
                row.add()
            }
        }

        Label {
            anchors.baseline: repoTextField.baseline
            color: "white"
            text: "Branch:"
        }

        TextField {
            id: branchTextField
            placeholderText: "e.g. dev"
            onFocusChanged: {
                if(!focus) {
                    hideTimer.restart()
                }
            }

            Keys.onReturnPressed: {
                row.add()
            }
        }

        CheckBox {
            id: privateCheckbox
            text: "Private"

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

        Label {
            anchors.baseline: repoTextField.baseline
            text: "Travis token:"
        }

        TextField {
            id: tokenText
            text: root.travisToken
            Binding {
                target: root
                property: "travisToken"
                value: tokenText.text
            }
            Binding {
                target: tokenText
                property: "text"
                value: root.travisToken
            }
        }

        Button {
            text: "Generate token"
            onClicked: {
                tokenDialog.open()
            }
        }

        Label {
            anchors.baseline: repoTextField.baseline
            text: "GitHub token:"
        }

        TextField {
            id: githubTokenText
            text: root.githubToken
            Binding {
                target: root
                property: "githubToken"
                value: githubTokenText.text
            }
            Binding {
                target: githubTokenText
                property: "text"
                value: root.githubToken
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
        height: row.height
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

    Dialog {
        id: tokenDialog
        TextArea {
            anchors.fill: parent
            selectByMouse: true
            text: "Generate a GitHub token with access to private repos.\n" +
                  "Run the following command:\n\n" +
                  "curl -H 'Content-Type: application/json' -d " +
                  "'{\"github_token\":\"<your token>\"}' -H 'User-Agent: Travis/1.0' " +
                  "https://api.travis-ci.com/auth/github\n\n" +
                  "This results in something like '{\"access_token\": \"...\"}'. Copy and paste only the resulting token here."
        }
    }

    Timer {
        id: hideTimer
        interval: 1000
        onTriggered: {
            if(repoTextField.activeFocus || topMouseArea.containsMouse) {
                return
            }
            row.revealed = false
        }
    }
}
