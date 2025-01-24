//class that sends an  email notification to a specific set of users with the given subject and body content.
public class EmailNotifilcation {
    
    Public static void SendEmailNotification(Set<String> EmailNotify){
        
       //List Of Single Email Messge:
        List<Messaging.SingleEmailMessage> Emails = new List<Messaging.SingleEmailMessage>();
       
      //Get List of user to whom we need to send email:  
        List<User> users= [SELECT ID, Name,Email 
                          FROM User
                          WHERE Email IN:EmailNotify];
        
            for(User user :users ){
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[] { user.Email });
            email.setSubject('Please Have a look On the Mail');
            email.setPlainTextBody('This Email Contains Private Information');   
            Emails.add(email);
        }
        // Send the email messages
        if(!Emails.IsEmpty()){
             Messaging.SendEmailResult[] results = Messaging.sendEmail(emails);
            if (results[0].success) {
              System.debug('The email was sent successfully.');
            } else {
              System.debug('The email failed to send: '+ results[0].errors[0].message);
                   }
        }
    }

}