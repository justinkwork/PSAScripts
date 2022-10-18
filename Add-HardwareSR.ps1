param(
    $srId 
) 

Import-Module SMLets

function New-RelatedActivity {
    param(
        $Parent, $ActivityClass, $Prefix, $Title
    )

    switch ($Parent.ClassName)
    {
        "System.WorkItem.Incident" {$className = "Activity"}
        "System.WorkItem.ServiceRequest" {$className = "Activity"}
        "System.WorkItem.ChangeRequest" {$className = "Activities"}
        "System.WorkItem.Activity.ParallelActivity" {$className = "Activities"}
    }


    $Projection = @{
        __CLASS = "$($parent.ClassName)";
        __SEED = $Parent;
        $className = @{
            __CLASS = $ActivityClass.Name;
            __OBJECT = @{
                Id = "$Prefix{0}"
                Title = "$Title"
            }
        }
    }

    switch ($Parent.ClassName)
    {
        "System.WorkItem.Incident" {New-SCSMObjectProjection -Type "System.WorkItem.IncidentPortalProjection$" -Projection $Projection -PassThru -Bulk}
        "System.WorkItem.ServiceRequest" {New-SCSMObjectProjection -Type "System.WorkItem.ServiceRequestPortalProjection$" -Projection $Projection -PassThru -Bulk }
        "System.WorkItem.ChangeRequest" {New-SCSMObjectProjection -Type "TypeProjection.ChangeRequest$" -Projection $Projection -PassThru -Bulk }
        "System.WorkItem.Activity.ParallelActivity" {New-SCSMObjectProjection -Type "TypeProjection.ParallelActivity" -Projection $Projection -PassThru -Bulk}
    }
}


$onboardSR = Get-SCSMObject -Id $srId

if ($onboardSR) {
    $input = $onboardSR.InputJson | ConvertFrom-Json
    $name = "$($input.FirstName) $($input.LastName)"
    $dept = $input.department
    $srClass = Get-SCSMClass -Name "System.WorkItem.ServiceRequest$"
    $desktopSupport = Get-SCSMEnumeration -Name "ServiceRequestSupportGroupEnum.DesktopSupport$"
    $hardwareArea = Get-SCSMEnumeration -Name "ServiceRequestAreaEnum.JKW.Hardware$"
    $wiRelClass = Get-SCSMRelationshipClass -Name "System.WorkItemRelatesToWorkItem$"
    $affectedUserRel = Get-SCSMRelationshipClass -Name "System.WorkItemAffectedUser$"
    $userClass = Get-SCSMClass -Name "Microsoft.AD.User$"
    $maClass = Get-SCSMClass -Name "System.WorkItem.Activity.ManualActivity$"
    
    $srTitle = "Deploy Laptop for $dept user: $name"
    $newSRProperies = @{
        Id = "SR{0}"
        Title = $srTitle
        SupportGroup = $desktopSupport
        Urgency = "Medium"
        Priority = "Medium"
        Source = "Portal"
        Area = $hardwareArea
    }
    try {
        New-SCSMObject -Class $srClass -PropertyHashtable $newSRProperies -PassThru -Bulk
        $hwSR = Get-SCSMObject -class $srclass -filter "Title -eq '$srTitle'"
        New-RelatedActivity -Parent $hwSR -ActivityClass $maClass -Prefix "MA" -Title "Provision Laptop for $($name)"
        New-RelatedActivity -Parent $hwSR -ActivityClass $maClass -Prefix "MA" -Title "Add $($dept) Software"
        $firstMa = Get-SCSMObject -class $maClass -filter "Title -eq 'Provision Laptop for $($name)'" 
        $firstMa | Set-SCSMObject -propertyHashTable @{Status = "In Progress"; SequenceId = 0}
        $manager =  Get-SCSMObject -Class $UserClass -Filter "DistinguishedName -eq '$($input.Manager)'"
        New-SCSMRelationshipObject -Relationship $affectedUserRel -Source $hwSR -Target $manager -Bulk
        New-SCSMRelationshipObject -Relationship $wiRelClass -Source $onboardSR -Target $hwSR -Bulk

	 
    }
    catch {
        Write-Output "Could not create new work item! $($_.Exception)"
    }
}
else {
    Write-Output "Could not get Parent SR!"
}



