import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.0
import Qt.labs.settings 1.0

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

    Row {
        id: row
        anchors {
            left: parent.left
            top: parent.top
            margins: 16
        }

        TextField {
            id: textField
            placeholderText: "Repository name, e.g. CINPLA/exdir"
            Keys.onReturnPressed: {
                root.repositories = root.repositories.concat([{name: text}])
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
            Rectangle {
                id: background
                property var result: {
                    return {
                        "repo": {
                            "last_build_state": "unknown"
                        }
                    }
                }
                property bool valid: result["repo"] ? true : false

                color: {
                    // extra #2D95BF
                    var unknown = "#955BA5"
                    if(!valid) {
                        return unknown
                    }
                    var map = {
                        "passed": "#4EBA6F",
                        "created": "#F0C419",
                        "started": "#F0C419",
                        "errored": "#454545",
                        "failed": "#F15A5A"
                    }
                    return map[result["repo"]["last_build_state"]] || unknown
                }

                Layout.fillHeight: true
                Layout.fillWidth: true

                Component.onCompleted: {
                    refresh()
                }

                function refresh() {
                    var req = new XMLHttpRequest()
                    req.onreadystatechange = function() {
                        if(req.readyState !== XMLHttpRequest.DONE) {
                            return
                        }
                        console.log(modelData.name, req.responseText)
                        result = JSON.parse(req.responseText)

                    }
                    req.open("GET", "https://api.travis-ci.org/repos/" + modelData.name)
                    req.setRequestHeader("Accept", "application/vnd.travis-ci.2+json")
                    req.send()
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Qt.openUrlExternally("https://travis-ci.org/" + modelData.name)
                    }
                }

                Text {
                    anchors {
                        fill: parent
                        margins: 8
                    }

                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: Math.min(width, height) * 0.20
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    color: "white"
                    text: modelData.name.split("/").join("\n")
                }

                Text {
                    anchors {
                        right: parent.right
                        top: parent.top
                        margins: 8
                    }
                    font.pixelSize: background.height * 0.10
                    visible: mouseArea.containsMouse
                    color: "red"
                    text: "x"
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            for(var i in root.repositories) {
                                var repo = root.repositories[i]
                                if(repo.name === modelData.name) {
                                    var newRepositories = root.repositories
                                    newRepositories.splice(i, 1)
                                    root.repositories = newRepositories
                                    return
                                }
                            }
                        }
                    }
                }

                Timer {
                    interval: 60000
                    repeat: true
                    running: true
                    onTriggered: refresh()
                }

            }
        }
    }
    }
}
