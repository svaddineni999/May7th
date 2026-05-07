import { LightningElement, api} from 'lwc';
import addressSearch from '@salesforce/label/c.PC_Address_Search';

export default class Pc_AddressAutoComplete_lwc extends LightningElement {
    street;
    city;
    fieldsValueValid;
    label = {
        addressSearch
    };

    @api selectedAddress;
    @api fieldLabels;
    @api requiredFieldErrorMessage;
    validateChangeEventFiredOnLoad = false;

    renderedCallback() {
        if (this.validateChangeEventFiredOnLoad) {
            return;
        }
        this.validateChangeEventFiredOnLoad = true;

        this.street = this.selectedAddress.address1;
        this.city = this.selectedAddress.city;
        this.fieldsValueValid = (this.street && this.city) ? true : false ;
        const addressChangeEvent = new CustomEvent('validatechange', {
            detail: {
                'street': this.selectedAddress.address1,
                'city': this.selectedAddress.city,
                'province': this.selectedAddress.state,
                'country': this.selectedAddress.country,
                'postalCode': this.selectedAddress.zipCode,
                'fieldsValueValid': this.fieldsValueValid,
                'fieldValueChanged': true
            }
        });
        this.dispatchEvent(addressChangeEvent);
    }

    @api
    validateOnAdd() {
        const address = this.template.querySelector('lightning-input-address');
        if (!this.city&&!this.street){
            debugger;
            address.setCustomValidityForField(this.requiredFieldErrorMessage, 'street');
            address.setCustomValidityForField(this.requiredFieldErrorMessage, 'city');
            this.fieldsValueValid = false;
            address.reportValidity();
        }
        if(!this.street&&this.city){
            address.setCustomValidityForField(this.requiredFieldErrorMessage, 'street');
            address.setCustomValidityForField('', 'city');
            this.fieldsValueValid = false;
            address.reportValidity();
        }
        else if (!this.city&&this.street){
            address.setCustomValidityForField(this.requiredFieldErrorMessage, 'city');
            address.setCustomValidityForField('', 'street');
            this.fieldsValueValid = false;
            address.reportValidity();
        }
        else if(this.street&&this.city){
            address.setCustomValidityForField('', 'street');
            address.setCustomValidityForField('', 'city');
            this.fieldsValueValid = true;
            address.reportValidity();
        }
    }

    handleChange(event) {
        this.street = event.detail.street;
        this.city = event.detail.city;

        if(this.street&&this.city){
            this.fieldsValueValid = true;
        }
        else{
            this.fieldsValueValid = false;
        }
        const addressChangeEvent = new CustomEvent('validatechange', {
            detail: {'street': event.detail.street,'city': event.detail.city,'province': event.detail.province,
            'country': event.detail.country,'postalCode': event.detail.postalCode, 'fieldsValueValid': this.fieldsValueValid, 'fieldValueChanged': true }
        });
        this.dispatchEvent(addressChangeEvent);
    }


}