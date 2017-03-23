import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.0
import QtQuick.Particles 2.0
import Qt.labs.settings 1.0

import "md5.js" as MD5
import "."

Item {
    id: background
    property real scalar: Math.min(background.width, background.height) * 0.20
    property bool alternativeColor: true
    property bool facepalm: true
    property string buildState: "unknown"
    property string authorEmail: "@"
    property string commitMessage: ""
    property var milestones: []

    clip: true

    Component.onCompleted: {
        quickRefreshTimer.start()
    }

    function refreshMilestones() {
        var endpoint = "https://api.github.com/"
        var req = new XMLHttpRequest()
        req.onreadystatechange = function() {
            if(req.readyState !== XMLHttpRequest.DONE) {
                return
            }
            console.log("GitHub response on", modelData.name, req.responseText)
            var result = JSON.parse(req.responseText)
            if(!result.length) {
                milestones = []
                return
            }
            result.sort(function(a, b) {
                if(a.due_on === null) {
                    return 1
                }
                if(b.due_on === null) {
                    return -1
                }
                return a.due_on > b.due_on ? 1 : -1
            })
            milestones = result
        }
        req.open("GET", endpoint + "repos/" + modelData.name + "/milestones?sort=due_on&direction=asc")
        req.setRequestHeader("Accept", "application/vnd.github.v3+json")
        req.setRequestHeader("Authorization", "token " + Travis.githubToken)
        console.log("Authorization", "token " + Travis.githubToken)
        req.send()
    }

    function refresh() {
        if(modelData.name === "test/test") {
            buildState = "started"
            return
        }
        var endpoint = "https://api.travis-ci.org/"
        if(modelData.private) {
            endpoint = "https://api.travis-ci.com/"
        }
        if(modelData.private && !Travis.token) {
            quickRefreshTimer.restart()
            return
        }
        var req = new XMLHttpRequest()
        req.onreadystatechange = function() {
            if(req.readyState !== XMLHttpRequest.DONE) {
                return
            }
            console.log(modelData.name, req.responseText)
            var result = JSON.parse(req.responseText)
            if(!result["branch"] || !result["commit"]) {
                buildState = "unknown"
                console.log("Response missing branch or commit!")
                return
            }
            buildState = result["branch"]["state"]
            authorEmail = result["commit"]["author_email"]
            commitMessage = result["commit"]["message"]
        }
        req.open("GET", endpoint + "repos/" + modelData.name + "/branches/" + modelData.branch)
        req.setRequestHeader("Accept", "application/vnd.travis-ci.2+json")
        if(modelData.private) {
            req.setRequestHeader("Authorization", "token " + Travis.token)
        }
        req.send()

        refreshMilestones()
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
//            Qt.openUrlExternally("https://travis-ci.org/" + modelData.name)
            toggleState()
        }
    }

    Rectangle {
        id: backgroundRectangle
        anchors.fill: parent
        color: {
            // extra #2D95BF
            var unknown = "#955BA5"
            var map = {
                "passed": "#4EBA6F",
                "created": "#F0C419",
                "started": alternativeColor ? "#FF9409" : "#F0C419",
                                              "errored": "#454545",
                                              "failed": "#F15A5A"
            }
            return map[buildState] || unknown
        }

        Behavior on color {
            ColorAnimation {
                duration: 800
                easing.type: Easing.InOutQuad
            }
        }
    }

    Image {
        id: facepalmImage
        anchors.fill: parent
        source: "http://i.imgur.com/iWKad22.jpg"
        visible: buildState === "errored" || buildState === "failed"
        fillMode: Image.PreserveAspectCrop
        opacity: 0.0
        SequentialAnimation {
            id: facepalmAnimation
            NumberAnimation {
                from: 0
                to: 0.5
                target: facepalmImage
                property: "opacity"
                duration: 2000
                easing.type: Easing.InOutQuad
            }
            PauseAnimation {
                duration: 4000
            }
            NumberAnimation {
                from: 0.5
                to: 0
                target: facepalmImage
                property: "opacity"
                duration: 2000
                easing.type: Easing.InOutQuad
            }
        }

        Text {
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: parent.width * 0.01
            }
            fontSizeMode: Text.Fit
            horizontalAlignment: Text.AlignHCenter
            color: "white"
            font.pixelSize: parent.height * 0.05
            text: "Hvordan syns du at det gikk?"
        }
    }


    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        Item {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Text {
                anchors {
                    fill: parent
                    margins: scalar * 0.2
                }
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: scalar * 0.6
                fontSizeMode: Text.Fit
//                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                color: "#dcdcdc"

                text: modelData.name.split("/")[0]
            }
        }

        Item {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Text {
                anchors {
                    fill: parent
                    margins: scalar * 0.2
                }

                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: scalar
                fontSizeMode: Text.Fit
//                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                color: "#efefef"

                text: modelData.name.split("/")[1]
            }
        }

        Item {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Text {
                anchors {
                    fill: parent
                    margins: scalar * 0.2
                }
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: scalar * 0.4
                fontSizeMode: Text.Fit
//                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                color: "#cbcbcb"

                text: modelData.branch
            }
        }

        Item {
            Layout.fillHeight: buildState === "errored" || buildState === "failed"
            Layout.fillWidth: true
            Text {
                anchors {
                    fill: parent
                    margins: scalar * 0.2
                }
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                font.pixelSize: scalar * 0.46
                fontSizeMode: Text.Fit
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: "#efefef"
                visible: buildState === "errored" || buildState === "failed"

                //                    text: authorEmail.split("@")[0]
                text: authorEmail + ': "' + commitMessage + '"'
            }
        }
    }

    ColumnLayout {
        id: secondaryLayout
        anchors.fill: parent
        spacing: 0
        opacity: 0

        Item {
            Layout.fillHeight: true
            Layout.fillWidth: true
            height: 1

            Text {
                anchors {
                    fill: parent
                    margins: scalar * 0.2
                }
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: scalar * 0.6
                fontSizeMode: Text.Fit
//                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                color: "#dcdcdc"

                text: modelData.name.split("/")[1]
            }
        }

        Repeater {
            model: milestones
            Item {
                property int open: modelData.open_issues
                property int closed: modelData.closed_issues
                property int total: open + closed
                property real closedRatio: closed / total
                height: 1
                Layout.fillHeight: true
                Layout.fillWidth: true
                Rectangle {
                    anchors {
                        left: parent.left
                        top: parent.top
                        bottom: parent.bottom
                    }
                    color: Qt.rgba(0, 1, 0, 0.2)
                    width: closedRatio * parent.width
                }
                Text {
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: counter.left
                        bottom: parent.bottom
                        margins: scalar * 0.1
                    }

                    fontSizeMode: Text.Fit
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: scalar * 0.4
                    minimumPixelSize: 1
                    text: modelData.title
                    color: "white"
                }

                Text {
                    id: counter
                    anchors {
                        top: parent.top
                        right: parent.right
                        bottom: parent.bottom
                        margins: scalar * 0.1
                    }

                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignVCenter
                    fontSizeMode: Text.Fit
                    font.pixelSize: scalar * 0.4
                    minimumPixelSize: 1
                    text: closed + " of " + total
                    color: "white"
                }
            }
        }

        Item {
            height: 1
            Layout.fillHeight: true
            Layout.fillWidth: true
        }
    }

    states: [
        State {
            name: "secondary"
            PropertyChanges {
                target: mainLayout
                opacity: 0
            }
            PropertyChanges {
                target: secondaryLayout
                opacity: 1
            }
        }
    ]

    transitions: [
        Transition {
            NumberAnimation {
                property: "opacity"
                duration: 1200
                easing.type: Easing.InOutQuad
            }
        }
    ]

    Text {
        anchors {
            top: parent.top
            right: parent.right
            margins: 8
        }

        font.pixelSize: background.height * 0.10
        fontSizeMode: Text.Fit
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

    function toggleState() {
        if(state == "secondary") {
            state = ""
        } else {
            state = "secondary"
        }
    }

    Timer {
        running: milestones.length > 0
        interval: 20 * 1000 + 1000 * Math.random()
        repeat: true
        onTriggered: toggleState()
    }
    
    Timer {
        interval: 30 * 1000 + 1000 * Math.random()
        repeat: true
        running: facepalmImage.visible
        onTriggered: facepalmAnimation.restart()
    }
    
    Timer {
        interval: 1200 + 200 * Math.random()
        repeat: true
        running: true
        onTriggered: alternativeColor = !alternativeColor
    }
    
    Timer {
        interval: 60 * 1000 + 1000 * Math.random()
        repeat: true
        running: true
        onTriggered: refresh()
    }

    Timer {
        id: quickRefreshTimer
        repeat: false
        running: false
        interval: 1 * 1000
        onTriggered: refresh()
    }
}
