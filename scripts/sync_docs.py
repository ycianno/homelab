#!/usr/bin/env python3
import os
import re
import shutil

vault_root = os.environ.get("VAULT_ROOT", "/Users/yzee/Obsidian/02-Homelab")
repo_docs = os.environ.get("REPO_DOCS", "/Users/yzee/dev/homelab/docs")
excluded_private_docs = {
    "Homelab Overview.md",
    "Homelab Tasks.md",
    "Runbooks/Semaphore Automation Center Roadmap.md",
    "Security/Homelab Security Analysis.md",
    "Security/Hardening Checklist.md",
    "Security/Wazuh Vulnerability Report.md",
}
curated_public_docs = {
    "README.md",
    "Architecture.md",
    "Service Catalog.md",
    "Operations and Reliability.md",
}


def public_rel_path(rel_path):
    """Map vault folder names to their canonical public repository paths."""
    parts = rel_path.split(os.sep)
    if parts and parts[0] == "Services":
        parts[0] = "services"
    return os.path.join(*parts)

print(f"Scanning vault notes at {vault_root}...")

# Step 1: Scan 02-Homelab to build note_map (maps note_name -> relative_path_from_vault_root)
note_map = {}
for root, dirs, files in os.walk(vault_root):
    for file in files:
        vault_rel_path = os.path.relpath(os.path.join(root, file), vault_root)
        if vault_rel_path in excluded_private_docs:
            continue
        if file.endswith(".md"):
            abs_path = os.path.join(root, file)
            rel_path = public_rel_path(os.path.relpath(abs_path, vault_root))
            note_name, _ = os.path.splitext(file)
            # Register both exact note name and lowercase for case-insensitive lookup
            note_map[note_name] = rel_path
            note_map[note_name.lower()] = rel_path

# Step 2: Define wiki-link resolver and content converter
def resolve_note_link(source_rel_dir, target_str):
    if '#' in target_str:
        target_path, anchor = target_str.split('#', 1)
        anchor_part = f"#{anchor}"
    else:
        target_path = target_str
        anchor_part = ""

    if not target_path:
        return anchor_part

    if target_path.startswith(('http://', 'https://', 'file://')):
        return f"{target_path}{anchor_part}"

    # Get note key (last component)
    note_key = target_path.split('/')[-1]

    # Resolve relative path to target
    target_rel_path = note_map.get(note_key) or note_map.get(note_key.lower())
    if not target_rel_path:
        target_rel_path = note_map.get(target_path) or note_map.get(target_path.lower())

    if not target_rel_path:
        # Fallback if note isn't found in mapping
        return f"{target_path}.md{anchor_part}"

    # Compute relative path
    rel_path = os.path.relpath(target_rel_path, source_rel_dir)
    return f"{rel_path}{anchor_part}"

