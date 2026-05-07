import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import resultSet from '@salesforce/apex/PC_DataTable.resultSet';
import getcolumns from '@salesforce/apex/PC_DataTable.getcolumns';
import saveOrderItems from '@salesforce/apex/PC_DataTable.saveOrderItems';
import { refreshApex } from '@salesforce/apex';
import errorProgramSelection from '@salesforce/label/c.PC_ProgramSelection';
import warningExistingPrescriptionProduct from '@salesforce/label/c.PC_ExistingPrescriptionProduct';
import warningPreselectPrescriptionProduct from '@salesforce/label/c.PC_PreselectPrescriptionProduct';
import errorPrescriptionProductUnavailable from '@salesforce/label/c.PC_PrescriptionProductUnavailable';
import warningProductSelectAfterPreselectPresProd from '@salesforce/label/c.PC_ProductSelectOnPreSelectPrescWarning';
import updateRecordTitle from '@salesforce/label/c.PC_OrderItemUpdateRecordTitle';
import updateRecordButton from '@salesforce/label/c.PC_OrderItemUpdateRecordButton';
import OrderItemTile from '@salesforce/label/c.PC_OrderItemTile';
import ProductTile from '@salesforce/label/c.PC_ProductTile';
import toastSuccessTitle from '@salesforce/label/c.PC_Toast_Title_Success';
import toastErrorTitle from '@salesforce/label/c.PC_Toast_Title_Error';
import editButtonLabel from '@salesforce/label/c.PC_Edit_Button';
import deleteButtonLabel from '@salesforce/label/c.PC_Delete';
import errorExistingOrderItemOnDelete from '@salesforce/label/c.PC_ExistingOrderItemOnDelete';
import warningOnPreSelectPresProdOrderItemDelete from '@salesforce/label/c.PC_PreselectPrescriptionProdOrderItemDelete';
import warningPrescriptionNotContainingProduct from '@salesforce/label/c.PC_PrescriptionNotContainingProduct';
import toastWarningTitle from '@salesforce/label/c.PC_Warning';

    // row actions
    const actions = [
        { label: editButtonLabel, name: 'edit'},
        { label: deleteButtonLabel, name: 'delete'}
    ];

const actionAttribute = {
                            type: 'action',
                            typeAttributes: {
                                                rowActions: actions
                                            }
                        }



export default class PC_DataTable_lwc extends LightningElement {
    @track productData = [];
    @api objectName = this.namespacePrefix+'PC_OrderItem__c';
    @track productColumns = [];
    @track OrderItemData = [];
    @track OrderItemDataList ;
    @track OrderItemDataToSave = [];
    @track OrderItemDataToSaveUnEdited = [];
    @track OrderItemInitialized;
    @track existingOrderItemData = [];
    @track OrderItemColumns = [];
    @track OrderItemColumnsToDisplay = [];
    @track presProduct = [];
    @track selectedRows = [];
    @track selectedRowsCloned = [];
    @track netNewOrderItems = [];
    @track o;
    @api fsProduct;
    @api fsOrderItem;
    @api recordId;
    @api programId;
    @api prescriptionId;
    @wire (resultSet) newResultSet;

    @track orderItemDataAvailable = false;
    @track existingOrderItem = false;
    @track productDataAvailable = true;
    @track orderitemmap = [];
    @track transfer = '';

    //Modal
    @track bShowModal = false;
    @track currentRecordId;
    @track currentProductId;
    @track isEditForm = false;
    @track showLoadingSpinner = false;
    @track fieldList;
    @track fieldListMap;

    @api namespacePrefix;
    @api orderItemInitializationFields;
    @api orderItemRefFields;
    @api mappingFields;
    @api showAllProduct;

    @track preselected = false;
    @track existingprescriptionproduct = false;
    @track runPrescriptionCheck = false;

    label = {
            updateRecordTitle,
            updateRecordButton,
            OrderItemTile,
            ProductTile,
    };

    warningMessages = {
        warningExistingPrescriptionProduct,
        warningPreselectPrescriptionProduct
    }

