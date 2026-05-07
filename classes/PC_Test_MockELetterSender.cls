/**
 * Created by mklumpenaar on 3/13/2017.
 */
@isTest
public with sharing class PC_Test_MockELetterSender implements PC_eLetter.Sender {
    public void sendLetter(Id objectId, List<PC_eLetter.DocumentWrapper> documentRecipients,
            PC_eLetter__c eLetter, Boolean sendToCurrentUser) {
        return;
    }
}