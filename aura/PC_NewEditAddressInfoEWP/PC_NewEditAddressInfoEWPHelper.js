/**
 * Created by kkanteti on 11/17/2021.
 */
({
    doInit : function(component,event,helper){
        var row = component.get("v.newEditAddress");
        if(!$A.util.isUndefinedOrNull(row)){
            if(!$A.util.isUndefinedOrNull(row.AddressId)){
                component.set("v.addressId",row.AddressId);
            }else{
                component.set("v.addressId",JSON.stringify(Date.now()));
            }
            component.set("v.lastModifiedDate",row.LastModifiedDate);
            component.set("v.addressName",row.Name);
        }else{
            component.set("v.lastModifiedDate","");
            component.set("v.addressName",'N/A');
        }
    },
    getRowIndex: function(rows, row) {
        var rowIndex = -1;
        rows.some(function(current, i) {
            if (current.AddressId === row.AddressId){
                rowIndex = i;
                return true;
            }
        });
        return rowIndex;
    },
    submitAddress : function(component,event,helper){
        var persistentAddresses = component.get("v.persistentAddress");
        var currentAddress = component.get("v.newEditAddress");
        var rowIndex = -1;
        if(!$A.util.isUndefinedOrNull(persistentAddresses)){
            rowIndex = this.getRowIndex(persistentAddresses,currentAddress);
        }else{
            persistentAddresses = [];
        }
        if(rowIndex != -1){
            persistentAddresses[rowIndex] = currentAddress;
        }else{
            persistentAddresses.push(component.get("v.newEditAddress"));
        }
        component.set("v.persistentAddress",persistentAddresses);
        component.set("v.showAddressModal",false);
    },
    setPersistentAddress : function(component,event,helper){
        var pcRecordFormCmp = component.find('pcRecordFormByFieldSets');
        var formFields = pcRecordFormCmp.getAllFormValues();
        var isValid = pcRecordFormCmp.validateForm();
        if(isValid){
            component.set("v.isValid",isValid);
            formFields["AddressId"] = component.get("v.addressId");
            formFields["LastModifiedDate"] = component.get("v.lastModifiedDate");
            formFields["Name"] = component.get("v.addressName");
            component.set('v.newEditAddress',formFields);
        }
    },
})