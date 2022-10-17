write-output "Testing merge script"
foreach ($file in ${{steps.changed-files.outputs.all_changed_files}}) {
    $file
}