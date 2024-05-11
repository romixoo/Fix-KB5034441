[string]$nfo = reagentc /info
if($nfo -match ".*Windows RE status:.*Enabled.*"){ #Verify if WINRE is enabled, if so proceed.
  $nfo -match ".*Windows RE location.*harddisk(\d+)" | Out-Null #Locate the disk number it is on.
    $disk = $Matches[1]
  $nfo -match ".*Windows RE location.*partition(\d+)" | Out-Null #Locate the partition it is on.
    $partition = $Matches[1]
  $disk_type = $(Get-Disk | Select-Object Number, PartitionStyle | ?{$_.Number -eq 0}).PartitionStyle #Determine disk partition style.
  
  #Start building the script to pass to diskpart.
  $Diskpart_Script =  "sel disk $disk`n" #Target disk with recovery partition.
  $Diskpart_Script += "sel partition $($partition - 1)`n" #Target partition left adjacent to recovery partition.
  $Diskpart_Script += "shrink desired=500 minimum=500`n" #Shrink by 500m.
  $Diskpart_Script += "sel partition $partition`n" #Target recovery partition.
  $Diskpart_Script += "delete partition override`n" #Remove it.
  if ($disk_type -eq 'GPT'){ #Recreate partition based on partiton table layout.
    $Diskpart_Script += "create partition primary id=de94bba4-06d1-4d40-a16a-bfd50179d6ac`n"
    $Diskpart_Script += "gpt attributes=0x8000000000000001`n"
  }else{
    $Diskpart_Script += "create partition primary id=27`n"
  }
  $Diskpart_Script += "format fs=ntfs label=`"Windows RE tools`" quick`n" #Format the newly created partition.
  $Diskpart_Script | Out-File .\DiskScript.txt -Encoding ascii #Write the script.
  
  #Do it!
  reagentc /disable
  diskpart /s .\DiskScript.txt
  reagentc /enable
  Remove-Item .\DiskScript.txt
}
