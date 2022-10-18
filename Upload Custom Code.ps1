param(
    $workItemId
)
$thisSR = get-scsmobject -id $workItemId

$InputJSON = $thisSR.InputJSON | ConvertFrom-Json
$affectedUserRel = Get-SCSMRelationshipObject -BySource $thisSR -Filter {relationshipid -eq 'dff9be66-38b0-b6d6-6144-a412a3ebd4ce'}
$affectedUser = get-scsmobject -id $affectedUserRel.targetobject.id
$faRels = Get-SCSMRelationshipObject -bysource $thisSR | ?{ $_.relationshipid -eq 'ffd71f9e-7346-d12b-85d6-7c39f507b7bb'}
if ($thisSR.CreatedOnServer -eq 'www') {
    $customSpace = "c:\inetpub\CiresonPortal\CustomSpace\"
}
else {
    $customSpace = "\\jkwdev\c`$\inetpub\CiresonPortal\CustomSpace\"
}




function New-View {
    param($name, $title)
    $view = @{
        Id = $name
        layoutType = "semantic"
        pageTitle = $title
        view = @{
            cssClass = "container-fluid"
            content =  @(
                @{
                    cssClass = "row"
                    content = @(
                        @{
                            cssClass = "col-sm-12"
                            content = @{
                                cssClass = "row"
                                content = @(
                                    @{
                                        cssClass = "col-md-12"
                                        type = "viewPanel"
                                        ViewPanelId = $name + "-vp"
                                    }
                                )
                            }
                        }
                    )
                }
            )
        }
    }
    return $view | ConvertTo-Json -Depth 10
}

function New-ViewPanel {
    param(
        $name, $fpath, $fileName
    )
    $viewPanel = @{
        Id = $name + "-vp"
        TypeId = "html"
        Definition = @{
            content = "<div id='" + $name + "'></div><script>`$('#" + $name + "').load('" + $fpath + $fileName + "');</script>"
        }
    }
    return $viewPanel | ConvertTo-Json -depth 3 | %{[regex]::unescape($_)}
}

function Write-Attachment {
    param(
        $path,
        $attachment
    )

    $fs = [Io.file]::OpenWrite($path + $attachment.DisplayName)
    $memoryStream = New-Object IO.MemoryStream
    $buffer = New-Object byte[] 8192
    [int]$bytesToRead|Out-Null
    while (($bytesRead = $file.Content.Read($buffer,0, $buffer.Length)) -gt 0) {
        $memoryStream.Write($buffer, 0, $bytesRead)
    }
    $memoryStream.WriteTo($fs)
    $fs.Close()
    $memoryStream.Close()
}

if ($InputJSON.newFolder -eq "New Folder") {
    $nfPath = $customSpace + $InputJSON.folderName

    if (!(test-path -path $nfPath)) {
        mkdir -Path $nfPath
    }
    else {
        if (!($InputJSON.overwrite -eq 'Yes') -and ($InputJSON.Notify.Failure)) {
            Write-Error -Message "$($inputJSON.folderName) exists and overwrite is set to false!"
        }
    }
    $savePath = $customSpace + $InputJSON.folderName + "\"
}
else {
    $savePath = $customSpace
}

$pathArr = $savePath.split("\")
if ($InputJSON.newFolder -eq "New Folder") {
    $newPath = "/" + $pathArr[$pathArr.Length - 3] + "/" + $pathArr[$pathArr.Length - 2] + "/"
}
else {
    $newPath = "/" + $pathArr[$pathArr.Length - 2] + "/"
}

if ($faRels.length -gt 1) {
    $firstAttachment = $faRels[0].SourceObject
}
else {
    $firstAttachment = $faRels.SourceObject
}

if ($InputJSON.CustomPage -eq 'true') {
    $viewPath = ( $customSpace + "views\" + $InputJSON.viewName + ".js")
    $vpPath = ($customSpace + "views\viewpanels\" + $InputJSON.viewName + "-vp.js")
    
    if (!(test-path -path $viewPath)) {
        New-View -name $InputJSON.viewName -title $InputJSON.viewName | Out-File $viewPath
        New-ViewPanel -name $InputJSON.viewName -fpath $newPath -fileName $firstAttachment.DisplayName | out-file $vpPath
    }
    elseif ($InputJSON.overwrite -eq 'Yes') {
        New-View -name $InputJSON.viewName -title $InputJSON.viewName | Out-File $viewPath
        New-ViewPanel -name $InputJSON.viewName -fpath $newPath -fileName $firstAttachment.DisplayName | out-file $vpPath
    }
    else {
        if ($InputJSON.Notify.Failure -eq 'true') {
            Write-Error -Message "$($inputJSON.viewName) exists and overwrite is set to false!"
        }
    }
}

foreach ($attachment in $faRels) {
    if (!(test-path -Path ($savePath + $attachment.sourceobject.DisplayName))) {
        $file = get-scsmobject -id $attachment.sourceobject.id
        Write-Attachment -path $savePath -attachment $file
        if (($InputJSON.newCustomJsLine -eq 'true') -and $file.Extension -eq '.js') {
            $pagesToRun = $inputJSON.pagesToRun.split(",") | ConvertTo-Json -Compress
            "`nloadScript('" + $newPath + $file.DisplayName + "', $pagesToRun);" | Out-File -FilePath ($customSpace + "custom.js") -Append -Encoding "utf8" -Force
        }
    }
    else {
        if ($InputJSON.overwrite -eq 'Yes') {
            $file = get-scsmobject -id $attachment.sourceobject.id
            Write-Attachment -path $savePath -attachment $file
        }
        else {
            if ($InputJSON.Notify.Failure -eq 'true') {
                Write-Error -Message "$($savePath + $attachment.sourceobject.DisplayName) exists and overwrite is set to false!"
            }
        }
    }
}

if ($InputJSON.Notify.Success -eq 'true') {
    $template = Get-SCSMObjectTemplate -id "52f430c6-46f1-955b-484c-5aa4d0a2dde0"
    $mixedValue = $template.PropertyCollection |?{$_.path -like '*/Content`$'} | select -expand mixedvalue
    $mixedValue = $mixedValue.replace('<1033>','').replace('</1033>','').replace('&lt;', '<').replace('&gt;', '>')
    $body = $mixedValue.replace('@@server@@', $thisSR.CreatedOnServer).replace('@@Title@@', $thisSR.Title).replace('@@affectedUserFirstNam@@', $affectedUser.FirstName)
    Send-MailMessage -To $affectedUser.upn -From "servicemanager@jkwcireson.com" -body $body -SmtpServer "jkwcireson.mail.protection.outlook.com" -BodyAsHtml -Subject "[$($thisSr.Name)] - Code Uploaded!"
}