    connectedCallback(){
        if(this.fsProduct === undefined ){
            this.fsProduct = this.namespacePrefix+'PC_Product';
        }
        if(this.fsOrderItem === undefined){
            this.fsOrderItem = this.namespacePrefix+'PC_OrderItems';
        }

        this.objectName = this.namespacePrefix+'PC_OrderItem__c';
        // OrderItem Initialization fields
        this.orderItemInitializationFields = { 'ord': this.namespacePrefix+'PC_Order__c', 'prd': this.namespacePrefix+'PC_Product__c'};
        // OrderItem Reference fields
        this.orderItemRefFields = [ { rFields: this.namespacePrefix+'PC_Product__r', rFieldsattr: 'Name'}];

        // Product to OrderItem Mapping
        this.mappingFields = [
            { pFields: 'Id', oiFields: this.namespacePrefix+'PC_Product__c'},
            { pFields: 'Description', oiFields: this.namespacePrefix+'PC_ProductDescription__c'},
            { pFields: this.namespacePrefix+'PC_Strength__c', oiFields: this.namespacePrefix+'PC_Strength__c'},
            { pFields: this.namespacePrefix+'PC_NDC__c', oiFields: this.namespacePrefix+'PC_NDC__c'},
            { pFields: 'Name', oiFields: this.namespacePrefix+'PC_Product__r.Name'}
        ];
    }

    //Not required since the attributes are reactive.
    @api
    handleApexRefresh(event){
        refreshApex(this.newResultSet);
    }


    @api
    handleProgramRefresh(pId){
        this.runPrescriptionCheck = true;
        this.programId =  pId;
    }

    @api
    handlePrescriptionRefresh(presId){
        this.runPrescriptionCheck = true;
        this.prescriptionId = presId;
    }

    @api
    clearProductData(){
        this.productColumns = [];
        this.productData =[];
        this.productDataAvailable = false;
        this.nextStepsHandler();
    }

    @api
    clearPrescriptionData(){
        this.clearPrescriptionProduct();
        this.presProduct = [];
        this.preselected = false;
        this.existingprescriptionproduct = false;
        this.nextStepsHandler();
    }

    clearPrescriptionProduct(){
        this.selectedRows = [];
        this.selectedRowsCloned = [];
        /*let selectedRows = JSON.parse(JSON.stringify(this.selectedRows));
        this.selectedRows = [];
        let presProduct = JSON.parse(JSON.stringify(this.presProduct[0]));
        let temp = [];
        selectedRows.forEach(sElement =>{
            if(sElement['Id'] = presProduct['Id']){
                console.log('@@Remove '+JSON.stringify(sElement));
            }else{
                temp.push(sElement);
            }
        })
        console.log('@@temp '+JSON.stringify(temp));
        this.selectedRows = temp;*/
    }

    clearAfterSave(){
        this.prescriptionId = '';
        this.runPrescriptionCheck = false;
        this.selectedRows = [];
        this.selectedRowsCloned = [];
        this.orderItemData = [];
        this.OrderItemDataToSave = [];
        this.OrderItemDataToSaveUnEdited = [];
    }

    showToast(title, variant, mode, errorMessage) {
        const event = new ShowToastEvent({
            title: title,
            message: String(errorMessage),
            variant : variant,
            mode : mode,
        });
        this.dispatchEvent(event);
    }

    @api
    nextStepsHandler() {
        //Check for Existing Order Item Data.
        if(this.existingOrderItemData.length > 0){
            this.createOrderItem(this.existingOrderItemData);   //Transform the existing Order Items into correct format for display.
            this.OrderItemData = JSON.parse(JSON.stringify(this.existingOrderItemData));
        }

        //Check if Product Data is available.
        if(this.productData.length > 0){
            this.productDataAvailable = true;
        }else{
            this.productDataAvailable = false;
        }

        //Check for Existing Order Item Data, and set flags
        if(this.existingOrderItemData.length > 0){
            this.orderItemDataAvailable = true;
            this.existingOrderItem = true;
            //Workflow for existing OrderItem
        }else{
            this.orderItemDataAvailable = false;
            this.existingOrderItem = false;
            this.existingOrderItemData = [];
            //No existing OrderItems
        }
        if(this.runPrescriptionCheck){
            this.preSelectPrescription();
        }
    }

    @api
    refreshParentComponents(event){
        var orderRecordId = this.recordId;
        let refreshParentsEvt = new CustomEvent('refreshparent', {
            detail: {
                    refreshParent : true,
                    orderId : orderRecordId
            }
        });
         //Fire the custom event
        this.dispatchEvent(refreshParentsEvt);
    }

