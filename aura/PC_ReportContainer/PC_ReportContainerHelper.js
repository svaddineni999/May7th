({
	setNamespace : function(cmp) {
            var component_to_string = cmp.toString();
            var markupTagLoc = component_to_string.indexOf('markup://');
            var endOfNamespaceLoc = component_to_string.indexOf(':',markupTagLoc+9);
            var ns = component_to_string.substring(markupTagLoc+9,endOfNamespaceLoc);
            var namespacePrefix = (ns == "c" || ns == "C") ?  "" :  ns + "__";
            cmp.set("v.namespace", ns);
            cmp.set("v.namespacePrefix", namespacePrefix);
        },
        replacePCNamespace : function(cmp) {
                    var reportDevName = cmp.get("v.developerName");
                    console.log("v.developerName = " + reportDevName);
                    var matchRegex = /PatientConnectNamespace__/i;
                    if(reportDevName != null && reportDevName != undefined && reportDevName.search(matchRegex) == 0) {
                        var newReportDevName = reportDevName.replace(matchRegex,cmp.get("v.namespacePrefix"));
                        cmp.set("v.developerName",newReportDevName);
                        console.log("new v.developerName = " + newReportDevName);
                    }
                }

})