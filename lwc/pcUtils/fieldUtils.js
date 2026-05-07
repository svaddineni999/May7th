export const UNSUPPORTED_REFERENCE_FIELDS = [
    'OwnerId',
    'CreatedById',
    'LastModifiedById'
];

export function getFieldsForLayout(record, apiName, layoutType) {
    let layoutData = record.layout;
    if (record.layouts) {
        layoutData = extractLayoutFromLayouts(
            record.layouts,
            apiName,
            layoutType || 'Full'
        );
    }
    if (layoutData) {
        const fieldsFromLayout = getFieldsFromLayoutResponse(
            layoutData,
            record.objectInfos[apiName]
        );

        if (Array.isArray(fieldsFromLayout)) {
            return fieldsFromLayout.reduce((seed, field) => {
                seed[field.fieldName] = {
                    label: field.fieldLabel
                };

                return seed;
            }, {});
        }
    }
    return {};
}

export function extractLayoutFromLayouts(layouts, apiName, layout) {
    const entityLayout = layouts && layouts[apiName];
    if (!entityLayout) {
        return null;
    }

    const layoutId = Object.keys(entityLayout)[0];
    if (
        layoutId &&
        entityLayout[layoutId] &&
        entityLayout[layoutId][layout] &&
        entityLayout[layoutId][layout].View
    ) {
        return entityLayout[layoutId][layout].View;
    }
    return null;
}


function getFieldsFromLayoutResponse(layout, objectInfo) {
    const processedFieldNames = {};

    const fieldsAccumulator = (
        listToReduce,
        fieldsGetterFn,
        optionalValues
    ) => {
        return listToReduce.reduce((fields, item) => {
            return fields.concat(fieldsGetterFn(item, optionalValues));
        }, []);
    };

    const getFieldsFromLayoutComponent = (layoutComponent, pageLayoutLabel) => {
        let fieldName = layoutComponent.apiName;
        const fieldInfo = objectInfo.fields[layoutComponent.apiName];

        if (fieldInfo && fieldInfo.compoundFieldName) {
            fieldName = fieldInfo.compoundFieldName;
        }
        if (fieldInfo && !processedFieldNames[fieldName]) {
            processedFieldNames[fieldName] = true;
            return {
                fieldName,

                fieldLabel: pageLayoutLabel || layoutComponent.label
            };
        }
        return [];
    };
    const getFieldsFromItem = (item) => {
        return fieldsAccumulator(
            item.layoutComponents,
            getFieldsFromLayoutComponent,
            item.label
        );
    };
    const getFieldsFromRow = (row) =>
        fieldsAccumulator(row.layoutItems, getFieldsFromItem);
    const getFieldsFromSection = (section) =>
        fieldsAccumulator(section.layoutRows, getFieldsFromRow);
    const getFieldsFromSections = (sections) =>
        fieldsAccumulator(sections, getFieldsFromSection);
    return getFieldsFromSections(layout.sections);
}


export function getCompoundFields(field, record, objectInfo) {
    return Object.keys(objectInfo.fields).filter((key) => {
        return (
            key !== field &&
            record.fields[key] &&
            objectInfo.fields[key].compoundFieldName === field
        );
    });
}


export function compoundFieldIsUpdateable(fields, record, objectInfo) {
    return fieldAttributesTruthy('updateable', fields, objectInfo);
}


export function compoundFieldIsCreateable(fields, record, objectInfo) {
    return fieldAttributesTruthy('createable', fields, objectInfo);
}


export function isCompoundField(field, objectInfo, personAccount = false) {
    const fieldInfo = objectInfo.fields[field];
    if (!fieldInfo) {
        return false;
    }

    if (fieldInfo.compound === false) {
        return false;
    }

    const keys = Object.keys(objectInfo.fields);
    for (let i = 0; i < keys.length; i++) {
        if (
            keys[i] !== field &&
            objectInfo.fields[keys[i]].compoundFieldName === field
        ) {
            if (
                objectInfo.apiName === 'Account' &&
                objectInfo.fields[keys[i]].compoundFieldName === 'Name' &&
                !personAccount
            ) {
                return false;
            }

            return true;
        }
    }

    return false;
}

export function isPersonAccount(record) {
    if (record.apiName !== 'Account' && record.apiName !== 'PersonAccount') {
        return false;
    }

    return record.fields.IsPersonAccount
        ? record.fields.IsPersonAccount.value
        : false;
}