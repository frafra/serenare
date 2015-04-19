import QtQuick 2.4
import QtQuick.Controls 1.3
import QtQuick.Window 2.2
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.1
import io.thp.pyotherside 1.4

ApplicationWindow {
    title: qsTr("Serenare 0.3-dev")
    width: 640
    height: 480
    visible: true

    function send(message) {
        python.call('serenare.writeInput', [message]);
    }

    function sendUserInput() {
        var widget = textInput;
        send(widget.text);
        widget.text = "";
    }

    function generic(part) {
        return '<span style="color: lightgrey; font-size: small;">'+part+'</span>';
    }

    toolBar: ToolBar {
        RowLayout {
            anchors.fill: parent
            Item {
                Layout.fillWidth: true
            }
            CheckBox {
                id: recStatus
                text: qsTr("Recording")
                checked: false
                onClicked: {
                    send('/r');
                }
            }
            CheckBox {
                id: micStatus
                text: qsTr("Microphone")
                checked: true
                onClicked: {
                    send('/m');
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

    Python {
        id: python
        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl('.'));
            importModule('serenare', function () {
                call('serenare.startSeren');
            });
        }
        onError: {
            console.log("Error: " + traceback);
            Qt.quit();
        }
        onReceived: {
            switch (data[0]) {
                case 'generic':
                    messageBox.append(generic(data[1]));
                    break;
                case 'message':
                    var user = data[2];
                    var text = data[3];
                    messageBox.append('<span style="color: lightblue;">'+user+'</span>' +
                                      ' <span>'+text+'</span>');
                    break;
                case 'node-join':
                    var user = data[2];
                    userListModel.append({'username':user});
                    break;
                case 'node-left':
                    var user = data[2];
                    for (var i=0; i<userListModel.count; i++) {
                        if (userListModel.get(i)['username'] === user) {
                            userListModel.remove(i);
                            break;
                        }
                    }
                    break;
                case 'mute':
                    micStatus.checked = data[1] === 'off';
                    break;
                case 'recording':
                    recStatus.checked = data[1] === 'on';
                    break;
            }
            console.log(data);
        }
    }
}
