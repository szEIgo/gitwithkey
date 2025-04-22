#!/bin/zsh

set -e

echo "🔍 Searching for SSH keys in ~/.ssh/..."
pub_keys=()
while IFS= read -r line; do
  pub_keys+=("$line")
done < <(find ~/.ssh -type f -name "*.pub")

private_keys=()

# Strip .pub and verify private key exists
for pub in "${pub_keys[@]}"; do
  key="${pub%.pub}"
  [[ -f "$key" ]] && private_keys+=("$key")
done

if [ ${#private_keys[@]} -eq 0 ]; then
  echo "❌ No SSH private keys found."
  exit 1
fi

echo "🔐 Select an SSH Key:"
select key in "${private_keys[@]}"; do
  if [ -n "$key" ]; then
    echo "✅ Using SSH key: $key"
    break
  else
    echo "❌ Invalid selection."
  fi
done

# Create temp dir and copy key
tmpdir=$(mktemp -d)
keyfile="$tmpdir/id_key"
cp "$key" "$keyfile"
chmod 600 "$keyfile"

# Run Docker with Git and SSH
docker run --rm -it \
  -v "$PWD":/repo \
  -v "$keyfile":/root/.ssh/id_rsa:ro \
  -e GIT_SSH_COMMAND="ssh -o IdentitiesOnly=yes -i /root/.ssh/id_rsa" \
  -w /repo \
  alpine/git \
  "$@"

# Clean up
rm -rf "$tmpdir"

