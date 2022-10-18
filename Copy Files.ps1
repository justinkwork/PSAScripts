param($sourcePath, $targetPath)

if (test-path $targetPath) {
	rename-item $targetPath "$targetPath.old"
}
copy-item $sourcePath\* $targethPath


