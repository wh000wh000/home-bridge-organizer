# Publish Checklist

The repository is prepared for a public GitHub release.

1. Re-authenticate GitHub CLI if needed:

```bash
gh auth login -h github.com
```

2. Create the public repository and push:

```bash
gh repo create home-bridge-organizer --public --source=. --remote=origin --push
git push origin v0.1.0
```

3. The `v0.1.0` tag triggers the release workflow. If you prefer creating the release manually, use:

```bash
gh release create v0.1.0 --title "Home Bridge Organizer v0.1.0" --notes-file RELEASE.md
```

4. Before sharing widely, confirm the GitHub Actions CI build passes.
