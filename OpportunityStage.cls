//Apex class that retrieves all Opportunities with a Close Date within the current month and updates their Stage to “Closed Won”.

public class OpportunityStage {
    Public static void UpdateOpportunities(){
        Date today = Date.today();
        Date firstDayOfMonth = Date.newInstance(today.year(), today.month(), 1);
        Date lastDayOfMonth = firstDayOfMonth.addMonths(1).addDays(-1);
        List<Opportunity> Opportunities = [SELECT ID,Name,StageName from Opportunity 
                                           WHERE CloseDate >= :firstDayOfMonth 
                                           AND CloseDate <= :lastDayOfMonth];
        for(Opportunity Opp : Opportunities){
             Opp.StageName = 'Prospecting';
        }
        if (!opportunities.isEmpty()) {
            update opportunities;
    }
}
}