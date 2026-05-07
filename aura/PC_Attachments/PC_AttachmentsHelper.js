/**
 * Created by sathekumar on 6/29/2020.
 */
({
    getAllAttachments: function(component, event, helper){
        var cmpGlobalId = component.getGlobalId();
        component.set('v.cmpGlobalId', cmpGlobalId);
        var action = component.get("c.getAttachments");
        if(component.get("v.recordId")!=null && component.get("v.recordId")!=undefined) {
            component.set("v.isAttachmentLoading", true);
            action.setParams({
                "recordId": component.get("v.recordId"),
                "showAttachmentsOfRecord": component.get("v.showAttachmentsOfRecord"),
                "showAttachmentsUsingDocumentLog": component.get("v.showAttachmentsUsingDocumentLog"),
                "showAttachmentsOfRelatedCase": component.get("v.showAttachmentsOfRelatedCase"),
                "showAllAttachmentsOfDocument": component.get("v.showAllAttachmentsOfDocument")
            });
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === 'SUCCESS'){
                    var attachmentList = response.getReturnValue();
                    if(attachmentList.length > 0){
                        var targetAttachmentList = attachmentList.map(function(el) {
                            var o = Object.assign({}, el);
                            o.isChecked = false;
                            o.contentSizeInString = helper.formatBytes(o.contentSize,2);
                            return o;
                        });
                        var attachmentListOriginalCopy = [...targetAttachmentList];
                        var additionalAttachmentList = component.get("v.additionalAttachmentList");
                        component.set("v.attachmentList", additionalAttachmentList.concat(targetAttachmentList));
                        component.set("v.attachmentListOriginalCopy", attachmentListOriginalCopy);
                        helper.calculateSelectedCount(component, event, helper);

                        // jQuery instantiation after document is loaded
                        jQuery("document").ready(function(){
                            // jQuery function to enable sorting
                            var attachmentTBodyElem = document.getElementById(cmpGlobalId+'_sortable');
                            $(function(){
                                $(attachmentTBodyElem).sortable({
                                    cursor: 'move',
                                    axis: 'y',
                                    helper: fixWidthHelper,
                                    revert: 50,
                                    tolerance: "pointer",
                                    scrollSpeed: 10,
                                    opacity: 0.5,
                                    handle: ".handle",
                                    stop: function (e, ui) {
                                        var sortedAttachmentIDs = $(attachmentTBodyElem).sortable("toArray");
                                        var originalAttachmentList = component.get("v.attachmentList");
                                        var sortedAttachmentList = sortedAttachmentIDs.map(function(sortElement, index) {
                                            var attachment = originalAttachmentList.find(att => att.id == sortElement);
                                            return attachment;
                                        });
                                        component.set("v.attachmentList", sortedAttachmentList);
                                    }
                                });
                            });

                            function fixWidthHelper(e, ui){
                                ui.children().each(function(){
                                    $(this).width($(this).width());
                                });
                                return ui;
                            }
                        });
                    }else{
                        // if there is no records then display message
                        component.set("v.noRecordsFound" , true);
                    }
                } else if (state === "ERROR") {
                    var errors = response.getError();
                    console.log(JSON.stringify(errors));
                    var errText = component.get("v.ErrorText");
                    if (errors && errors[0] && errors[0].message) {
                        console.log(errText);
                    } else {
                        console.log("Unknown error");
                    }
                }
                component.set("v.isAttachmentLoading", false);
            });
            $A.enqueueAction(action);
        }
    },

    /*
    *  This method helps to formats an integer with a byte count into human readable form
    */
    formatBytes: function(bytes, decimals) {
        if (bytes === 0) return '0 Bytes';

        const k = 1024;
        const dm = decimals < 0 ? 0 : decimals;
        const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];

        const i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
    },

    /*
    *  This method helps to calculate and set the selected attachment count
    */
    calculateSelectedCount: function(component, event, helper) {
        var attachmentList = component.get('v.attachmentList');
        var totalRecordsCount = attachmentList.length;
        var selectedCount = 0;
        attachmentList.forEach(function(item) {
            if(item.isChecked === true){
                selectedCount++;
            }
        });
        component.set("v.selectedCount", selectedCount);
        component.set("v.totalRecordsCount", totalRecordsCount);
        component.set("v.noRecordsFound", (totalRecordsCount > 0) ? false : true);
        if (totalRecordsCount > 0 && (selectedCount == totalRecordsCount)) {
            component.set("v.isSelectAllChecked", true);
        } else {
            component.set("v.isSelectAllChecked", false);
        }
    }
})