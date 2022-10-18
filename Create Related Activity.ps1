param($srId)

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

$serviceRequest = get-scsmobject -id $srId
$paTitle = "PA: $($serviceRequest.Title)"
$paClass = (get-scsmclass -name "System.WorkItem.Activity.ParallelActivity$") 
$maClass = (get-scsmclass -name "System.WorkItem.Activity.ManualActivity$") 
New-RelatedActivity -Parent $serviceRequest -ActivityClass $paClass  -Prefix "PA" -Title $paTitle

$parentPA = get-scsmobject -class $paClass -filter "Title -eq '$paTitle'"


if ($parentPA) {
   new-relatedActivity -parent $parentPA -ActivityClass $maClass -Prefix "MA" -Title "MA: $($parentPA.Title)"
}
else {
    $parentPA = Get-SCSMObject -Class $paClass -Filter "LastModified -gt $((get-date).AddMinutes(-2))"
    if ($parentPA) {
        new-relatedActivity -parent $parentPA -ActivityClass $maClass -Prefix "MA" -Title "MA: $($parentPA.Title)"
    }
    else {
        Write-Output "2 attempts were made to create an MA inside the PA.  Both failed"
    }
}

