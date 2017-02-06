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

    clip: true
    
    Component.onCompleted: {
        refresh()
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
            if(result["repo"]) {                
                var req2 = new XMLHttpRequest()
                req2.onreadystatechange = function() {
                    if(req2.readyState !== XMLHttpRequest.DONE) {
                        return
                    }
                    console.log(modelData.name, req2.responseText)
                    var build = JSON.parse(req2.responseText)
                    buildState = build["build"]["state"]
                    authorEmail = build["commit"]["author_email"]
                    commitMessage = build["commit"]["message"]
                }
                var url2 = endpoint + "builds/" + result["repo"]["last_build_id"]
                console.log("Getting", url2)
                req2.open("GET", url2)
                req2.setRequestHeader("Accept", "application/vnd.travis-ci.2+json")
                if(modelData.private) {
                    req2.setRequestHeader("Authorization", "token " + Travis.token)
                }
                req2.send()
            }
        }
        req.open("GET", endpoint + "repos/" + modelData.name)
        req.setRequestHeader("Accept", "application/vnd.travis-ci.2+json")
        if(modelData.private) {
            req.setRequestHeader("Authorization", "token " + Travis.token)
        }
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
                to: 0.2
                target: facepalmImage
                property: "opacity"
                duration: 2000
                easing.type: Easing.InOutQuad
            }
            PauseAnimation {
                duration: 2000
            }
            NumberAnimation {
                from: 0.2
                to: 0
                target: facepalmImage
                property: "opacity"
                duration: 2000
                easing.type: Easing.InOutQuad
            }
        }
    }
    
    Text {
        id: organizationNameText
        anchors {
            bottom: repositoryNameText.top
            left: parent.left
            right: parent.right
            margins: 16
        }
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: scalar * 0.6
        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        color: "#dcdcdc"
        
        text: modelData.name.split("/")[0]
    }
    
    Text {
        id: repositoryNameText
        anchors {
            verticalCenter: parent.verticalCenter
            left: parent.left
            right: parent.right
            margins: 16
        }
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: scalar
        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        color: "#efefef"
        
        text: modelData.name.split("/")[1]
    }
    
    Text {
        anchors {
            top: repositoryNameText.bottom
            left: parent.left
            right: parent.right
            margins: 16
        }
        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        font.pixelSize: scalar * 0.46
        horizontalAlignment: Text.AlignHCenter
        color: "#efefef"
        visible: buildState === "errored" || buildState === "failed"
        
        //                    text: authorEmail.split("@")[0]
        text: authorEmail + ': "' + commitMessage + '"'
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
