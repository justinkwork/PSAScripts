$customSpace = "C:\logs\psTest\"
$faRels = @(
    @{
        SourceObject = @{
            DisplayName = "file.txt"
        }
    }

)

function New-ViewPanel {
    param(
        $name, $path
    )
    $viewPanel = @{
        Id = $name + "-vp"
        TypeId = "html"
        Definition = @{
            content = "<div id='" + $name + "'></div><script>`$('#" + $name + "').load('" + $path + $faRels[0].SourceObject.DisplayName + "');</script>"
        }
    }
    return $viewPanel | ConvertTo-Json -depth 3
}


"loadScript('" + $newPath + $file.DisplayName + "', ['']);" | Out-File -FilePath ($customSpace + "custom.js") -Append -Encoding "utf8" -Force
New-ViewPanel -path "/CustomSpace/NewFolder/" | Out-File -FilePath "c:\logs\psTest\viewpanel.js"
