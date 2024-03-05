#author: callmebix

<#
Below examples use AzureAD, AZ and Partner Center PowerShell modules 
Install-Module -Name AzureAD -Force 
Install-Module -Name Az -AllowClobber -Force 
Install-Module -Name PartnerCenter -Force 

#>

#Variables 

#tenant domain of the partner tenant who should have aobo access on customer subscriptions
$PartnertenantDomain = "mydistidomain.onmicrosoft.com"

#tenant id of the same partner tenant above
$PartnerTenantID = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'

#desired file name
$CSVname = "C:\User\your\desired\path\desired_file_name.csv"

### Get Agent-Groups Object IDs and write to CSV ###

Connect-AzureAD -TenantDomain $PartnerTenantDomain

$Headers = "GroupName`tObjectID`tPartnerTenantName`tPartnerTenantID" >>$CSVname

$PartnerTenant = Get-AzureADTenantDetail

$groups = Get-AzureADGroup | Where-Object { $_.DisplayName.Endswith('Agents') }

ForEach ($Group in $Groups){
    $NewLine = $Group.DisplayName + "`t" + $Group.ObjectID + "`t" + $PartnerTenant.DisplayName + "`t" + $PartnerTenant.ObjectID
    $NewLine >>$CSVname
}

### Get list of CSP Customers, get List of Azure Subscriptions, get list of Foreign Principals and add them to the same CSV ###

Connect-PartnerCenter -TenantID $PartnertenantID

#here you want to create an array of all the end users that you are checking subscriptions under for aobo
$Customers = @(
    'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
    'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
    'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
    'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
    'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
    'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
    'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
)

$Headers = "`r`nCustomerTenantName`tCustomerTenantID`tSubscriptionId`tForeignPrincipalName`tObjectID`tAzureRBACRole`tTimeChecked`tNotes`tCredentialsUsedForAccessCheck" >>$CSVname

Foreach ($id in $Customers){

    $Customer = Get-PartnerCustomer -CustomerId $id

    $AzurePlanId = Get-PartnerCustomerSubscription -CustomerId $Customer.CustomerId | Where-Object {$_.OfferName -eq "Azure Plan"}

        if ($null -eq $AzurePlanID){

            Write-Host "Customer $($Customer.Name) does not have Azure Plan"

        }
        else{

            $AzurePlanSubscriptionsSold = Get-PartnerCustomerAzurePlanEntitlement -CustomerId $Customer.CustomerId -SubscriptionId $AzurePlanId.SubscriptionId

        }


    Clear-AzContext -Scope CurrentUser -Force
    
    Try{

        Connect-AzAccount -Tenant $Customer.CustomerId

        $CurrentUser = Get-AzContext

        $CustomerTenantSubscriptionsAccessible = Get-AzSubscription -TenantId $Customer.CustomerId

        $SoldAndAccessibleSubscriptions = $AzurePlanSubscriptionsSold.Id | Where-Object {$CustomerTenantSubscriptionsAccessible.Id -Contains $_}

        $SoldButNotAccessibleSubscriptions = $AzurePlanSubscriptionsSold.Id | Where-Object {$CustomerTenantSubscriptionsAccessible.Id -notcontains $_}

        $NotSoldButAccessibleSubscriptions = $CustomerTenantSubscriptionsAccessible.Id | Where-Object {$AzurePlanSubscriptionsSold.Id -notcontains $_}

        ForEach ($Subscription in $SoldAndAccessibleSubscriptions){

                $Roles = Get-AzRoleAssignment -Scope "/subscriptions/$($Subscription)" | Where-Object {$_.ObjectId -in $groups.ObjectId}

                ForEach ($Role in $Roles){

                    $CurrentTime = Get-Date -format "dd-MMM-yyyy HH:mm:ss"

                    $NewLine = $Customer.Domain + "`t" + $Customer.CustomerId + "`t" + $Subscription + "`t" + "Foreign Principal" + "`t" + $Role.ObjectID + "`t" + $Role.RoleDefinitionName + "`t" + $CurrentTime + "`t" + "Access with current credentials and sold as CSP Partner" + "`t" + $CurrentUser.Account.Id

                    $NewLine >>$CSVname
                }
        }

        ForEach ($Subscription in $SoldButNotAccessibleSubscriptions){

            $CurrentTime = Get-Date -format "dd-MMM-yyyy HH:mm:ss"

            $NewLine = $Customer.Domain + "`t" + $Customer.CustomerId + "`t" + $Subscription + "`t" + "N/A" + "`t" + "N/A" + "`t" + "N/A" + "`t" + $CurrentTime + "`t" + "Sold via CSP, but no access with current credentials" + "`t" + $CurrentUser.Account.Id

            $NewLine >>$CSVname

        }

        ForEach ($Subscription in $NotSoldButAccessibleSubscriptions){

            $Roles = Get-AzRoleAssignment -Scope "/subscriptions/$($Subscription)" | Where-Object {$_.DisplayName -like "Foreign*"}

            ForEach ($Role in $Roles){

                $CurrentTime = Get-Date -format "dd-MMM-yyyy HH:mm:ss"
                $NewLine = $Customer.Domain + "`t" + $Customer.CustomerId + "`t" + $Subscription + "`t" + $Role.DisplayName + "`t" + $Role.ObjectID + "`t" + $Role.RoleDefinitionName + "`t" + $CurrentTime + "`t" + "Access with current credentials, but not sold as CSP Partner" + "`t" + $CurrentUser.Account.Id
                $NewLine >>$CSVname
            }
        }
    
    }


    catch{
        Write-Host "The Customer $($Customer.CustomerName) most likely has a conditional access policy blocking our access"
        Continue
    }
}