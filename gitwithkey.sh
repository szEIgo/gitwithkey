#!/bin/bash
set -e

IDENTITY_STORE="$HOME/.git-identities"

echo "🔍 Searching for SSH keys in ~/.ssh/..."
pub_keys=()
while IFS= read -r line; do
  pub_keys+=("$line")
done < <(find ~/.ssh -type f -name "*.pub")

private_keys=()
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

# Extract a label for the key (just the filename)
key_label=$(basename "$key")

# Load or prompt Git identity
if grep -q "$key_label" "$IDENTITY_STORE" 2>/dev/null; then
  git_name=$(grep "$key_label" "$IDENTITY_STORE" | cut -d',' -f2)
  git_email=$(grep "$key_label" "$IDENTITY_STORE" | cut -d',' -f3)
  echo "📛 Using saved identity for $key_label: $git_name <$git_email>"
else
  echo "👤 No identity saved for this key."
  read -p "Enter Git name: " git_name
  read -p "Enter Git email: " git_email
  echo "$key_label,$git_name,$git_email" >> "$IDENTITY_STORE"
  echo "💾 Identity saved for future use."
fi

# Run Docker with Git and SSH
docker run --rm -it \
  --entrypoint /bin/sh \
  -v "$PWD":/repo \
  -v "$keyfile":/root/.ssh/id_rsa:ro \
  -e GIT_SSH_COMMAND="ssh -o IdentitiesOnly=yes -i /root/.ssh/id_rsa" \
  -w /repo \
  alpine/git \
  -c '
    git config user.name "'"$git_name"'" &&
    git config user.email "'"$git_email"'" &&
    git "$@"
  ' sh "$@"

rm -rf "$tmpdir"

