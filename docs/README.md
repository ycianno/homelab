# Homelab Documentation

This directory explains the running infrastructure from the outside in. The first three documents are curated, dated descriptions of observed state. The remaining pages provide implementation detail and operational history.

## Start here

1. [Architecture](Architecture.md) — compute, network, trust boundaries, and system relationships.
2. [Service Catalog](Service%20Catalog.md) — deployed applications and their host placement.
3. [Operations and Reliability](Operations%20and%20Reliability.md) — management model, monitoring, security, backups, and gaps.

## Supporting records

- [Servers](Servers) — host and guest records.
- [Services](services) — individual service notes.
- [Runbooks](Runbooks) — procedures and automation references.
- [Security](Security) — baseline and implementation notes.

## Documentation trust model

- **Observed:** verified against the running environment on the review date shown in the document.
- **Configured:** present in version-controlled configuration, but not necessarily validated end to end during the latest audit.
- **Planned:** not yet an operating capability.

GitHub is the source of truth for this public, sanitized view. Private credentials and unredacted operations notes remain outside the repository. Public documents should never imply that a planned control is deployed or that a backup is recoverable without a successful restore test.
