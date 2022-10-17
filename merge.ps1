write-output "Testing merge script"

foreach ($file in ($env:filesOutput | convertfrom-json)) {
    $file
}