    @api
    preSelectPrescription(){
        //Check for existing prescription product data
        if(this.presProduct.length > 0){
            if(!this.productDataAvailable){
                this.showToast(toastErrorTitle, 'error', 'sticky', errorProgramSelection);
            }
            //let check = false;
            if(this.existingOrderItem){
                let eValue = this.existingOrderItemData;

                eValue.forEach(element => {
                    let existingOrderItem = JSON.parse(JSON.stringify(element));
                    let prescriptionItem = JSON.parse(JSON.stringify(this.presProduct[0]));
                    if(existingOrderItem[this.namespacePrefix+'PC_Product__c'] == prescriptionItem['Id']){
                        this.existingOrderItem = true;
                        //this.showToast('Warning', 'warning', 'dismissable', warningExistingPrescriptionProduct);
                        this.existingprescriptionproduct = true;
                    }
                })
            }
            if (this.productDataAvailable){
                let selectedProductId = [];
                let selectedProduct = [];
                var showError = true;
                if(this.selectedRowsCloned && this.selectedRowsCloned.length > 0){
                    let selectedProductData = this.selectedRowsCloned;
                    let presProductData = this.presProduct;
                    //If number of selected products are greater than prescription product(s).
                    if(this.selectedRowsCloned.length > this.presProduct.length){
                        selectedProductData.forEach(element => {
                            let productObj = JSON.parse(JSON.stringify(element));
                            console.log('productObj :::::'+JSON.stringify(productObj));
                            presProductData.forEach(preProd => {
                                let prescriptionItemObj = JSON.parse(JSON.stringify(preProd));
                                console.log('prescriptionItemObj :::::'+JSON.stringify(prescriptionItemObj));
                                if(productObj['Id'] == prescriptionItemObj['Id']){
                                    selectedProductId.push(productObj['Id']);
                                    selectedProduct.push(productObj);
                                } else {
                                    let productValue = this.productData;
                                    productValue.forEach(element => {
                                        let product = JSON.parse(JSON.stringify(element));
                                        let prescriptionItem = JSON.parse(JSON.stringify((this.presProduct)[0]));
                                        if(product['Id'] == prescriptionItem['Id']){
                                            selectedProductId.push(product['Id']);
                                            selectedProduct.push(product);
                                        }
                                    })
                                }
                            })
                        })
                        if(selectedProductId.length > 0){
                            this.selectedRows = selectedProductId;
                            this.preselected = true;
                            this.selectPreSelected(selectedProduct);
                            showError = false;
                            this.showToast(toastWarningTitle, 'warning', 'sticky', warningProductSelectAfterPreselectPresProd);
                            this.dispatchEvent(new CustomEvent('prescriptionunavailable', { detail: false }));
                        }
                    }
                    //If number of selected products are same as prescription product(s).
                    else if(this.selectedRowsCloned.length == this.presProduct.length){
                        let productSelectionNotMatchWithPresProd = [];
                        selectedProductData.forEach(element => {
                            let productObj = JSON.parse(JSON.stringify(element));
                            presProductData.forEach(preProd => {
                                let prescriptionItemObj = JSON.parse(JSON.stringify(preProd));
                                if(productObj['Id'] == prescriptionItemObj['Id']){
                                    selectedProductId.push(productObj['Id']);
                                    selectedProduct.push(productObj);
                                } else {
                                    productSelectionNotMatchWithPresProd.push(productObj['Id']);
                                    let productValue2 = this.productData;
                                    productValue2.forEach(element => {
                                        let product = JSON.parse(JSON.stringify(element));
                                        let prescriptionItem = JSON.parse(JSON.stringify((this.presProduct)[0]));
                                        if(product['Id'] == prescriptionItem['Id']){
                                            selectedProductId.push(product['Id']);
                                            selectedProduct.push(product);
                                        }
                                    })
                                }
                            })
                        })
                        if(selectedProductId.length > 0){
                            this.selectedRows = selectedProductId;
                            this.preselected = true;
                            this.selectPreSelected(selectedProduct);
                            showError = false;
                            this.dispatchEvent(new CustomEvent('prescriptionunavailable', { detail: false }));
                        }
                        if(productSelectionNotMatchWithPresProd.length > 0){
                            this.showToast(toastWarningTitle, 'warning', 'sticky', warningProductSelectAfterPreselectPresProd);
                            showError = false;
                        }
                    }
                } else {
                    let eValue = this.productData;
                    eValue.forEach(element => {
                        let product = JSON.parse(JSON.stringify(element));
                        let prescriptionItem = JSON.parse(JSON.stringify((this.presProduct)[0]));
                        if(product['Id'] == prescriptionItem['Id']){
                            selectedProductId.push(product['Id']);
                            selectedProduct.push(product);
                            this.selectedRows = selectedProductId;
                            this.preselected = true;
                            this.selectPreSelected(selectedProduct);
                            showError = false;
                            this.dispatchEvent(new CustomEvent('prescriptionunavailable', { detail: false }));
                        }
                    })
                }
                if(showError){
                     this.selectedRows = [];
                     this.selectedRowsCloned = [];
                     this.showToast(toastWarningTitle, 'warning', 'sticky', errorPrescriptionProductUnavailable);
                     this.dispatchEvent(new CustomEvent('prescriptionunavailable', { detail: true }));
                }
            }
        } else {
            if(this.prescriptionId != null &&  this.prescriptionId != 'undefined' && this.prescriptionId != ''){
                this.showToast(toastWarningTitle, 'warning', 'sticky', warningPrescriptionNotContainingProduct);
                this.dispatchEvent(new CustomEvent('prescriptionunavailable', { detail: true }));
            }
        }
        //this.setFieldList(this.newResultSet.data.displayColumns, this.newResultSet.data.productList);
    }