def convert_content(content, source_rel_dir):
    # Regex to match [[target|label]] or [[target]]
    def wiki_link_replacer(match):
        inner = match.group(1)
        if '|' in inner:
            target, label = inner.split('|', 1)
        else:
            target = inner
            # Use note name or anchor as label
            if '#' in target and not target.split('#')[0]:
                label = target.split('#')[1]
            else:
                label = target.split('#')[0].split('/')[-1]

        # Resolve target to relative path
        resolved_path = resolve_note_link(source_rel_dir, target.strip())
        return f"[{label.strip()}]({resolved_path})"

    # Apply wiki link replacement
    content = re.sub(r'\[\[([^\]]+)\]\]', wiki_link_replacer, content)

    # Replace the private domain when supplied by the local sync environment.
    private_domain = os.environ.get("PRIVATE_DOMAIN", "").strip()
    if private_domain:
        content = content.replace(private_domain, "yourdomain.com")

    # Replace Discord Webhook URLs to prevent credential leaks
    content = re.sub(
        r'https://discord\.com/api/webhooks/\d+/[A-Za-z0-9_-]+',
        'https://discord.com/api/webhooks/YOUR_WEBHOOK_ID/YOUR_WEBHOOK_TOKEN',
        content
    )

    # Apply dynamic wording sanitization (convert conversational AI wording to enterprise standards)
    sanitization_mapping = {
        "This is the central task list for your homelab hardening and career-aligned projects.":
            "This is the centralized tracking roadmap for homelab infrastructure hardening and systems engineering development.",
        "Proxmox external drive has backup issues; we need an alternative way to send backups directly to your iPhone (1TB space).":
            "Proxmox external drive constraints require an alternative method to store backups on a primary administrative mobile client (1TB storage capacity).",
        "in your existing Discord alerts server.":
            "in the centralized Discord alerts server.",
        "[YOUR-PASSWORD]":
            "[ADMIN_PASSWORD]",
        "You can configure Watchtower to only update containers you explicitly **opt-in** using labels.":
            "Watchtower is configured to only update containers that explicitly **opt-in** via labels.",
        "On both `automation-01` and `docker-01`, modify your Watchtower `docker-compose.yml` configurations (under `/opt/stacks/watchtower/docker-compose.yml`):":
            "On both `automation-01` and `docker-01`, the Watchtower `docker-compose.yml` configuration (located at `/opt/stacks/watchtower/docker-compose.yml`) is modified as follows:",
        "# Discord Notification Settings (Keep your existing settings)":
            "# Discord Notification Settings (Preserve active configurations)",
        "When you get a Discord notification, go to Semaphore, click **Run**, type the stack name (e.g. `n8n`), and it will safely pull the images, recreate the container, and prune the old image.":
            "Upon receiving a Discord alert, the administrator initiates the Semaphore task, specifies the target stack name (e.g. `n8n`), executing the remote image pull, container recreation, and image pruning sequence.",
        "Monitors Docker containers for new base image updates and notifies you.":
            "Monitors Docker containers for base image updates and publishes status alerts.",
        "natively on your macOS client (Unified Memory/GPU acceleration)":
            "natively on the macOS workstation host (utilizing Unified Memory and GPU acceleration)",
        "Currently active models pulled on your Mac:":
            "Currently active models pulled on the Ollama host:",
        "show your ecosystem and homelab resources cleanly:":
            "provide a clean visualization of the homelab infrastructure and active service pools:",
        "emphasize your current certification targets (PL-900, AZ-900, ITIL 4/5) at the very top.":
            "place professional certification tracks (such as PL-900, AZ-900, and ITIL 4/5) at the top of the resource list.",
        "When editing or creating workflows in the n8n GUI, you must export the changes to the Git repository to keep configuration files updated.":
            "When editing or creating workflows in the n8n GUI, changes are exported to the Git repository to maintain version control for configuration files."
    }

    for vault_phrase, repo_phrase in sanitization_mapping.items():
        content = content.replace(vault_phrase, repo_phrase)

    return content

# Step 3: Preserve the GitHub-native portfolio layer, then replace vault-derived docs.
print(f"Cleaning repository docs directory: {repo_docs}...")
preserved_docs = {}
for rel_path in curated_public_docs:
    source_path = os.path.join(repo_docs, rel_path)
    if os.path.isfile(source_path):
        with open(source_path, "rb") as source_file:
            preserved_docs[rel_path] = source_file.read()

if os.path.exists(repo_docs):
    shutil.rmtree(repo_docs)
os.makedirs(repo_docs, exist_ok=True)

for rel_path, content in preserved_docs.items():
    destination_path = os.path.join(repo_docs, rel_path)
    os.makedirs(os.path.dirname(destination_path), exist_ok=True)
    with open(destination_path, "wb") as destination_file:
        destination_file.write(content)

print(f"Syncing and translating docs...")
sync_count = 0
for root, dirs, files in os.walk(vault_root):
    for file in files:
        src_path = os.path.join(root, file)
        vault_rel_path = os.path.relpath(src_path, vault_root)
        if vault_rel_path in excluded_private_docs:
            continue
        rel_path = public_rel_path(vault_rel_path)
        dest_path = os.path.join(repo_docs, rel_path)

        # Ensure destination directory exists
        os.makedirs(os.path.dirname(dest_path), exist_ok=True)

        if file.endswith(".md"):
            with open(src_path, "r", encoding="utf-8") as f:
                content = f.read()

            source_rel_dir = os.path.dirname(rel_path)
            converted = convert_content(content, source_rel_dir)

            with open(dest_path, "w", encoding="utf-8") as f:
                f.write(converted)
        else:
            # Copy binary / other files as-is
            shutil.copy2(src_path, dest_path)
        sync_count += 1

print(f"Success! {sync_count} files successfully synced, wiki-links translated, and domains sanitized.")
