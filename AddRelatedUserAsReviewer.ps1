param(
    $psaId 
)
import-module SMLets


function Add-Reviewer {
    param($ra, $user, $mustVote)
    $Reviewer1 = $null
    # Set options on the Reviewer
    $Reviewer_args = @{ReviewerID = "{0}"; Mustvote = $mustVote; Veto = $false}
    # add Reviewer
    $Reviewer1 = New-SCSMObject -Class (Get-SCSMClass -name system.reviewer) -PropertyHashtable $Reviewer_args -NoCommit
    $RAStep1 = New-SCSMRelationshipObject -Relationship (Get-SCSMRelationshipClass -name System.ReviewActivityHasReviewer$) -Source $RA -Target $Reviewer1 -NoCommit
    $RAStep2 = New-SCSMRelationshipObject -Relationship (Get-SCSMRelationshipClass -name System.ReviewerIsUser$) -Source $Reviewer1 -Target $User -NoCommit
    $RAStep1.Commit()
    $RAStep2.Commit() 

}
#get the WI contains ACtivity Relationship
$containsRel = Get-SCSMRelationshipClass -id 2da498be-0485-b2b2-d520-6ebd1698e61b

#get the PSA
$thisActivity = Get-SCSMObject -id $psaId
if ($thisActivity) {
    Write-Output "Got PSA: $($thisActivity.Name)"
}

#get the Contains Rel where PSA is target
$parentContainsPSA = Get-SCSMRelationshipObject -ByTarget $thisActivity | ?{$_.relationshipid -eq $containsRel.Id}

#get parent object
$parentSR = Get-SCSMObject -Id $parentContainsPSA.sourceObject.Id
if ($parentSR) {
    Write-Output "Got Parent WorkItem: $($parentSR.Name)"
}

#get all relationships for the parent
$parentsRelsBySource = Get-SCSMRelationshipObject -BySource $parentSR 

#filter on related CI rel
$RelatedCiRO = $parentsRelsBySource | ?{($_.relationshipid -eq 'd96c8b59-8554-6e77-0aa7-f51448868b43') -and ($_.targetobject.className -eq "System.Domain.User")} | select -first 1

#get selected User Object
$selectedUser = Get-SCSMObject -Id $RelatedCiRO.targetobject.Id
if ($selectedUser) {
    Write-Output "Got Related User of Parent: $($selectedUser.DisplayName)"

    #get the rest of the activities from the parent
    $ParentActivities = $parentsRelsBySource | ?{$_.relationshipid -eq $containsRel.Id} | %{Get-SCSMObject -id $_.targetobject.Id}

    #filter on next activity according to sequence and is review activity
    $firstReviewActivityAfterPSA = $ParentActivities | ?{($_.SequenceId -gt $thisActivity.SequenceId) -and ($_.className -eq "System.Workitem.Activity.ReviewActivity")} | select -First 1

    if ($firstReviewActivityAfterPSA) {
        Write-Output "Creating Reviewer on $($firstReviewActivityAfterPSA.Name)"
        Add-Reviewer -ra $firstReviewActivityAfterPSA -user $selectedUser -mustVote $true
    }
    else {
        Write-Output "Failed to create reviewer.  Couldn't find RA"
    }
}

else {
        Write-Output "Failed to find selected user"
}