    setData(){
        this.productColumns             = this.newResultSet.data.selectionColumns;  //Product Object fields
        this.productData                = this.newResultSet.data.productList;       //Product Data
        this.presProduct                = this.newResultSet.data.prescProductList;  //Prescription Product Data
        this.OrderItemColumns           = this.newResultSet.data.displayColumns;
        this.existingOrderItemData      = this.newResultSet.data.orderItemList;     //Existing Order Item.
    }


    @wire(getcolumns, { fsProduct: '$fsProduct', fsOrderItem: '$fsOrderItem', recordIdString:'$recordId', programIdString:'$programId', prescriptionIdString:'$prescriptionId', showAllProduct:'$showAllProduct'})
    wiredGetProductData(value) {
        this.newResultSet       = value;
        const { data, error }   = value;
        if (data) {
            //this.runPrescriptionCheck = false;
            this.setData();
            this.removeReferenceFields(this.newResultSet.data.displayColumns);
            //this.makeOrderItemColumnsEditable(this.newResultSet.data.displayColumns);   //Add editable property.//need to be commmented since table need not be editable.
            this.initializeOrderItem(this.newResultSet.data.displayColumns);            //Initialize the Order Item data.
            this.nextStepsHandler();
        }
        else if (error) { console.log('Error'+JSON.stringify(error));}
    }

    initializeOrderItem(oItemColumns){
        var cValue = oItemColumns;
        var newOrderItem = new Object();
        cValue.forEach(column =>{
            newOrderItem[column.fieldName] = '';
        })
        this.OrderItemInitialized =  newOrderItem;
    }

    createOrderItem(oItemList){
        var cValue = oItemList;
        var newOrderItem = JSON.parse(JSON.stringify(oItemList));
        newOrderItem.forEach(oItem =>{
            this.orderItemRefFields.forEach(field =>{
                var f = field.rFields+'.'+field.rFieldsattr;
                var temp = oItem[field.rFields][field.rFieldsattr];
                //newOrderItem[0][f] = temp;
                oItem[f] = temp;
            })
        })
        this.existingOrderItemData =  newOrderItem;
    }

    setFieldList(columns,productData){
        var cValue = columns;
        var pValue = productData;
        pValue.forEach(product =>{
            var newR = new Object();
            cValue.forEach(column =>{
                if(product[column.fieldName]){
                    newR[column.fieldName] = product[column.fieldName];
                }else{
                    newR[column.fieldName] = '';
                }
            })
            this.netNewOrderItems.push(newR);
        })
        cValue.forEach(element =>{
         this.fieldList.push(element.fieldName);
        })
    }

    makeOrderItemColumnsEditable(temp){
        var o;
        var tempColumn;
        var tempColumnList = [];
        for (o of temp){
            tempColumn =  Object.assign({}, o);
            tempColumn.editable = true;
            tempColumnList.push(tempColumn);
        }
        tempColumnList.push(actionAttribute);
        this.OrderItemColumns = tempColumnList;
    }

