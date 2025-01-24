public with sharing class EmailTriggerforAccountCreation {

   public static void sendEmailNotification(List<Account> newRecords) {
    if (newRecords == null || newRecords.isEmpty()) {
        System.debug('No new records to process.');
        return;
    }

    // Query Accounts with Owner Email explicitly
    List<Account> accountsWithOwners = [
        SELECT Id, Name, Phone, Owner.Email, Owner.Name
        FROM Account
        WHERE Id IN :newRecords
    ];

    List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

    for (Account acc : accountsWithOwners) {
        if (acc.Owner != null && String.isNotBlank(acc.Owner.Email)) {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[] { acc.Owner.Email });
            email.setSubject('Welcome to Our Company!');
            email.setPlainTextBody(
                'Hello ' + acc.Name + ',\n\nThank you for joining us! We look forward to working with you.\nPhone: ' + acc.Phone
            );

            // Generate PDF content
            String pdfContent = 'Account Name: ' + acc.Name + '\nPhone: ' + acc.Phone + '\nOwner: ' + acc.Owner.Name;
            Blob pdfBlob = Blob.valueOf(pdfContent);

            // Create an attachment for the email
            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
            attachment.setFileName('AccountDetails.pdf');
            attachment.setBody(pdfBlob);
            email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });

            emails.add(email);
        } else {
            System.debug('Owner or Owner email is missing for account: ' + acc.Name);
        }
    }

    // Send emails
    if (!emails.isEmpty()) {
        try {
            Messaging.sendEmail(emails);
            System.debug('Emails sent successfully.');
        } catch (Exception e) {
            System.debug('Error sending emails: ' + e.getMessage());
        }
    } else {
        System.debug('No emails to send.');
    }
}

}