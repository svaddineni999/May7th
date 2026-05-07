/*recoverableErrorController.js*/
({
    /*throwErrorHelper: function(cmp) {
        $A.createComponents([
                ["ui:message", {
                    "title": $A.get("$Label.c.PC_Fatal_Error_Warning"),
                    "severity": "error",
                }],
                ["ui:outputText", {
                    "value": $A.get("$Label.c.PC_Lighting_Error_Message")
                }]
            ],
            function(components, status, errorMessage) {
                if (status === "SUCCESS") {
                    var message = components[0];
                    var outputText = components[1];
                    // set the body of the ui:message to be the ui:outputText
                    message.set("v.body", outputText);
                    var errorMessage = cmp.find("errorMessage");
                    // Replace div body with the dynamic component
                    errorMessage.set("v.body", message);
                } else if (status === "INCOMPLETE") {
                    console.log("No response from server or client is offline.");
                    // Show offline error
                } else if (status === "ERROR") {
                    console.log("Error: " + errorMessage);
                    // Show error message
                }
            }
        );
    }*/
})