/**
 * Created by tusarora on 4/22/2020.
 */
/*
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Haritha Reddy         21-Jan-2021              [PC-7102] Force Reviewer scan issue fix. Updated Sharing declaration.
 */

public inherited sharing class PC_ConditionBuilder{
    public List<LstConditionsPerObject> LstConditionsPerObject;
    public inherited sharing class LstConditionsPerObject {
        public String ObjectType;
        public String RecordValue;
        public List<Conditions> Conditions;
        public String Logic;
    }
    public inherited sharing class Conditions{
        public Integer ConditionNo;
        public String FieldName;
        public String FieldApiName;
        public String Operator;
        public String Type;
        public String Value;
        public String changeToValue;
    }
}