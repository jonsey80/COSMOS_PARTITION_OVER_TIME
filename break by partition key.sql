let startdate = datetime('20241126 05:00:00');
let enddate =  datetime('20241126 06:00:00');
let QuerypartitionKeyRangeId  = 37;
let DataPlane = CDBDataPlaneRequests
| where TimeGenerated between(startdate..enddate) 
|project TimeGenerated,OperationName,ActivityId,StatusCode,PartitionId;
let PartRUCons = CDBPartitionKeyRUConsumption
|where TimeGenerated between(startdate..enddate) 
|project TimeGenerated,ActivityId,PartitionKey,PartitionKeyRangeId,RequestCharge,OperationName;
let PartStats = CDBPartitionKeyStatistics
| where TimeGenerated between(startdate..enddate)
|project TimeGenerated,RegionName,PartitionKey,SizeKb;
let QRTS = CDBQueryRuntimeStatistics
|where TimeGenerated between(startdate..enddate)
|project TimeGenerated, QueryText,ActivityId;
let combi1 = DataPlane
|join  kind=inner PartRUCons on $left.ActivityId == $right.ActivityId
|project TimeGenerated,ActivityId,StatusCode,PartitionId,PartitionKeyRangeId,PartitionKey,RequestCharge,OperationName;
let combi2 = combi1
|join kind=leftouter QRTS on $left.ActivityId == $right.ActivityId
|project TimeGenerated,ActivityId,StatusCode,PartitionId,PartitionKeyRangeId,PartitionKey,RequestCharge,OperationName,QueryText; 
combi2
| join kind = inner PartStats on $left.PartitionKey == $right.PartitionKey
|where PartitionKeyRangeId == QuerypartitionKeyRangeId
|summarize sum(RequestCharge) by OperationName,RegionName,bin(TimeGenerated,5m)
|order by sum_RequestCharge desc
|render timechart 
    with (
        title="Partition use over time",
        xtitle="Time",
        ytitle="RU_Cost",
        ycolumns=OperationName 
        )
