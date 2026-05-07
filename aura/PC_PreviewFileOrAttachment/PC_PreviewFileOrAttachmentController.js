/**
 * Created by peharitha on 7/4/2019.
   [PC-5713] Added capability of Preview for html attachment
 */
({
    doInit : function(component, event, helper) {
        helper.setNamespace(component);
        helper.getDocumentDetails(component);
    },

    popOutDocument : function (component, event, helper) {
        var previewFile = component.get("v.documentDetails.previewFile");
        var titleName=component.get("v.popoutTitle");
        var url,documentId, recordId;
        var isText = component.get("v.documentDetails.isTEXT");
        if(previewFile){
            var namespace = component.get("v.namespace");
            var previewComponentName = component.get("v.previewComponentName");
            var qualifiedIdName = CH_PC_Util.getQualifiedQueryParam(component,'fileId',namespace);
            documentId = component.get("v.documentDetails.fileId");
            url = '/lightning/cmp/'+namespace+'__'+previewComponentName+'?'+qualifiedIdName+'='+documentId;
            window.open(url,titleName+documentId,"toolbar=yes,scrollbars=yes,resizable=yes,left=1050,top=100,width=800,height=800");
        }else{
            if (!isText){
                documentId = component.get("v.documentDetails.attachmentId");
                url = '/servlet/servlet.FileDownload?file=' +documentId;
                window.open(url,titleName+documentId,"toolbar=yes,scrollbars=yes,resizable=yes,left=1050,top=100,width=800,height=800");
            }
            else{
                recordId = component.get("v.recordId")
                var componentName="PC_PreviewFileOrAttachment";
                titleName="Document Preview";
                var vfpage = component.get("v.namespacePrefix")+'PC_PopOutDocument';
                url = '/apex/'+ vfpage +'?documentId=' + recordId + '&componentName=' + componentName;
                window.open(url,titleName,"toolbar=yes,scrollbars=yes,resizable=yes,left=1050,top=100,width=800,height=800");
            }
        }
    },
})