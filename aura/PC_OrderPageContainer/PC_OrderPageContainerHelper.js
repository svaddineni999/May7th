({
    launchOrderInNewTab : function(component, event, helper) {
        var recordId = component.get('v.recordId');
        component.set("v.programId",component.get("v.recordId"));
        var programId = component.get("v.programId");
        var fsOrderDetails = component.get("v.fsOrderDetails");
        var fsProduct = component.get("v.fsProduct");
        var fsOrderItem = component.get("v.fsOrderItem");
        var fsOrderShipment = component.get("v.fsOrderShipment");
        if(!$A.util.isEmpty(component.get("v.programId"))){
            var blnk = '';
            recordId = blnk;
            component.set("v.recordId",recordId);
        }
        var namespace = component.get("v.namespace");
        var componentAPIName =  namespace+'__'+component.get("v.orderComponentName");
        var pageAPIName = component.get("v.namespacePrefix") +component.get("v.orderPageName");
        var qualifiedIdName = CH_PC_Util.getQualifiedQueryParam(component,'recordId',namespace);
        var qualifiedProgramIdName = CH_PC_Util.getQualifiedQueryParam(component,'programId',namespace);
        var qualifiedFSOrderDetailsName = CH_PC_Util.getQualifiedQueryParam(component,'fsOrderDetails',namespace);
        var qualifiedFSProductName = CH_PC_Util.getQualifiedQueryParam(component,'fsProduct',namespace);
        var qualifiedFSOrderItemName = CH_PC_Util.getQualifiedQueryParam(component,'fsOrderItem',namespace);
        var qualifiedFSOrderShipmentName = CH_PC_Util.getQualifiedQueryParam(component,'fsOrderShipment',namespace);
        var qualifiedOpenInNewTabName = CH_PC_Util.getQualifiedQueryParam(component,'openInNewTab',namespace);

        var tabParamsObject = new Object();
        tabParamsObject[qualifiedIdName] = recordId;
        tabParamsObject[qualifiedProgramIdName] = programId;
        tabParamsObject[qualifiedFSOrderDetailsName] = fsOrderDetails;
        tabParamsObject[qualifiedFSProductName] = fsProduct;
        tabParamsObject[qualifiedFSOrderItemName] = fsOrderItem;
        tabParamsObject[qualifiedFSOrderShipmentName] = fsOrderShipment;
        tabParamsObject[qualifiedOpenInNewTabName] = false;

        var urlParams = '?'+qualifiedIdName+'='+recordId +'&'+ qualifiedProgramIdName +'='+ programId +'&'+ qualifiedFSOrderDetailsName +'='+ fsOrderDetails +'&'+ qualifiedFSProductName +'='+ fsProduct + '&'+ qualifiedFSOrderItemName +'='+ fsOrderItem + '&'+ qualifiedFSOrderShipmentName +'='+ fsOrderShipment +'&' +qualifiedOpenInNewTabName+'=false&';

        var workspaceAPI = component.find("orderWorkspace");
        workspaceAPI.isConsoleNavigation().then(function(isConsole) {
            if (isConsole) {
                // this block of code helps to open the component in new console tab if it is console app
                CH_PC_Util.openLightningComponentInNewTab(workspaceAPI,componentAPIName,pageAPIName,tabParamsObject,
                component.get("v.orderTabLabel"),component.get("v.orderTabIcon"),true,urlParams);
            } else {
                // this block of code helps to open the component in new tab if it is lightning app
                var url = '/lightning/cmp/' + componentAPIName + urlParams;
                window.open(url,"_blank");
            }
        })
        .catch(function(error) {
            console.log(error);
        });
    },
    setNamespace : function(component, event, helper) {
        var ns = CH_PC_Util.getNamespace(component);
        var nsPrefix = CH_PC_Util.getNamespacePrefix(component);
        component.set("v.namespace", ns);
        component.set("v.namespacePrefix", nsPrefix);
    },
    setPageReferenceValues: function(component, event, helper) {
        var namespace = component.get("v.namespace");
        var pageReference = component.get("v.pageReference");
        var recordIdName = CH_PC_Util.getQualifiedQueryParam(component,'recordId',namespace);
        var openInNewTabName = CH_PC_Util.getQualifiedQueryParam(component,'openInNewTab',namespace);
        var FSOrderDetailsName = CH_PC_Util.getQualifiedQueryParam(component,'fsOrderDetails',namespace);
        var FSProductName = CH_PC_Util.getQualifiedQueryParam(component,'fsProduct',namespace);
        var FSOrderItemName = CH_PC_Util.getQualifiedQueryParam(component,'fsOrderItem',namespace);
        var FSOrderShipmentName = CH_PC_Util.getQualifiedQueryParam(component,'fsOrderShipment',namespace);
        var ProgramIdName = CH_PC_Util.getQualifiedQueryParam(component,'programId',namespace);
        var recordId, openInNewTab, actionName, programId, fsOrderDetails, fsProduct, fsOrderItem, fsOrderShipment;
        if(pageReference && pageReference.state){
            if(pageReference.state[recordIdName] != 'NULL' && pageReference.state[recordIdName] != 'undefined'){
                recordId = pageReference.state[recordIdName];
            }
            if(pageReference.state[openInNewTabName] != 'NULL' && pageReference.state[openInNewTabName] != 'undefined'){
                openInNewTab = pageReference.state[openInNewTabName];
            }
            if(pageReference.state[FSOrderDetailsName] != 'NULL' && pageReference.state[FSOrderDetailsName] != 'undefined'){
                fsOrderDetails = pageReference.state[FSOrderDetailsName];
            }
            if(pageReference.state[FSProductName] != 'NULL' && pageReference.state[FSProductName] != 'undefined'){
                fsProduct = pageReference.state[FSProductName];
            }
            if(pageReference.state[FSOrderItemName] != 'NULL' && pageReference.state[FSOrderItemName] != 'undefined'){
                fsOrderItem = pageReference.state[FSOrderItemName];
            }
            if(pageReference.state[FSOrderShipmentName] != 'NULL' && pageReference.state[FSOrderShipmentName] != 'undefined'){
                fsOrderShipment = pageReference.state[FSOrderShipmentName];
            }
            if(pageReference.state[ProgramIdName] != 'NULL' && pageReference.state[ProgramIdName] != 'undefined'){
                programId = pageReference.state[ProgramIdName];
            }
            if(pageReference.attributes.actionName != 'NULL' && pageReference.attributes.actionName != 'undefined'){
                actionName = pageReference.attributes.actionName;
            }
        }
        else{
            var query = location.search.substr(1);
            var result = {};
            query.split("&").forEach(function(part) {
                var item = part.split("=");
                if(!$A.util.isUndefinedOrNull(item[0]) && !$A.util.isUndefinedOrNull(item[1])){
                    result[item[0]] = decodeURIComponent(item[1]);
                }
            });
            recordId = ($A.util.isUndefinedOrNull(recordId))?result[recordIdName]:recordId;
            openInNewTab = ($A.util.isUndefinedOrNull(openInNewTab))?result[openInNewTabName]:openInNewTab;
            fsOrderDetails = ($A.util.isUndefinedOrNull(openInNewTab))?result[FSOrderDetailsName]:fsOrderDetails;
            fsProduct = ($A.util.isUndefinedOrNull(openInNewTab))?result[FSProductName]:fsProduct;
            fsOrderItem = ($A.util.isUndefinedOrNull(openInNewTab))?result[FSOrderItemName]:fsOrderItem;
            fsOrderShipment = ($A.util.isUndefinedOrNull(openInNewTab))?result[FSOrderShipmentName]:fsOrderShipment;

        }
        component.set("v.recordId", (recordId != undefined)? recordId :component.get("v.recordId"));
        component.set("v.mode",(actionName != undefined)? actionName :component.get("v.mode"));
        component.set("v.programId",(programId != undefined)? programId :component.get("v.programId"));
        component.set("v.fsOrderDetails", (fsOrderDetails != undefined)? fsOrderDetails :component.get("v.fsOrderDetails"));
        component.set("v.fsProduct", (fsProduct != undefined)? fsProduct :component.get("v.fsProduct"));
        component.set("v.fsOrderItem", (fsOrderItem != undefined)? fsOrderItem :component.get("v.fsOrderItem"));
        component.set("v.fsOrderShipment", (fsOrderShipment != undefined)? fsOrderShipment :component.get("v.fsOrderShipment"));
        component.set("v.openInNewTab", (openInNewTab != undefined)? this.getBooleanValue(openInNewTab) :this.getBooleanValue(component.get("v.openInNewTab")));
    },
    getBooleanValue: function(value){
            value = (typeof value == 'string') ? value.toLowerCase() : value;
            switch(value){
                case true:
                case "true":
                    return true;
                default:
                    return false;
            }
    },
    navigationNeeded : function(component, event, helper){
        var pageReference = component.get("v.pageReference");
        var namespace = component.get("v.namespace");
        // var qualifiedIdName = CH_PC_Util.getQualifiedQueryParam(component,'recordId',namespace);
        // var qualifiedProgramIdName = CH_PC_Util.getQualifiedQueryParam(component,'programId',namespace);
        var qualifiedObjectAPIName = component.get("v.namespacePrefix") +component.get("v.orderAPIName");
        if(pageReference && pageReference.state){
            if(pageReference.attributes.objectApiName != 'NULL' && pageReference.attributes.objectApiName != 'undefined' && (pageReference.attributes.objectApiName == qualifiedObjectAPIName && pageReference.attributes.actionName == 'new') ){
                component.set("v.navigate", true);
            }
        } else {
            component.set("v.navigate", false);
        }
    }

})