$versions = $PSVersionTable.GetEnumerator()
foreach ($v in $versions) {
    if ($v.Name -eq 'PSVersion') { Write-Output $($v.Name + ": " + $v.value.tostring()) }
}
Write-Output "PS Versions:"
write-output (get-host).version.toString()
write-output $host.version.toString()