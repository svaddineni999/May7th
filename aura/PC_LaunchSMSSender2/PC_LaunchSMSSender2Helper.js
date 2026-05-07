/**
 * Created by cmohapatra on 12/4/2020.
 */
({
    setNamespace : function(component, event, helper) {
        var ns = CH_PC_Util.getNamespace(component);
        var nsPrefix = CH_PC_Util.getNamespacePrefix(component);
        component.set("v.namespace", ns);
        component.set("v.namespacePrefix", nsPrefix);
    },

    launchSMSSender : function(component, event, helper){
        var workspaceAPI = component.find("smsSenderLaunchWorkspace");

        var recordId = component.get('v.recordId');
        var namespace = component.get("v.namespace");
        var componentAPIName =  namespace+'__'+component.get("v.messageComponentName");
        var pageAPIName = component.get("v.namespacePrefix") +component.get("v.messagePageName");

        var qualifiedIdName = CH_PC_Util.getQualifiedQueryParam(component,'recordId',namespace);

        var tabParamsObject = new Object();
        tabParamsObject.uid = 'EL-'+recordId;
        tabParamsObject[qualifiedIdName] = recordId;

        var urlParams = '?'+qualifiedIdName+'='+recordId;

        workspaceAPI.isConsoleNavigation().then(function(isConsole) {
            if (isConsole) {
                // this block of code helps to open the component in new console tab if it is console app
               CH_PC_Util.openLightningComponentInNewTab(workspaceAPI,componentAPIName,pageAPIName,tabParamsObject,
              component.get("v.messageTabLabel"),component.get("v.messageTabIcon"),true,urlParams);
            }
            else {
                // this block of code helps to open the component in new tab if it is lightning app
                var url = '/lightning/cmp/' + componentAPIName + urlParams;
                window.open(url,"_blank");
            }
        })
        .catch(function(error) {
            console.log(error);
        });
    }

})