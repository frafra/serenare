import QtQuick 2.4
import QtQuick.Controls 1.3
import QtQuick.Window 2.2
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.1
import Qt.WebSockets 1.0
//import Qt.labs.settings 1.0

ApplicationWindow {
    title: qsTr("Serenare 0.1")
    width: 640
    height: 480
    visible: true

    /*menuBar: MenuBar {
        Menu {
            title: qsTr("&File")
            MenuItem {
                text: qsTr("&Open")
                onTriggered: messageDialog.show(qsTr("Open action triggered"));
            }
            MenuItem {
                text: qsTr("E&xit")
                onTriggered: Qt.quit();
            }
        }
    }*/

    function sendUserInput() {
        var widget = textInput;
        socket.sendTextMessage(widget.text);
        widget.text = "";
    }

    function escapeHtml(unsafe) {
        return unsafe
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#039;');
    }

    function generic(part) {
        return '<span style="color: lightgrey; font-size: small;">'+escapeHtml(part)+'</span>';
    }

    // TODO: replace '\t'
    function parse(message) {
        console.log(message);
        switch (message.substring(0, 1)) {
        case 'S': // First message
            break;
        case '': // Empty message
            break;
        case '[':
            var timestamp = message.substring(1, 20);
            var type = message.substring(23, 24);
            var part = message.substring(26);
            switch (type) {
            case 'C':
                var sepPos = part.indexOf('>');
                var user = escapeHtml(part.substring(0, sepPos));
                var text = escapeHtml(part.substring(sepPos+1));
                var line = '<span style="color: lightblue;">'+user+'</span>' +
                        ' <span>'+text+'</span>';
                messageBox.append(line);
                break;
            case 'G':
                var parts = part.split(' ');
                if ((part.substring(part.length-17) === 'accepted the call') ||
                        (part.substring(part.length-25) === 'has joined the conference')) {
                    var parts = part.split(' ');
                    if (parts[2][0] !== '(') {
                        return; // No username is provided
                    }
                    var user = parts[1];
                    var host = parts[2].substring(1, parts[2].length-1);
                    userListModel.append({'username':user});
                } else if (parts[3]+' '+parts[4] === 'has left') {
                    var user = parts[1];
                    for (var i=0; i<userListModel.count; i++) {
                        if (userListModel.get(i)['username'] === user) {
                            userListModel.remove(i);
                            break;
                        }
                    }
                } else if (parts[1] === 'Mute:') {
                    micStatus.checked = parts[2] === 'off';
                } else {
                    messageBox.append(generic(part));
                }
                break;
            case 'I':
                messageBox.append(generic(part));
                break;
            default:
                console.log("^ Unknown message type!")
            }
            break;
        default: // Multipart or something strange
            messageBox.append(generic(message));
            break;
        }
    }

    toolBar: ToolBar {
        RowLayout {
            anchors.fill: parent
            /*ToolButton {
                text: "Placeholder"
            }*/
            Item {
                Layout.fillWidth: true
            }
            CheckBox {
                id: micStatus
                text: qsTr("Microphone")
                checked: true
                onClicked: {
                    socket.sendTextMessage('/m');
                    // It should prevent default action
                }
            }
        }
    }

    ListModel {
        id: userListModel
    }

    ColumnLayout {
        anchors.fill: parent
        RowLayout {
            TextArea {
                id: messageBox
                readOnly: true
                textFormat: TextEdit.RichText
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
            TableView {
                id: userListView
                model: userListModel
                TableViewColumn {
                    role: 'username'
                    title: qsTr("Users")
                }
                Layout.fillHeight: true
            }
        }
        RowLayout {
            TextField {
                id: textInput
                Layout.fillWidth: true
                Keys.onReturnPressed: sendUserInput()
            }
            Button {
                text: "Send"
                onClicked: sendUserInput()
            }
        }
    }

    statusBar: StatusBar {
        Label {
            id: statusBar
            text: qsTr("Starting...")
        }
    }

    WebSocket {
        id: socket
        url: "ws://localhost:8100"
        active: true
        onTextMessageReceived: parse(message);
        onStatusChanged: {
            if (status == WebSocket.Error) {
                statusBar.text = qsTr("Error message: ") + errorString;
            } else if (status == WebSocket.Open) {
                statusBar.text = qsTr("WebSocket connection open");
            } else if (status == WebSocket.Closed) {
                statusBar.text = qsTr("WebSocket connection closed");
            } else {
                statusBar.text = qsTr("Status code: ") + status;
            }
        }
    }

    /*Component.onCompleted: {
        socket.active = true;
    }*/

    /*Settings {
        id: settings
        property alias address1: textField1.text
    }*/
}
