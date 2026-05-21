import paramiko, os

host = '139.196.51.45'
port = 22
username = 'root'
password = 'ZMQyhwsun1314@'
pubkey_path = os.path.expanduser('~/.ssh/id_ed25519.pub')

with open(pubkey_path) as f:
    pubkey = f.read().strip()

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(host, port, username, password)

# Install public key
cmd = f'mkdir -p ~/.ssh && echo "{pubkey}" >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && chmod 700 ~/.ssh'
stdin, stdout, stderr = ssh.exec_command(cmd)
exit_code = stdout.channel.recv_exit_status()
print(f'Add key exit code: {exit_code}')
err = stderr.read().decode()
if err:
    print(f'STDERR: {err}')

ssh.close()

# Now test key-based login
ssh2 = paramiko.SSHClient()
ssh2.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh2.connect(host, port, username, key_filename=os.path.expanduser('~/.ssh/id_ed25519'))
stdin, stdout, stderr = ssh2.exec_command('echo KEY_LOGIN_OK && hostname')
print('Key login test:', stdout.read().decode())
ssh2.close()
print('SUCCESS')
