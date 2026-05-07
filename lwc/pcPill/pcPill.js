import { LightningElement, api } from 'lwc';

export default class PC_Pill extends LightningElement {
    @api label;
    @api value;
    @api selected;

    get cssClass() {
        return 'pc-pill' + (this.selected ? ' selected' : '');
    }
}