    removeReferenceFields(temp){
        var o;
        var tempColumn;
        var tempColumnList = [];
        for (o of temp){
            tempColumn =  Object.assign({}, o);
            //tempColumn.editable = true;
            if(o.type == 'REFERENCE' || o.type == 'ID'){
                //Nothing
            }else{
                tempColumnList.push(tempColumn);
            }

        }
        tempColumnList.push(actionAttribute);
        this.OrderItemColumnsToDisplay = tempColumnList;
    }

    addSelectValue(selectedValue){
        let sValue = selectedValue;
        let oValue = JSON.parse(JSON.stringify(this.OrderItemData));
        let nValue = [];
        //let temp = JSON.parse(JSON.stringify(this.OrderItemData));
        let temp2 = [];
        let uniqueProductId = new Set();

        let orderItemDataMap = new Map();
        oValue.forEach(element =>{
            orderItemDataMap.set(element[this.namespacePrefix+'PC_Product__c'],element);
            uniqueProductId.add(element[this.namespacePrefix+'PC_Product__c']);
        })

        sValue.forEach(selectedProduct => {
            let product = JSON.parse(JSON.stringify(selectedProduct)); //Product selected
            let orderItemData = JSON.parse(JSON.stringify(this.OrderItemInitialized)); //OrderItem Initialized

            this.mappingFields.forEach(mField =>{
                orderItemData[mField.oiFields] = product[mField.pFields];
            })
            if(this.recordId){
                orderItemData[this.namespacePrefix+'PC_Order__c'] = this.recordId;
            }
            nValue.push(orderItemData);
        })

        let nValueMap = new Map();
        nValue.forEach(element =>{
            nValueMap.set(element[this.namespacePrefix+'PC_Product__c'],element);
            uniqueProductId.add(element[this.namespacePrefix+'PC_Product__c']);
        })

        uniqueProductId.forEach(pid =>{
            if(orderItemDataMap.get(pid)){
                if(orderItemDataMap.get(pid)['Id']){
                    temp2.push(orderItemDataMap.get(pid));
                }else if(nValueMap.get(pid)){
                    temp2.push(nValueMap.get(pid));
                }
            }else if(nValueMap.get(pid)){
                temp2.push(nValueMap.get(pid));
            }
        })
        this.OrderItemData = temp2;


        /*var nValueLength = nValue.length;
        var oValueLength = oValue.length;
        if(nValueLength >= oValueLength){
            nValue.forEach(element =>{
                if(orderItemDataMap.get(element[this.namespacePrefix+'PC_Product__c'])){
                }else{
                    temp.push(element);
                }

            })
            this.OrderItemData = temp;
        }else{
            oValue.forEach(element =>{
                if(element.Id){
                    temp2.push(element);
                }else{
                    if(nValueMap.get(element[this.namespacePrefix+'PC_Product__c'])){
                        temp2.push(element);
                    }else{
                    }
                }
            })
            this.OrderItemData = temp2;
        } */
    }

    addUneditedOrderItems(){
        var ordeItem = JSON.parse(JSON.stringify(this.OrderItemData));
        var uneditedOrder = [];
        ordeItem.forEach(element =>{
            if(element.Id){
                //element already exists so don't add, update only after edit, which is handelled by other method
            }else{
                var temp = new Object();
                temp[this.orderItemInitializationFields.ord] = element[this.orderItemInitializationFields.ord];
                temp[this.orderItemInitializationFields.prd] = element[this.orderItemInitializationFields.prd];
                uneditedOrder.push(temp);
            }

        })
        this.OrderItemDataToSaveUnEdited =  uneditedOrder;
    }

    getSelectedName(event) {
        var selectedValue = event.detail.selectedRows;
        this.selectedRowsCloned = selectedValue;
        this.addSelectValue(selectedValue);
        this.addUneditedOrderItems();
        if(this.OrderItemData.length > 0){
            this.orderItemDataAvailable = true;
        }else{
            this.orderItemDataAvailable = false;
        }
    }

    selectPreSelected(selectedRow) {
        var selectedValue = selectedRow;
        this.selectedRowsCloned = selectedValue;
        this.addSelectValue(selectedValue);
        this.addUneditedOrderItems();
        if(this.OrderItemData.length > 0){
            this.orderItemDataAvailable = true;
        }else{
            this.orderItemDataAvailable = false;
        }

    }

