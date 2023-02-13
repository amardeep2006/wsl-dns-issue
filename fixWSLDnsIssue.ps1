$userHome=[Environment]::GetFolderPath("UserProfile")
$ShellScriptPath=$userHome+"\setUpDNS.sh"

function ReplaceTextInFile($fileName, $originalText, $newText) {
	$original_file = $fileName
	$text = [IO.File]::ReadAllText($original_file) -replace $originalText, $newText
	[IO.File]::WriteAllText($original_file, $text)
}

function FindDNSServerIPAddress() {
	$dnsServerIP = (Get-DnsClientServerAddress -AddressFamily IPv4).ServerAddresses
	#$dnsServerIP = (Get-DnsClientServerAddress).ServerAddresses
	return $dnsServerIP
}


function GenerateShellScript($DNSAddresses,$ShellScriptPath) {
	$ShellScriptContentPart1 = @" 
#!/bin/bash
echo "wsl config"
rm -fr /etc/wsl.conf
bash -c 'echo "[network]" > /etc/wsl.conf'
bash -c 'echo "generateResolvConf = false" >> /etc/wsl.conf'
echo "resolve.conf Configuration"
chattr -i /etc/resolv.conf
rm -fr /etc/resolv.conf
"@

	$ShellScriptContentPart3 = @"
chattr +i /etc/resolv.conf
echo "done here is final config"
cat /etc/resolv.conf
#curl -v google.com
#ping -c 5 google.com
echo "done ..."
"@

	# Generate the Shell script
	Set-Content -Path $ShellScriptPath -Value $ShellScriptContentPart1
# There may be multiple DNS servers	
	if ($DNSAddresses.GetType().Name -eq 'String') {
		$temp = "bash -c 'echo `"nameserver $DNSAddresses`" >> /etc/resolv.conf'"
		Add-Content -Path $ShellScriptPath -Value $temp
	}
 else {
		foreach ($ip in $DNSAddresses) {
			$temp = "bash -c 'echo `"nameserver $ip`" >> /etc/resolv.conf'"
			Add-Content -Path $ShellScriptPath -Value $temp	
  }
	}	
  
	Add-Content -Path $ShellScriptPath -Value $ShellScriptContentPart3 
	
}

#Get Dns Servers IP address
$DNSIP = FindDNSServerIPAddress

# Generate Shell Scripts with dns ip address
GenerateShellScript $DNSIP $ShellScriptPath

# Replce Windows style CRLF with UNIX style LF in geterated shell script
ReplaceTextInFile $ShellScriptPath "`r`n" "`n"

# Make Ubuntu default
wsl --setdefault Ubuntu

# Go to Home directory Run the shell script
cd $userHome
wsl sudo ./setUpDNS.sh

wsl ping -c 5 google.com
