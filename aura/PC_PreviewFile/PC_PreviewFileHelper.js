/**
 * Created by peharitha on 6/27/2019.
 */
({
    setNamespace : function(component) {
        var ns = CH_PC_Util.getNamespace(component);
        var nsPrefix = CH_PC_Util.getNamespacePrefix(component);
        component.set("v.namespace", ns);
        component.set("v.namespacePrefix", nsPrefix);
    },
    navigateToFilePreview : function(component) {
        //Get fileId from URL Parameters
        var namespace = component.get("v.namespace");
        var qualifiedIdName = CH_PC_Util.getQualifiedQueryParam(component,'fileId',namespace);
        var fileId;
        var pageReference = component.get("v.pageReference");
        if(pageReference != null && pageReference.state[qualifiedIdName] != 'NULL' && pageReference.state[qualifiedIdName] != 'undefined'){
            fileId = pageReference.state[qualifiedIdName];
        }
        //Navigate to File Preview Page
		var navService = component.find("previewNavService");
        pageReference = {
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview'
            },
            state:{
                selectedRecordId: fileId
            }
        };
        navService.navigate(pageReference);
    },
})