    mergeUneditedOrderItem(){
        var editedOrderItem = this.OrderItemDataToSave;
        var unEditedOrderItem = this.OrderItemDataToSaveUnEdited;
        let uniqueProductId = new Set();
        var temp = [];

        let editedOrderItemMap = new Map();
        editedOrderItem.forEach(element =>{
            editedOrderItemMap.set(element[this.namespacePrefix+'PC_Product__c'],element);
            uniqueProductId.add(element[this.namespacePrefix+'PC_Product__c']);
        })

        let unEditedOrderItemMap = new Map();
        unEditedOrderItem.forEach(element =>{
            unEditedOrderItemMap.set(element[this.namespacePrefix+'PC_Product__c'],element);
            uniqueProductId.add(element[this.namespacePrefix+'PC_Product__c']);
        })

        uniqueProductId.forEach(pid =>{
            if(editedOrderItemMap.get(pid)){
                temp.push(editedOrderItemMap.get(pid));

            }else if(unEditedOrderItemMap.get(pid)){
                temp.push(unEditedOrderItemMap.get(pid));
            }else{
                //this.showToast('Error', 'error', 'sticky', 'Critical Issue in saving Order Item');
            }
        })
        this.OrderItemDataToSave = temp;
    }

    @api
    handleSave(event){
        var orderCreatedId = event.detail.orderCreatedId;
        this.mergeUneditedOrderItem();
        if(!this.recordId){
            var orderItem = this.OrderItemDataToSave;
            orderItem.forEach(o =>{
            o[this.namespacePrefix+'PC_Order__c'] = orderCreatedId;
            })
        }
        if(this.OrderItemDataToSave){
            this.transfer = JSON.stringify(this.OrderItemDataToSave);
            saveOrderItems({ orderItemData : this.transfer })
            .then(result =>{
                this.clearAfterSave();
                this.recordId = orderCreatedId;
                this.refreshParentComponents(event);
                this.handleApexRefresh(event);
            })
            .catch(error =>{
            })
        }
    }

    handleRowActions(event) {
        let actionName = event.detail.action.name;
        let row = event.detail.row;
        switch (actionName) {
            case 'edit':
                this.editCurrentRecord(row);
                break;
            case 'delete':
                this.deleteCons(row);
                break;
        }
    }

    // closing modal box
    closeModal() {
        this.bShowModal = false;
    }

    deleteCons(currentRow) {
        if(currentRow.Id) {
            this.showToast('Error', 'Error', 'sticky', errorExistingOrderItemOnDelete);
        } else {
            this.OrderItemDataList = [];
            if(this.OrderItemData.length > 0) {
                 var selectedOrderItemData = this.OrderItemData;
                 var deletedOrderItemData = currentRow;
                 let deleteRowIndex;
                 for(let i=0; i<selectedOrderItemData.length; i++) {
                     if(selectedOrderItemData[i][this.namespacePrefix+'PC_Product__c'] === deletedOrderItemData[this.namespacePrefix+'PC_Product__c']) {
                         deleteRowIndex = i;
                     }
                 }
                 this.OrderItemData.splice(deleteRowIndex, 1);
                 this.OrderItemData = [...this.OrderItemData];
                 this.addUneditedOrderItems();
                 if(this.preselected){
                    let prescriptionItem = JSON.parse(JSON.stringify((this.presProduct)[0]));
                    if(deletedOrderItemData[this.namespacePrefix+'PC_Product__c'] == prescriptionItem['Id']){
                        this.preselected = false;
                        this.showToast(toastWarningTitle, 'warning', 'sticky', warningOnPreSelectPresProdOrderItemDelete);
                    }
                 }
                 if(this.OrderItemData.length > 0){
                     this.orderItemDataAvailable = true;
                 } else {
                     this.orderItemDataAvailable = false;
                 }
                 if(this.selectedRowsCloned.length > 0){
                     let updateRowSelectionId = [];
                     let updateRowSelectionObj = [];
                     let rowSelection = this.selectedRowsCloned;
                     let modifiedOrderItemData = this.OrderItemData;
                     rowSelection.forEach(element => {
                          let productObj = JSON.parse(JSON.stringify(element));
                          modifiedOrderItemData.forEach(orderItem => {
                              let orderItemObj = JSON.parse(JSON.stringify(orderItem));
                              if(productObj['Id'] == orderItemObj[this.namespacePrefix+'PC_Product__c']){
                                  updateRowSelectionId.push(productObj['Id']);
                                  updateRowSelectionObj.push(productObj);
                              }
                          })
                     })
                     if(updateRowSelectionId.length>0){
                         this.selectedRows = updateRowSelectionId;
                         this.selectedRows = [...this.selectedRows];
                         this.selectedRowsCloned = updateRowSelectionObj;
                     } else {
                         this.selectedRows = updateRowSelectionId;
                         this.selectedRowsCloned = updateRowSelectionObj;
                     }
                 }
             }
        }
    }

