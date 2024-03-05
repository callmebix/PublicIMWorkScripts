<#
Author: callmebix

the idea behid this report is to pull a detailed Azure Reservation Report during a given month
it is a daily granularity and will show how many hours each machine applicable used the reserved instance
#>

<#
required modules Import-Excel and Az
Install-Module -Name Import-Excel -Scope CurrentUser
Install-Module -Name Az  -Scope CurrentUser
#>

#initialize the timer
$timer = Measure-Command {

    #environment variables that need to be set prior to execution
    #first is TenantId/CustomerId/MicrosoftId second is Reservation Order Id
    $customerId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    $reservationOrderId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

    #get current date for the output file path
    $date = Get-Date -Format "MM_dd_yyyy_HH_mm"

    #desired output file location/name
    $filePath = "C:\Users\your\desired\location\name_of_file_$($date).xlsx"

    #connect to azure and authneticate
    Connect-AzAccount 

    #set the context to the specific customer
    Set-AzContext -TenantId $customerId 

    #initialize empty array to hold data before exporting
    $final = @()


    #parameters for the call to Azure RI Usage cmdlet. This is where the date range for the report is sent
    $params = @{
        StartDate = "10-1-2023"
        EndDate = "10-31-2023"
        ReservationOrderId = $reservationOrderId
    }

    #store the returned data from call to azure in a variable
    $reservationUsage = Get-AzConsumptionReservationDetail @params

    #iterate through each item in the retuned data and create a hashtable
    foreach($item in $reservationUsage){
        $new_row = @{
            Id = $item.Id
            InstanceId = $item.InstanceId
            Name = $item.Name
            ReservationId = $item.ReservationId
            ReservationOrderId = $item.ReservationOrderId
            ReservedHour = $item.ReservedHour
            SkuName = $item.SkuName
            Tag = $item.Tag
            TotalReservedQuantity = $item.TotalReservedQuantity
            Type = $item.Type
            UsageDate = $item.UsageDate
            UsedHour = $item.UsedHour

        }
        #append the hashtable to the array created earlier
        $final += New-Object PSObject -Property $new_row
    }



    #organize the column headers as desired
    $final = $final | Select-Object Id,InstanceId,Name,ReservationId,ReservationOrderId,ReservedHour,SkuName,Tag,TotalReservedQuantity,Type,UsageDate,UsedHour

    #export the excel file to path stated earlier
    $final | Export-Excel -Path $filePath 

}
#wirte the time lapsed during execution
Write-Output "Time taken: $($timer.TotalSeconds) seconds"