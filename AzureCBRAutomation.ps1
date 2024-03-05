#Author: callmebix
<#
required modules Import-Excel and Az
Install-Module -Name Import-Excel -Scope CurrentUser
Install-Module -Name Az  -Scope CurrentUser
#>


#this initializes a timer so that I can see how long the script takes to execute
$timer = Measure-Command {

    #I include a date in the output file. this gets the date and time for me
    $date = Get-Date -Format "MM_dd_yyyy_HH_mm"

    #CHANGE THIS ID!!!!! This is the Microsoft Customer ID of the customer or tenant that you will be pulling cost by resource reports for
    $customerID = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'

    #change the file path and name of where you would like the file to be saved
    $file_destination = "C:\User\your\desired\path\desired_file_name_$($date).xlsx"

    #this will launch a window for Azure authentication. you must log in with an account that has a the appropriate rbac for the subscriptions
    Connect-AzAccount -TenantId $customerID

    #this command gets all of the subscriptions within the azure plan of the tenant you are logged into
    $subscriptions = Get-AzSubscription

    <#this can be changed depending on the type of report. the options are:

    ActualCost
    AmortizedCost
    Usage 

    #>
    $type = "ActualCost"

    <#This can also be changed depending on the date range you are looking to pull. The options are:

    BillingMonthToDate
    Custom
    MonthToDate
    TheLastBillingMonth
    TheLastMonth
    WeekToDate
    
    #>
    $timeFrame = "MonthToDate" 

    #Hash tables for the aggregation
    $totalCost = @{
        'name' = 'Cost' 
        'function' = 'Sum'
    }

    $totalCostUSD = @{
        'name' = 'CostUSD' 
        'function' = 'Sum'
    }

    $aggregation = @{
        'totalCost' = $totalCost
        'totalCostUSD' = $totalCostUSD
    }

    #Hash tables for the grouping
    $grouping = @(

        @{
            "type" = "Dimension"
            "name" = "ResourceId"
        },

        @{
            "type" = "Dimension"
            "name" = "ResourceType"

        },

        @{
            "type" = "Dimension"
            "name" = "ResourceLocation"
        },

        @{
            "type" = "Dimension"
            "name" = "ResourceGroupName"
        },

        @{
            "type" = "Dimension"
            "name" = "ServiceName"
        },

        @{
            "type" = "Dimension"
            "name" = "Meter"
        }

    )

    #blank array to hold the returned query data 
    $final = @()

    #Iterate through each subscription returned in the Get-Subscription Command
    foreach($sub in $subscriptions){

        #put the response into a variable to isolate the data in the row section of the IQueryResult
        $response = Invoke-AzCostManagementQuery -Scope "/subscriptions/$($sub.Id)" -Timeframe $timeFrame -Type $type -DatasetAggregation $aggregation -DatasetGrouping $grouping 

        $properties = $response.Row
        
        #iterate through each item in the returned dataset
        foreach ($row in $properties){

            #give column headers and store data under the headers
            $new_row = @{
                Subscription_Name = $sub.Name
                Subscription_ID = $sub.Id
                Cost = $row[0]
                Cost_USD = $row[1]
                Resource_ID = $row[2]
                Resource_Type =$row[3]
                Resource_Location = $row[4]
                Resource_Group_Name = $row[5]
                Service_Name = $row[6]
                Meter = $row[7]
                Currency = $row[8]
                    }

                    #add the data to the blank array
                    $final += New-Object PSObject -Property $new_row
            }
    }

    #organize the data in a reader friendly way
    $final = $final | Select-Object Subscription_Name,Subscription_ID,Resource_ID,Resource_Group_Name,Resource_Type,Resource_Location,Service_Name,Meter,Cost,Currency,Cost_USD

    #export the data in an excel sheet to the desired path and file name
    $final | Export-Excel -Path $file_destination 


}
#end the timer and output to terminal
Write-Output "Time taken: $($timer.TotalSeconds) seconds"
