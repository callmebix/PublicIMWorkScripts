<#
Author: callmebix

the idea behid this report is to pull a detailed Azure Usage Report for a subscription during a given month
it is a daily granularity and will show you the quantity and meter Id of all consumption in the 
provided time period
#>

<#
required modules Import-Excel and Az
Install-Module -Name Import-Excel -Scope CurrentUser
Install-Module -Name Az  -Scope CurrentUser
#>

#initialize the timer
$timer = Measure-Command {
    
    #environment variables that need to be set prior to execution
    #first is TenantId/CustomerId/MicrosoftId second is Azure subscription ID
    $customerId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    $subscriptionId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

    #get current date for the output file path
    $date = Get-Date -Format "MM_dd_yyyy_HH_mm"

    #desired output file location/name
    $filePath = "C:\Users\your\desired\location\name_of_file_$($date).xlsx"

    #connect to azure and authneticate
    Connect-AzAccount 

    #set the context to the specific customer and subscription
    Set-AzContext -TenantId $customerId -SubscriptionId $subscriptionId

    #initialize empty array to hold data before exporting
    $final = @()

    #parameters for the first call to Azure Usage cmdlet. This is where the date range for the report is sent
    $params = @{
        ReportedStartTime = "10-31-2023"
        ReportedEndTime = "11-1-2023"
        AggregationGranularity = "Daily"
    }

    #for the while loop that follows. will be changed to false where there is no more data to pull
    $continuation = $true

    #start while loop to catch all the data
    while($continuation -eq $true){

        #call to azure for usage
        $usageData = Get-UsageAggregates @params


        #isolate the data returned
        $data = $usageData.UsageAggregations
        $properties = $data.Properties

        #iterate through each item in the retuned data and create a hashtable
        foreach($item in $properties){
            $new_row = @{
                InstanceData = $item.InstanceData
                MeterCategory = $item.MeterCategory
                MeterId = $item.MeterId
                MeterName = $item.MeterName
                MeterRegion = $item.MeterRegion
                MeterSubCategory = $item.MeterSubCategory
                Quantity = $item.Quantity
                Unit = $item.Unit
                UsageEndTime = $item.UsageEndTime
                UsageStartTime = $item.UsageStartTime

            }

            #append the hashtable to the array created earlier
            $final += New-Object PSObject -Property $new_row
        }

        #if else statment will catch the continuation token and restart the while loop with the token if needed 
        #if not needed it will stop the while loop 
        if($null -eq $usageData.ContinuationToken){
            $continuation = $false
            Write-Host "i am done"
        }
        else{
            $params["ContinuationToken"] = $usageData.ContinuationToken
            Write-Host "using the next continuation token"
        }
    }

    #organize the column headers as desired
    $final = $final | Select-Object UsageStartTime,UsageEndTime,MeterCategory,MeterSubCategory,MeterName,MeterId,MeterRegion,Quantity,Unit,InstanceData

    #export the excel file to path stated earlier
    $final | Export-Excel -Path $filePath 

}

#wirte the time lapsed during execution
Write-Output "Time taken: $($timer.TotalSeconds) seconds"