//Apex class to update the email address of a Contact record based on the provided Contact Id.
public class ConEmailUpdate {
    
    Public static Contact UpdateConEmail(string Id){
       Contact con = [SELECT Id, Email FROM Contact WHERE Id = :Id LIMIT 1];
            con.Email = 'priyanka.p.lnu@yahoo.com';   
            update con;
            return con;

    }

}