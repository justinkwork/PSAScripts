param($crId)
import-module smlets

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
        "System.WorkItem.Activity.ParallelActivity" {New-SCSMObjectProjection -Type "TypeProjection.ParallelActivity$" -Projection $Projection -PassThru -Bulk}
    }
}

$CRemo = Get-SCSMObject -id $crId 
$maClass = Get-SCSMClass -name system.workitem.activity.manualActivity
$hasActivityRel = Get-SCSMRelationshipClass -name System.WorkItemContainsActivity
$computerClass = Get-SCSMClass -name Microsoft.Windows.Computer$
$relatesToConfig = Get-SCSMRelationshipClass -name System.WorkItemRelatesToConfigItem$
$primaryUserRel = Get-SCSMRelationshipClass -Name System.ComputerPrimaryUser$
$assignedUser = Get-SCSMRelationshipClass -Name System.WorkItemAssignedToUser$
if ($CRemo) {
    $desc = $CRemo.Description
    try {
        $servers = "[" + $desc.split("[")[1] | ConvertFrom-Json
    }
    catch {
        $servers = @()
    }

    foreach ($server in $servers) {
        $proj = New-RelatedActivity -Parent $CRemo -ActivityClass $maclass -Prefix "MA" -Title "Run Updates on $($server)"
        $relatedActivity = Get-SCSMRelatedObject -SMObject $CRemo -Relationship $hasActivityRel | sort SequenceId | select -last 1
        $thisComputer = Get-SCSMObject -Class $computerClass -Filter "NetbiosComputerName -eq $($server)"
        if ($thisComputer) {
            New-SCSMRelationshipObject -Source $relatedActivity -Target $thisComputer -Relationship $relatesToConfig -Bulk
            $primaryUsers = Get-SCSMRelationshipObject -BySource $primaryUserRel
            if ($primaryUsers) {
                $user = get-scsmobject -id $primaryUsers[0].TargetObject.Id
                New-SCSMRelationshipObject -Source $relatedActivity -Target $user -Relationship $assignedUser -Bulk
            }

        }
    }

}