    editCurrentRecord(currentRow) {
        // open modal box
        this.bShowModal = true;
        this.isEditForm = true;

        // assign record id to the record edit form
        this.currentRecordId = currentRow.Id;
        this.currentProductId = currentRow[this.namespacePrefix+'PC_Product__c'];
        this.createFieldListMap(currentRow);
    }

    handleSubmit(event) {
        event.preventDefault();
        var toSave = event.detail.fields;
        var orderItemId = '';
        var orderId = '';
        var productId = toSave[this.namespacePrefix+'PC_Product__c'];
        //Check for Order Item Id
        if(toSave.Id){
            orderItemId =  toSave.Id;
        }else if(this.currentRecordId){
            toSave.Id =  this.currentRecordId;
        }else{
            //No Order Item Id, send for insert
        }

        //Check for Order Id
        if(toSave[this.namespacePrefix+'PC_Order__c']){
            orderId = toSave[this.namespacePrefix+'PC_Order__c'];
        }else if(this.recordId){
            toSave[this.namespacePrefix+'PC_Order__c'] = this.recordId
        }else{
            //this.showToast('Warning', 'warning', 'sticky', 'Order Record not Found');
        }

        //Push edited order item to OrderItemDataToSave
        var orderItem = JSON.parse(JSON.stringify(this.OrderItemDataToSave));
        var newOrderItemToSave = [];
        if(orderItem.length > 0){
            var counter = 0;
            orderItem.forEach(oItem =>{
                if(oItem.Id == orderItemId || oItem[this.namespacePrefix+'PC_Product__c'] == productId){
                    newOrderItemToSave.push(JSON.parse(JSON.stringify(toSave)));
                }else{
                    newOrderItemToSave.push(JSON.parse(JSON.stringify(oItem)));
                    counter++;    
                }       
            })
            if(counter == orderItem.length){
                newOrderItemToSave.push(JSON.parse(JSON.stringify(toSave)));  
            }
            this.OrderItemDataToSave = newOrderItemToSave;
        }else{
            this.OrderItemDataToSave.push(JSON.parse(JSON.stringify(toSave)));
        }
        
        this.updateOrderItemTable(toSave);
        this.closeModal();
    }

    updateOrderItemTable(toSave){
        var orderItemList = JSON.parse(JSON.stringify(this.OrderItemData));
        var orderItem = toSave;
        var columns = this.OrderItemColumns;
        orderItemList.forEach(element =>{
            if(element.Id == toSave.Id || element[this.namespacePrefix+'PC_Product__c'] == toSave[this.namespacePrefix+'PC_Product__c']){
                columns.forEach(c =>{
                    if(orderItem[c.fieldName]){
                        element[c.fieldName] = orderItem[c.fieldName];  
                    } else{
                    }  
                })
            }
            this.OrderItemData = orderItemList;      
        })
    }

    createFieldListMap(row){
        let myMap = [];
        let clmn = this.OrderItemColumns;
            clmn.forEach(c =>{
                let vShow = false;
                let isDisabled = false;
                if(c.isEditable){
                    vShow = true;      
                }
                if(c.fieldName == this.namespacePrefix+'PC_Product__c'){
                    isDisabled = true;   
                }
                /*if(this.recordId){
                    vShow = true;    
                }else if(c.fieldName == this.namespacePrefix+'PC_Order__c'){
                    vShow = false;
                }*/

                let keyString = c.fieldName;
                let valueString = row[c.fieldName];
                myMap.push({value:valueString, key:keyString, show:vShow, isDisabled:isDisabled});
            }) 
        this.fieldListMap = myMap;
    }
}