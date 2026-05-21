import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=10)

stdin, stdout, stderr = ssh.exec_command("pip3 list 2>/dev/null | wc -l", timeout=10)
pkg_count = "".join(stdout.readlines()).strip()

stdin2, stdout2, stderr2 = ssh.exec_command("ps aux | grep -E 'pip|wget|curl' | grep -v grep | awk '{print $2, $9, $10, $11}'", timeout=10)
processes = "".join(stdout2.readlines()).strip()

stdin3, stdout3, stderr3 = ssh.exec_command("df -h / | tail -1", timeout=5)
disk = "".join(stdout3.readlines()).strip()

print(f"Packages: {pkg_count}")
print(f"Running processes:")
print(processes[:500])
print(f"Disk: {disk}")

ssh.close()
